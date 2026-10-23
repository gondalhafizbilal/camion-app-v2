import 'dart:io';

import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/home/data/data_source/remote_data_source.dart';
import 'package:camion/features/home/data/graphql/home_graphql_queries.dart';
import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';
import 'package:camion/features/home/data/models/categories_model/get_categories_model.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/reviews_model/review_model.dart';
import 'package:camion/features/home/data/models/slider_items/slider_item_model.dart';
import 'package:camion/features/home/data/models/stories_model.dart/stories_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HomeRepository {
  HomeRemoteDataSource remoteDataSource;

  HomeRepository({required this.remoteDataSource});

  static const List<HomeGraphqlSectionDefinition> defaultHomeGraphqlSections = [
    HomeGraphqlSectionDefinition(
      type: HomeProductSectionType.allProducts,
      query: HomeGraphqlSectionQuery(itemsPerPage: 8),
    ),
    HomeGraphqlSectionDefinition(
      type: HomeProductSectionType.featuredProducts,
      query: HomeGraphqlSectionQuery(itemsPerPage: 8),
    ),
    HomeGraphqlSectionDefinition(
      type: HomeProductSectionType.popularProducts,
      query: HomeGraphqlSectionQuery(itemsPerPage: 8),
    ),
    HomeGraphqlSectionDefinition(
      type: HomeProductSectionType.recentlyViewed,
      query: HomeGraphqlSectionQuery(itemsPerPage: 8),
    ),
  ];

  static const Set<String> _graphqlSupportedCurrencies = {
    'qar',
    'aed',
    'sar',
    'kwd',
    'omr',
    'bhd',
    'usd',
  };

  Future<Either<ApiErrorModel, List<AllProductModel>>> getProducts({
    required int page,
    required int perPage,
    required String lang,
    String? search,
    String? sort,
    num? minPrice,
    num? maxPrice,
  }) async {
    try {
      final graphqlResponse = (search != null && search.trim().isNotEmpty)
          ? await searchGraphqlProducts(
              language: lang,
              queryText: search.trim(),
              sort: sort,
              pageNumber: page,
              itemsPerPage: perPage,
            )
          : await getGraphqlProducts(
              language: lang,
              sort: sort,
              pageNumber: page,
              itemsPerPage: perPage,
            );

      return graphqlResponse.fold(
        (error) => left(error),
        (products) => Right(_mapGraphqlProductsToLegacy(products)),
      );
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<AllProductModel>>> searchProducts({
    required String query,
    String? sort,
    num? minPrice,
    num? maxPrice,
  }) async {
    try {
      final response = await searchGraphqlProducts(
        language: _selectedLanguageCode(),
        queryText: query,
        sort: sort,
        pageNumber: 1,
        itemsPerPage: 100,
      );
      return response.fold(
        (error) => left(error),
        (products) => Right(_mapGraphqlProductsToLegacy(products)),
      );
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, AllProductModel>> getProductById({
    required String id,
    String? token,
    required String lang,
  }) async {
    try {
      final response = await remoteDataSource.getProductById(
        id: id,
        token: token,
        lang: lang,
      );
      return Right(AllProductModel.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e, showNoDataPopup: false));
    }
  }

  Future<Either<ApiErrorModel, List<StoriesModel>>> getStories({
    required String token,
  }) async {
    try {
      final response = await remoteDataSource.getStories(token: token);
      final stories = (response.data as List)
          .map((story) => StoriesModel.fromJson(story))
          .toList();
      return Right(stories);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<StoriesModel>>> getGraphqlStories({
    String? token,
    required String language,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.stories,
        variables: {'language': language, 'pageNumber': 1, 'itemsPerPage': 100},
        suppressBackendUnavailableBanner: true,
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawStories =
          (data['getStories'] as List? ??
                  data['storiesSection'] as List? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .toList();
      final stories = rawStories
          .map(HomeGraphqlStoryMapper.fromGraphqlJson)
          .where((story) => story.frames.isNotEmpty)
          .toList();
      appLog(
        '[Stories] server=${rawStories.length} valid=${stories.length} '
        'frames=${stories.fold<int>(0, (sum, story) => sum + story.frames.length)}',
      );
      return Right(stories);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, StoriesModel>> getStoryById({
    required String id,
    required String token,
  }) async {
    try {
      final response = await remoteDataSource.getStoryById(
        id: id,
        token: token,
      );
      return Right(StoriesModel.fromJson(response.data));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<GeTCategoriesModel>>> getCategories({
    required String lang,
  }) async {
    try {
      final response = await remoteDataSource.getCategories(lang: lang);
      final categories = (response.data as List)
          .map((category) => GeTCategoriesModel.fromJson(category))
          .toList();
      return Right(categories);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlCategory>>>
  getGraphqlCategories({
    String? token,
    required String language,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.featuredCategories,
        variables: {'language': language, 'pageNumber': 1, 'itemsPerPage': 100},
        suppressBackendUnavailableBanner: true,
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final categories =
          (data['getFeaturedCategories'] as List? ??
                  data['getCategories'] as List? ??
                  data['categoriesSection'] as List? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .map(HomeGraphqlCategory.fromJson)
              .toList();
      return Right(categories);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<GeTCategoriesModel>>> getSubCategories({
    required int id,
    required String lang,
  }) async {
    try {
      final response = await remoteDataSource.getSubCategories(
        id: id,
        lang: lang,
      );
      final products = (response.data["subcategories"] as List)
          .map((product) => GeTCategoriesModel.fromJson(product))
          .toList();
      return Right(products);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<AllProductModel>>> getProductsByCategory({
    required String slug,
    required int page,
    required int perPage,
    required String lang,
  }) async {
    try {
      final response = await getProductsByCategoryGraphql(
        language: lang,
        slug: slug,
        pageNumber: page,
        itemsPerPage: perPage,
      );
      return response.fold(
        (error) => left(error),
        (products) => Right(_mapGraphqlProductsToLegacy(products)),
      );
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<AllProductModel>>> getProductsByCategories({
    required List<String> slugs,
    required int page,
    required int perPage,
    required String lang,
    String? sort,
  }) async {
    try {
      final normalizedSlugs = slugs
          .map((slug) => slug.trim())
          .where((slug) => slug.isNotEmpty)
          .toSet()
          .toList();
      if (normalizedSlugs.isEmpty) {
        return const Right(<AllProductModel>[]);
      }

      final response = await getProductsByCategoriesGraphql(
        language: lang,
        slugs: normalizedSlugs,
        pageNumber: page,
        itemsPerPage: perPage,
        sort: sort,
      );
      return response.fold(
        (error) => left(error),
        (products) => Right(_mapGraphqlProductsToLegacy(products)),
      );
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<AllProductModel>>> getProductsOnSale({
    required int page,
    required int perPage,
    required String lang,
  }) async {
    try {
      final response = await getGraphqlProducts(
        language: lang,
        pageNumber: page,
        itemsPerPage: perPage,
      );
      return response.fold(
        (error) => left(error),
        (products) => Right(
          _mapGraphqlProductsToLegacy(
            products.where((p) => p.hasDiscount).toList(),
          ),
        ),
      );
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  // Future<Either<ApiErrorModel, StoriesModel>> getStoryById({
  //   required String id,
  //   required String token
  // }) async {
  //   try {
  //     final response = await remoteDataSource.getStoryById(id: id , token: token);
  //     return Right(StoriesModel.fromJson(response.data));
  //   } catch (e) {
  //     return left(ApiErrorHandler.handle(e));
  //   }
  // }

  Future<Either<ApiErrorModel, List<SliderItemModel>>> getSliders() async {
    try {
      final response = await remoteDataSource.getSliders();
      final sliders = (response.data as List)
          .map((slider) => SliderItemModel.fromJson(slider))
          .toList();
      return Right(sliders);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  List<SliderItemModel> _mapGraphqlBanners(
    List<dynamic> rawBanners, {
    required String language,
  }) {
    return rawBanners
        .whereType<Map<String, dynamic>>()
        .map(
          (banner) => HomeGraphqlBannerMapper.fromGraphqlJson(
            banner,
            language: language,
          ),
        )
        .toList();
  }

  List<SliderItemModel> _extractGraphqlBanners(
    Map<String, dynamic> data, {
    required String language,
  }) {
    final rawBanners =
        data['getBannersByCategory'] as List? ??
        data['getBannersByPlacement'] as List? ??
        data['getBanners'] as List? ??
        data['bannersSection'] as List? ??
        const [];
    return _mapGraphqlBanners(rawBanners, language: language);
  }

  Future<List<SliderItemModel>> _fetchGraphqlBanners({
    String? token,
    required String language,
    required String query,
    required Map<String, dynamic> variables,
  }) async {
    final response = await remoteDataSource.postGraphql(
      token: token,
      query: query,
      variables: variables,
      suppressBackendUnavailableBanner: true,
    );
    final data = response.data['data'] ?? const <String, dynamic>{};
    return _extractGraphqlBanners(data, language: language);
  }

  Future<Either<ApiErrorModel, List<SliderItemModel>>> getGraphqlBanners({
    String? token,
    required String language,
    String placement = 'homepage',
    bool forceRefresh = false,
  }) async {
    try {
      final banners = await _fetchGraphqlBanners(
        token: token,
        language: language,
        query: HomeGraphqlQueries.bannersByPlacement,
        variables: {
          'placement': placement,
          'language': language,
          'pageNumber': 1,
          'itemsPerPage': 100,
        },
      );
      if (banners.isNotEmpty) {
        return Right(banners);
      }

      final fallbackBanners = await _fetchGraphqlBanners(
        token: token,
        language: language,
        query: HomeGraphqlQueries.bannersFallback,
        variables: {'language': language, 'pageNumber': 1, 'itemsPerPage': 100},
      );
      return Right(fallbackBanners);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<SliderItemModel>>>
  getGraphqlBannersByCategory({
    String? token,
    required String language,
    required String slug,
    String? parentSlug,
    String primaryPlacement = 'all-categories-mobile',
    String secondaryPlacement = 'homepage',
    bool forceRefresh = false,
  }) async {
    try {
      final categorySlugs = <String>[];
      void addSlug(String? value) {
        final normalized = value?.trim() ?? '';
        if (normalized.isNotEmpty && !categorySlugs.contains(normalized)) {
          categorySlugs.add(normalized);
        }
      }

      addSlug(slug);
      addSlug(parentSlug);

      for (final candidateSlug in categorySlugs) {
        final banners = await _fetchGraphqlBanners(
          token: token,
          language: language,
          query: HomeGraphqlQueries.bannersByCategory,
          variables: {
            'slug': candidateSlug,
            'language': language,
            'pageNumber': 1,
            'itemsPerPage': 100,
          },
        );
        if (banners.isNotEmpty) {
          return Right(banners);
        }
      }

      final placements = <String>[
        primaryPlacement,
        secondaryPlacement,
      ].where((placement) => placement.trim().isNotEmpty).toSet().toList();

      for (final placement in placements) {
        final banners = await _fetchGraphqlBanners(
          token: token,
          language: language,
          query: HomeGraphqlQueries.bannersByPlacement,
          variables: {
            'placement': placement,
            'language': language,
            'pageNumber': 1,
            'itemsPerPage': 100,
          },
        );
        if (banners.isNotEmpty) {
          return Right(banners);
        }
      }

      final fallbackBanners = await _fetchGraphqlBanners(
        token: token,
        language: language,
        query: HomeGraphqlQueries.bannersFallback,
        variables: {'language': language, 'pageNumber': 1, 'itemsPerPage': 100},
      );
      return Right(fallbackBanners);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, HomeGraphqlCategoryFeedData>>
  getCategoryFeedGraphql({
    String? token,
    required String language,
    String placement = 'all-categories-mobile',
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.categoryFeed,
        variables: {
          'language': language,
          'placement': placement,
          'categoriesPageNumber': 1,
          'categoriesItemsPerPage': 100,
          'bannersPageNumber': 1,
          'bannersItemsPerPage': 100,
        },
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final categories =
          (data['categoriesSection'] as List? ??
                  data['getCategories'] as List? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .map(HomeGraphqlCategory.fromJson)
              .toList();

      var banners = _extractGraphqlBanners(data, language: language);
      if (banners.isEmpty) {
        banners = await _fetchGraphqlBanners(
          token: token,
          language: language,
          query: HomeGraphqlQueries.bannersFallback,
          variables: {
            'language': language,
            'pageNumber': 1,
            'itemsPerPage': 100,
          },
        );
      }
      return Right(
        HomeGraphqlCategoryFeedData(banners: banners, categories: categories),
      );
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>> getGraphqlProducts({
    String? token,
    required String language,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.products,
      fieldName: 'getProducts',
      variables: {
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getFeaturedGraphqlProducts({
    String? token,
    required String language,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.featuredProducts,
      fieldName: 'getFeaturedProducts',
      variables: {
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, HomeGraphqlFeaturedCampaign?>>
  getFeaturedCampaignGraphql({String? token, required String language}) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.featuredCampaign,
        variables: {'language': language},
        suppressBackendUnavailableBanner: true,
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawCampaign = data['getFeaturedCampaign'];
      if (rawCampaign is! Map<String, dynamic>) {
        return const Right(null);
      }
      final campaign = HomeGraphqlFeaturedCampaign.fromJson(rawCampaign);
      if (campaign.uuid.trim().isEmpty) {
        return const Right(null);
      }
      return Right(campaign);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getProductsInFeaturedCampaignGraphql({
    String? token,
    required String language,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.productsInFeaturedCampaign,
      fieldName: 'getProductsInFeaturedCampaign',
      variables: {
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getPopularGraphqlProducts({
    String? token,
    required String language,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.popularProducts,
      fieldName: 'getPopularProducts',
      variables: {
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getRecentlyViewedGraphqlProducts({
    String? token,
    required String language,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.recentlyViewedProducts,
      fieldName: 'getRecentlyViewedProducts',
      variables: {
        'language': language,
        'currency': _selectedCurrencyCode(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, HomeProductSections>> getHomeSectionsGraphql({
    String? token,
    required String language,
    bool forceRefresh = false,
  }) async {
    try {
      HomeGraphqlSectionQuery? queryFor(HomeProductSectionType type) {
        for (final definition in defaultHomeGraphqlSections) {
          if (definition.type == type) {
            return definition.query;
          }
        }
        return null;
      }

      final allQuery =
          queryFor(HomeProductSectionType.allProducts) ??
          const HomeGraphqlSectionQuery(itemsPerPage: 8);
      final featuredQuery =
          queryFor(HomeProductSectionType.featuredProducts) ??
          const HomeGraphqlSectionQuery(itemsPerPage: 8);
      final popularQuery =
          queryFor(HomeProductSectionType.popularProducts) ??
          const HomeGraphqlSectionQuery(itemsPerPage: 8);
      final recentlyViewedQuery =
          queryFor(HomeProductSectionType.recentlyViewed) ??
          const HomeGraphqlSectionQuery(itemsPerPage: 8);
      final featuredCampaignResult = await getFeaturedCampaignGraphql(
        token: token,
        language: language,
      );
      final featuredCampaign = featuredCampaignResult.fold(
        (_) => null,
        (campaign) => campaign,
      );
      final hasFeaturedCampaignSections =
          featuredCampaign?.campaignCategories.isNotEmpty ?? false;
      final campaign = featuredCampaign;
      final featuredCampaignFuture = !hasFeaturedCampaignSections
          ? Future.value(
              const Right<ApiErrorModel, List<HomeGraphqlCampaignSection>>(
                <HomeGraphqlCampaignSection>[],
              ),
            )
          : Future.wait(
              campaign!.campaignCategories.map((entry) {
                return getProductsByCategoryGraphql(
                  token: token,
                  language: language,
                  slug: entry.category.slug,
                  pageNumber: 1,
                  itemsPerPage: 8,
                );
              }),
            ).then((results) {
              final sections = <HomeGraphqlCampaignSection>[];
              for (var index = 0; index < results.length; index++) {
                final result = results[index];
                final category = campaign.campaignCategories[index].category;
                result.fold((_) {}, (items) {
                  if (items.isEmpty) return;
                  sections.add(
                    HomeGraphqlCampaignSection(
                      campaignUuid: campaign.uuid,
                      campaignName: campaign.name,
                      campaignFinishesAt: campaign.finishesAt,
                      categoryUuid: category.uuid,
                      categorySlug: category.slug,
                      categoryName: category.name,
                      categoryThumbnailUrl: category.thumbnailUrl,
                      products: items,
                    ),
                  );
                });
              }
              return Right<ApiErrorModel, List<HomeGraphqlCampaignSection>>(
                sections,
              );
            });
      final allFuture = getGraphqlProducts(
        token: token,
        language: language,
        sort: allQuery.sort,
        pageNumber: allQuery.pageNumber,
        itemsPerPage: allQuery.itemsPerPage,
      );
      final featuredFuture = getFeaturedGraphqlProducts(
        token: token,
        language: language,
        pageNumber: featuredQuery.pageNumber,
        itemsPerPage: featuredQuery.itemsPerPage,
      );
      final popularFuture = getPopularGraphqlProducts(
        token: token,
        language: language,
        pageNumber: popularQuery.pageNumber,
        itemsPerPage: popularQuery.itemsPerPage,
      );
      final recentlyViewedFuture = getRecentlyViewedGraphqlProducts(
        token: token,
        language: language,
        pageNumber: recentlyViewedQuery.pageNumber,
        itemsPerPage: recentlyViewedQuery.itemsPerPage,
      );

      final results = await Future.wait([
        featuredCampaignFuture,
        allFuture,
        featuredFuture,
        popularFuture,
        recentlyViewedFuture,
      ]);

      final featuredCampaignPageResult =
          results[0] as Either<ApiErrorModel, List<HomeGraphqlCampaignSection>>;
      final allResult =
          results[1] as Either<ApiErrorModel, List<HomeGraphqlProduct>>;
      final featuredResult =
          results[2] as Either<ApiErrorModel, List<HomeGraphqlProduct>>;
      final popularResult =
          results[3] as Either<ApiErrorModel, List<HomeGraphqlProduct>>;
      final recentlyViewedResult =
          results[4] as Either<ApiErrorModel, List<HomeGraphqlProduct>>;

      final featuredCampaignSections = featuredCampaignPageResult.fold(
        (_) => const <HomeGraphqlCampaignSection>[],
        (r) => r,
      );
      final all = allResult.fold((_) => const <HomeGraphqlProduct>[], (r) => r);
      final featured = featuredResult.fold(
        (_) => const <HomeGraphqlProduct>[],
        (r) => r,
      );
      final popular = popularResult.fold(
        (_) => const <HomeGraphqlProduct>[],
        (r) => r,
      );
      final recentlyViewed = recentlyViewedResult.fold(
        (_) => const <HomeGraphqlProduct>[],
        (r) => r,
      );

      ApiErrorModel? firstError;
      featuredCampaignPageResult.fold((error) => firstError ??= error, (_) {});
      allResult.fold((error) => firstError ??= error, (_) {});
      featuredResult.fold((error) => firstError ??= error, (_) {});
      popularResult.fold((error) => firstError ??= error, (_) {});
      recentlyViewedResult.fold((error) => firstError ??= error, (_) {});
      final hasAnyData =
          featuredCampaignSections.isNotEmpty ||
          all.isNotEmpty ||
          featured.isNotEmpty ||
          popular.isNotEmpty ||
          recentlyViewed.isNotEmpty;
      if (!hasAnyData && firstError != null) {
        return left(firstError!);
      }

      final sections = HomeProductSections(
        allProducts: all,
        featuredProducts: featured,
        popularProducts: popular,
        recentlyViewed: recentlyViewed,
        featuredCampaignTitle: featuredCampaign == null
            ? ''
            : featuredCampaign.name,
        featuredCampaignSections: featuredCampaignSections,
      );
      return Right(sections);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getRecommendedGraphqlProducts({
    String? token,
    required String language,
    required String slug,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.recommendedProducts,
      fieldName: 'getRecommendedProducts',
      variables: {
        'slug': slug,
        'language': language,
        'currency': _selectedCurrencyCode(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getRelatedGraphqlProducts({
    String? token,
    required String language,
    required String slug,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.relatedProducts,
      fieldName: 'getRelatedProducts',
      variables: {
        'slug': slug,
        'language': language,
        'currency': _selectedCurrencyCode(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  searchGraphqlProducts({
    String? token,
    required String language,
    required String queryText,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 100,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.searchProducts,
      fieldName: 'searchProducts',
      variables: {
        'query': queryText,
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getProductsByCategoryGraphql({
    String? token,
    required String language,
    required String slug,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 100,
  }) async {
    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.productsByCategory,
      fieldName: 'getProductsByCategory',
      variables: {
        'slug': slug,
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getProductsByCategoriesGraphql({
    String? token,
    required List<String> slugs,
    required String language,
    String? sort,
    int pageNumber = 1,
    int itemsPerPage = 100,
  }) async {
    final normalizedSlugs = slugs
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedSlugs.isEmpty) {
      return const Right(<HomeGraphqlProduct>[]);
    }

    return _runProductsQuery(
      token: token,
      query: HomeGraphqlQueries.productsByCategories,
      fieldName: 'getProductsByCategories',
      variables: {
        'slugs': normalizedSlugs,
        'language': language,
        'currency': _selectedCurrencyCode(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );
  }

  Future<Either<ApiErrorModel, HomeGraphqlProduct>> getProductGraphql({
    String? token,
    required String slug,
    required String language,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.product,
        variables: {
          'slug': slug,
          'language': language,
          'currency': _selectedCurrencyCode(),
        },
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getProduct'];
      final map = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
      return Right(HomeGraphqlProduct.fromJson(map));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, HomeGraphqlCustomer>> getCurrentCustomerGraphql({
    String? token,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.currentCustomer,
        variables: const {},
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getCurrentCustomer'];
      final map = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
      return Right(HomeGraphqlCustomer.fromJson(map));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlCustomerAddress>>>
  getCustomerAddressesGraphql({
    String? token,
    int pageNumber = 1,
    int itemsPerPage = 100,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.customerAddresses,
        variables: {'pageNumber': pageNumber, 'itemsPerPage': itemsPerPage},
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getCustomerAddresses'];
      final list = raw is List ? raw : const [];
      final addresses = list
          .whereType<Map<String, dynamic>>()
          .map(HomeGraphqlCustomerAddress.fromJson)
          .toList();
      return Right(addresses);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlLanguage>>> getLanguagesGraphql({
    String? token,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.languages,
        variables: const <String, dynamic>{},
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getLanguages'];
      final list = raw is List ? raw : const [];
      final languages = list
          .whereType<Map<String, dynamic>>()
          .map(HomeGraphqlLanguage.fromJson)
          .toList();
      return Right(languages);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlCurrency>>>
  getCurrenciesGraphql({String? token}) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.currencies,
        variables: const <String, dynamic>{},
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getCurrencies'];
      final list = raw is List ? raw : const [];
      final currencies = list
          .whereType<Map<String, dynamic>>()
          .map(HomeGraphqlCurrency.fromJson)
          .toList();
      return Right(currencies);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, HomeDashboardCounts>> getDashboardCountsGraphql({
    String? token,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: HomeGraphqlQueries.customerDashboardCounts,
        variables: const <String, dynamic>{},
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final cartRaw = data['getCustomerCartCount'];
      final wishlistRaw = data['getCustomerWishlistCount'];
      final cartCount = cartRaw is num ? cartRaw.toInt() : 0;
      final wishlistCount = wishlistRaw is num ? wishlistRaw.toInt() : 0;
      return Right(
        HomeDashboardCounts(cartCount: cartCount, wishlistCount: wishlistCount),
      );
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>> _runProductsQuery({
    String? token,
    required String query,
    required String fieldName,
    required Map<String, dynamic> variables,
  }) async {
    try {
      final response = await remoteDataSource.postGraphql(
        token: token,
        query: query,
        variables: variables,
        suppressBackendUnavailableBanner: true,
      );
      final products =
          ((response.data['data'] ?? const {})[fieldName] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(HomeGraphqlProduct.fromJson)
              .toList();
      return Right(products);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  String _selectedCurrencyCode() {
    final fallbackCurrency = AppDefaults.defaultCurrencyCode.toLowerCase();
    String? code;
    try {
      code = sl<CacheHelper>().getDataString(key: 'currencyCode');
    } catch (_) {
      code = null;
    }
    if (code == null || code.trim().isEmpty) {
      return fallbackCurrency;
    }
    final normalized = code.trim().toLowerCase();
    if (_graphqlSupportedCurrencies.contains(normalized)) {
      return normalized;
    }
    return fallbackCurrency;
  }

  String _selectedLanguageCode() {
    final fallbackLanguage = AppDefaults.defaultLanguageCode;
    try {
      final code = sl<CacheHelper>().getDataString(key: 'languageCode');
      if (code == null || code.trim().isEmpty) {
        return fallbackLanguage;
      }
      return code.trim();
    } catch (_) {
      return fallbackLanguage;
    }
  }

  Future<Either<ApiErrorModel, dynamic>> sendFcmToken({
    required String fcmToken,
    required String token,
  }) async {
    try {
      final response = await remoteDataSource.sendFcmToken(
        fcmToken: fcmToken,
        token: token,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  // Future<Either<ApiErrorModel, dynamic>> canReview({
  //   required String token,
  //   required String productId,
  // }) async {
  //   try {
  //     final response = await remoteDataSource.canReview(
  //       token: token,
  //       productId: productId,
  //     );
  //     return Right(response.data);
  //   } catch (e) {
  //     return left(ApiErrorHandler.handle(e));
  //   }
  // }

  Future<Either<ApiErrorModel, dynamic>> createReview({
    required String productId,
    required String comment,
    required double rating,
    List<String> imagePaths = const <String>[],
    String? orderUuid,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return left(
          ApiErrorModel(message: 'Authentication required', statusCode: 401),
        );
      }
      final formData = FormData.fromMap({
        'rating': rating,
        'comment': comment,
        if ((orderUuid ?? '').trim().isNotEmpty) 'orderUuid': orderUuid!.trim(),
      });
      for (final path in imagePaths) {
        final normalizedPath = path.trim();
        if (normalizedPath.isEmpty) continue;
        final file = File(normalizedPath);
        if (!file.existsSync()) continue;
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              normalizedPath,
              filename: normalizedPath.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
      final response = await remoteDataSource.createReview(
        token: token.toString(),
        productId: productId,
        formData: formData,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<ReviewModel>>> getReviews({
    required String productId,
    required String lang,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return const Right(<ReviewModel>[]);
      }
      final response = await remoteDataSource.getReviews(
        token: token.toString(),
        productId: productId,
      );
      final List<ReviewModel> reviews = (response.data as List)
          .map((review) => ReviewModel.fromJson(review))
          .toList();
      return Right(reviews);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e, showNoDataPopup: false));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> createReviewImage({
    required String productId,
    required String reviewId,
    required FormData formData,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return left(
          ApiErrorModel(message: 'Authentication required', statusCode: 401),
        );
      }
      final response = await remoteDataSource.createReviewImage(
        token: token.toString(),
        productId: productId,
        reviewId: reviewId,
        formData: formData,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, ReviewModel>> getReviewById({
    required String productId,
    required String reviewId,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return left(
          ApiErrorModel(message: 'Authentication required', statusCode: 401),
        );
      }
      final response = await remoteDataSource.getReviewById(
        token: token.toString(),
        productId: productId,
        reviewId: reviewId,
      );
      return Right(ReviewModel.fromJson(response.data as Map<String, dynamic>));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> updateReview({
    required String productId,
    required String reviewId,
    required String comment,
    required double rating,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return left(
          ApiErrorModel(message: 'Authentication required', statusCode: 401),
        );
      }
      final response = await remoteDataSource.updateReview(
        token: token.toString(),
        productId: productId,
        reviewId: reviewId,
        comment: comment,
        rating: rating,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> deleteReview({
    required String productId,
    required String reviewId,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return left(
          ApiErrorModel(message: 'Authentication required', statusCode: 401),
        );
      }
      final response = await remoteDataSource.deleteReview(
        token: token.toString(),
        productId: productId,
        reviewId: reviewId,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> deleteReviewImage({
    required String productId,
    required String reviewId,
    required String imageId,
  }) async {
    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (token == null || token.toString().isEmpty) {
        return left(
          ApiErrorModel(message: 'Authentication required', statusCode: 401),
        );
      }
      final response = await remoteDataSource.deleteReviewImage(
        token: token.toString(),
        productId: productId,
        reviewId: reviewId,
        imageId: imageId,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  List<AllProductModel> _mapGraphqlProductsToLegacy(
    List<HomeGraphqlProduct> products,
  ) {
    return products.map(_mapGraphqlProductToLegacy).toList();
  }

  AllProductModel _mapGraphqlProductToLegacy(HomeGraphqlProduct product) {
    final displayVariants = product.displayableVariants;
    final selectedVariant = displayVariants.isNotEmpty
        ? displayVariants.first
        : (product.variants.isNotEmpty ? product.variants.first : null);

    final thumbnail = product.primaryVariantImageUrl.trim();
    final priceAmount = product.priceAmount;
    final originalAmount = product.originalPriceAmount > 0
        ? product.originalPriceAmount
        : product.priceAmount;
    final hasDiscount =
        product.hasDiscount &&
        originalAmount > 0 &&
        priceAmount > 0 &&
        priceAmount != originalAmount;
    final currencyCode = product.formattedCurrencyCode.trim().toUpperCase();
    final priceText = priceAmount > 0 ? priceAmount.toStringAsFixed(2) : '0';
    final regularText = originalAmount > 0
        ? originalAmount.toStringAsFixed(2)
        : priceText;
    final saleText = hasDiscount ? priceText : '';
    final productName = product.title.trim().isNotEmpty
        ? product.title
        : product.slug.trim().replaceAll('-', ' ');
    final shortDescription = ProductDescriptionFormatter.resolveShort(
      brief: product.brief,
      descriptionHtml: product.descriptionHtml,
      description: product.description,
      fallback: '',
    );
    final fullDescription = ProductDescriptionFormatter.resolveFull(
      descriptionHtml: product.descriptionHtml,
      description: product.description,
      shortDescription: product.brief,
      fallback: '',
    );
    final categories = product.categoryNames
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
        .map(
          (name) => {
            'id': name.hashCode.abs(),
            'name': name.trim(),
            'slug': name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
          },
        )
        .toList();

    return AllProductModel.fromJson({
      'id': product.uuid.hashCode.abs(),
      'name': productName,
      'slug': product.slug,
      'parent': 0,
      'type': 'simple',
      'variation': '',
      'permalink': 'https://camion-app.com/products/${product.slug}',
      'sku': selectedVariant?.sku ?? '',
      'short_description': shortDescription,
      'description': fullDescription,
      'on_sale': hasDiscount,
      'prices': {
        'price': priceText,
        'regular_price': regularText,
        'sale_price': saleText,
        'currency_code': currencyCode,
        'currency_symbol': currencyCode,
        'currency_minor_unit': 2,
        'currency_decimal_separator': '.',
        'currency_thousand_separator': ',',
        'currency_prefix': '',
        'currency_suffix': '',
      },
      'price_html': '',
      'average_rating': product.averageRatingText,
      'review_count': product.reviewsCount,
      'images': [
        if (thumbnail.isNotEmpty)
          {
            'id': 0,
            'src': thumbnail,
            'thumbnail': thumbnail,
            'srcset': '',
            'sizes': '',
            'name': productName,
            'alt': productName,
          },
      ],
      'categories': categories,
      'tags': const [],
      'brands': const [],
      'attributes': const [],
      'variations': const [],
      'has_options': product.options.isNotEmpty,
      'is_purchasable': true,
      'is_in_stock': true,
      'is_on_backorder': false,
      'stock_availability': {'text': '', 'class': ''},
      'sold_individually': false,
      'add_to_cart': {
        'text': 'Add to cart',
        'description': 'Add to cart',
        'url': '',
        'single_text': 'Add to cart',
        'minimum': 1,
        'maximum': 99,
        'multiple_of': 1,
      },
      'cart': false,
      'wishlist': false,
      'campaign': {
        'uuid': product.campaign?.uuid ?? '',
        'name': product.campaign?.name ?? '',
        'brief': product.campaign?.brief ?? '',
        'slug': product.campaign?.slug ?? '',
        'discountPercentage': product.campaign?.discountPercentage ?? 0,
        'startsAt': product.campaign?.startsAt?.toIso8601String() ?? '',
        'finishesAt': product.campaign?.finishesAt?.toIso8601String() ?? '',
      },
    });
  }
}
