import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_product_sections_state.dart';

class HomeProductSectionsCubit extends Cubit<HomeProductSectionsState> {
  HomeProductSectionsCubit(this.homeRepository)
    : super(HomeProductSectionsInitial());

  final HomeRepository homeRepository;
  static final Map<String, HomeProductSections> _sectionsCacheByLanguage = {};
  Future<void>? _inFlightRequest;
  String? _inFlightLanguage;
  int _requestGeneration = 0;

  void clearCache() {
    _requestGeneration++;
    _sectionsCacheByLanguage.clear();
    _inFlightRequest = null;
    _inFlightLanguage = null;
  }

  Future<void> getSections({
    required String locale,
    bool forceRefresh = false,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = locale.trim().toLowerCase().split('-').first;
    final cached = _sectionsCacheByLanguage[language];
    if (!forceRefresh && cached != null) {
      if (!isClosed) {
        emit(HomeProductSectionsLoaded(sections: cached));
      }
      return;
    }
    if (!forceRefresh &&
        _inFlightRequest != null &&
        _inFlightLanguage == language) {
      await _inFlightRequest;
      return;
    }

    final requestGeneration = ++_requestGeneration;
    final request = _loadSections(
      token: token,
      language: language,
      requestGeneration: requestGeneration,
    );
    _inFlightLanguage = language;
    _inFlightRequest = request;
    try {
      await request;
    } finally {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
        _inFlightLanguage = null;
      }
    }
  }

  Future<void> _loadSections({
    required String? token,
    required String language,
    required int requestGeneration,
  }) async {
    if (isClosed) return;
    emit(HomeProductSectionsLoading());

    bool isCurrentRequest() {
      return !isClosed &&
          requestGeneration == _requestGeneration &&
          _inFlightLanguage == language;
    }

    HomeGraphqlSectionQuery? queryFor(HomeProductSectionType type) {
      for (final definition in HomeRepository.defaultHomeGraphqlSections) {
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
    final featuredCampaignResult = await homeRepository
        .getFeaturedCampaignGraphql(token: token, language: language);
    final featuredCampaign = featuredCampaignResult.fold(
      (_) => null,
      (campaign) => campaign,
    );

    var sections = HomeProductSections(
      allProducts: const <HomeGraphqlProduct>[],
      featuredProducts: const <HomeGraphqlProduct>[],
      popularProducts: const <HomeGraphqlProduct>[],
      recentlyViewed: const <HomeGraphqlProduct>[],
      featuredCampaignTitle: featuredCampaign?.name ?? '',
      featuredCampaignEndsAt: featuredCampaign?.finishesAt,
      featuredCampaignProducts: const <HomeGraphqlProduct>[],
      featuredCampaignSections: const <HomeGraphqlCampaignSection>[],
    );
    ApiErrorModel? firstError;

    Future<void> loadOne<T>({
      required Future<Either<ApiErrorModel, List<T>>> future,
      required HomeProductSections Function(
        HomeProductSections current,
        List<T> items,
      )
      update,
    }) async {
      final result = await future;
      if (!isCurrentRequest()) return;

      result.fold((error) => firstError ??= error, (items) {
        if (!isCurrentRequest()) return;
        sections = update(sections, items);
        emit(HomeProductSectionsLoaded(sections: sections));
      });
    }

    await Future.wait([
      loadOne(
        future: homeRepository.getGraphqlProducts(
          token: token,
          language: language,
          sort: allQuery.sort,
          pageNumber: allQuery.pageNumber,
          itemsPerPage: allQuery.itemsPerPage,
        ),
        update: (current, items) => HomeProductSections(
          allProducts: items,
          featuredProducts: current.featuredProducts,
          popularProducts: current.popularProducts,
          recentlyViewed: current.recentlyViewed,
          featuredCampaignTitle: current.featuredCampaignTitle,
          featuredCampaignEndsAt: current.featuredCampaignEndsAt,
          featuredCampaignProducts: current.featuredCampaignProducts,
          featuredCampaignSections: current.featuredCampaignSections,
        ),
      ),
      loadOne(
        future: homeRepository.getFeaturedGraphqlProducts(
          token: token,
          language: language,
          pageNumber: featuredQuery.pageNumber,
          itemsPerPage: featuredQuery.itemsPerPage,
        ),
        update: (current, items) => HomeProductSections(
          allProducts: current.allProducts,
          featuredProducts: items,
          popularProducts: current.popularProducts,
          recentlyViewed: current.recentlyViewed,
          featuredCampaignTitle: current.featuredCampaignTitle,
          featuredCampaignEndsAt: current.featuredCampaignEndsAt,
          featuredCampaignProducts: current.featuredCampaignProducts,
          featuredCampaignSections: current.featuredCampaignSections,
        ),
      ),
      loadOne(
        future: homeRepository.getPopularGraphqlProducts(
          token: token,
          language: language,
          pageNumber: popularQuery.pageNumber,
          itemsPerPage: popularQuery.itemsPerPage,
        ),
        update: (current, items) => HomeProductSections(
          allProducts: current.allProducts,
          featuredProducts: current.featuredProducts,
          popularProducts: items,
          recentlyViewed: current.recentlyViewed,
          featuredCampaignTitle: current.featuredCampaignTitle,
          featuredCampaignEndsAt: current.featuredCampaignEndsAt,
          featuredCampaignProducts: current.featuredCampaignProducts,
          featuredCampaignSections: current.featuredCampaignSections,
        ),
      ),
      loadOne(
        future: homeRepository.getRecentlyViewedGraphqlProducts(
          token: token,
          language: language,
          pageNumber: recentlyViewedQuery.pageNumber,
          itemsPerPage: recentlyViewedQuery.itemsPerPage,
        ),
        update: (current, items) => HomeProductSections(
          allProducts: current.allProducts,
          featuredProducts: current.featuredProducts,
          popularProducts: current.popularProducts,
          recentlyViewed: items,
          featuredCampaignTitle: current.featuredCampaignTitle,
          featuredCampaignEndsAt: current.featuredCampaignEndsAt,
          featuredCampaignProducts: current.featuredCampaignProducts,
          featuredCampaignSections: current.featuredCampaignSections,
        ),
      ),
      if (featuredCampaign != null)
        loadOne(
          future: homeRepository.getProductsInFeaturedCampaignGraphql(
            token: token,
            language: language,
            pageNumber: 1,
            itemsPerPage: 8,
          ),
          update: (current, items) => HomeProductSections(
            allProducts: current.allProducts,
            featuredProducts: current.featuredProducts,
            popularProducts: current.popularProducts,
            recentlyViewed: current.recentlyViewed,
            featuredCampaignTitle: current.featuredCampaignTitle,
            featuredCampaignEndsAt: current.featuredCampaignEndsAt,
            featuredCampaignProducts: items,
            featuredCampaignSections: current.featuredCampaignSections,
          ),
        ),
    ]);

    if (!isCurrentRequest()) return;
    final hasAnyData =
        sections.allProducts.isNotEmpty ||
        sections.featuredProducts.isNotEmpty ||
        sections.popularProducts.isNotEmpty ||
        sections.recentlyViewed.isNotEmpty ||
        sections.featuredCampaignProducts.isNotEmpty ||
        sections.featuredCampaignSections.isNotEmpty;
    if (!hasAnyData && firstError != null) {
      emit(HomeProductSectionsError(error: firstError!));
      return;
    }

    _sectionsCacheByLanguage[language] = sections;
    emit(HomeProductSectionsLoaded(sections: sections));
  }
}
