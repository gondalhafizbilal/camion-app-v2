import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/features/home/data/data_source/remote_data_source.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString:
        'BASE_URL=https://api.dev.camiontrading.com\n'
        'ASSETS_HOST=https://assets.dev.camiontrading.com',
  );
  AppConfig.initialize(flavor: AppFlavor.development, envFile: '.env');

  group('HomeRepository GraphQL', () {
    test('maps GraphQL stories into story viewer models', () async {
      final repository = HomeRepository(
        remoteDataSource: StubHomeRemoteDataSource(
          graphqlResponse: _response(
            data: {
              'data': {
                'getStories': [
                  {
                    'uuid': 'story-1',
                    'caption': 'Spring collection',
                    'frames': [
                      {
                        'uuid': 'frame-1',
                        'mediaType': 'image',
                        'mediaUrl': 'https://example.com/story.jpg',
                        'thumbnailUrl': 'https://example.com/thumb.jpg',
                        'duration': 6,
                        'order': 0,
                      },
                      {
                        'uuid': 'frame-2',
                        'mediaType': 'video',
                        'mediaUrl': 'https://example.com/story.mp4',
                        'thumbnailUrl':
                            'https://example.com/story-video-thumb.jpg',
                        'duration': 8,
                        'order': 1,
                      },
                    ],
                  },
                ],
              },
            },
          ),
        ),
      );

      final result = await repository.getGraphqlStories(
        token: 'token',
        language: 'en',
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected mapped stories'), (stories) {
        expect(stories, hasLength(1));
        expect(stories.first.id, 'story-1');
        expect(stories.first.mediaUrl, 'https://example.com/story.jpg');
        expect(stories.first.thumbnailUrl, 'https://example.com/thumb.jpg');
        expect(stories.first.duration, 6);
        expect(stories.first.frames, hasLength(2));
        expect(
          stories.first.frames.first.mediaUrl,
          'https://example.com/story.jpg',
        );
        expect(stories.first.frames.last.mediaType, 'video');
        expect(
          stories.first.frames.last.mediaUrl,
          'https://example.com/story.mp4',
        );
      });
    });

    test('maps GraphQL banners and categories', () async {
      final repository = HomeRepository(
        remoteDataSource: StubHomeRemoteDataSource.sequence(
          responses: [
            _response(
              data: {
                'data': {'getBannersByPlacement': const []},
              },
            ),
            _response(
              data: {
                'data': {
                  'getBanners': [
                    {
                      'uuid': 'banner-1',
                      'title': 'Main banner',
                      'imageUrl': 'https://example.com/banner.jpg',
                      'linkUrl': '/sale',
                      'placement': 'homepage',
                    },
                  ],
                },
              },
            ),
            _response(
              data: {
                'data': {
                  'getCategories': [
                    {
                      'uuid': 'category-1',
                      'slug': 'electronics',
                      'name': 'Electronics',
                    },
                  ],
                },
              },
            ),
          ],
        ),
      );

      final banners = await repository.getGraphqlBanners(
        token: 'token',
        language: 'en',
        placement: 'homepage',
      );
      final categories = await repository.getGraphqlCategories(
        token: 'token',
        language: 'en',
      );

      expect(banners.isRight(), isTrue);
      expect(categories.isRight(), isTrue);
      banners.fold((_) => fail('Expected banners'), (items) {
        expect(items.first.title, 'Main banner');
        expect(items.first.description, '/sale');
      });
      categories.fold((_) => fail('Expected categories'), (items) {
        expect(items.first.uuid, 'category-1');
        expect(items.first.slug, 'electronics');
      });
    });

    test(
      'falls back to all banners for category feed when mobile placement is empty',
      () async {
        final repository = HomeRepository(
          remoteDataSource: StubHomeRemoteDataSource.sequence(
            responses: [
              _response(
                data: {
                  'data': {
                    'categoriesSection': [
                      {
                        'uuid': 'category-1',
                        'slug': 'electronics',
                        'name': 'Electronics',
                      },
                    ],
                    'bannersSection': const [],
                  },
                },
              ),
              _response(
                data: {
                  'data': {
                    'getBanners': [
                      {
                        'uuid': 'banner-1',
                        'title': 'Fallback banner',
                        'imageUrl': 'https://example.com/fallback.jpg',
                        'linkUrl': '/fallback',
                        'placement': 'any',
                      },
                    ],
                  },
                },
              ),
            ],
          ),
        );

        final result = await repository.getCategoryFeedGraphql(
          token: 'token',
          language: 'en',
          placement: 'all-categories-mobile',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected category feed'), (feed) {
          expect(feed.categories, hasLength(1));
          expect(feed.categories.first.slug, 'electronics');
          expect(feed.banners, hasLength(1));
          expect(feed.banners.first.title, 'Fallback banner');
        });
      },
    );

    test('maps featured campaign categories into home sections', () async {
      final repository = HomeRepository(
        remoteDataSource: StubHomeRemoteDataSource.sequence(
          responses: [
            _response(
              data: {
                'data': {
                  'getFeaturedCampaign': {
                    'uuid': 'campaign-1',
                    'name': 'Summer 50%',
                    'slug': 'summer-50',
                    'discountPercentage': 50,
                    'startsAt': '2026-01-01T00:00:00.000Z',
                    'finishesAt': '2026-12-31T00:00:00.000Z',
                    'campaignCategories': [
                      {
                        'category': {
                          'uuid': 'category-1',
                          'slug': 'women-clothing',
                          'name': 'Women Clothing',
                          'thumbnailUrl': 'https://example.com/women.jpg',
                        },
                      },
                      {
                        'category': {
                          'uuid': 'category-2',
                          'slug': 'men-clothing',
                          'name': 'Men Clothing',
                          'thumbnailUrl': 'https://example.com/men.jpg',
                        },
                      },
                    ],
                  },
                },
              },
            ),
            _response(
              data: {
                'data': {
                  'getProductsByCategory': [
                    {
                      'uuid': 'women-product-1',
                      'slug': 'women-top',
                      'title': 'Women Top',
                      'brief': 'Women campaign item',
                      'description': 'Product description',
                      'status': 'active',
                      'variants': [
                        {
                          'uuid': 'variant-1',
                          'price': {'amount': 52, 'currencyCode': 'QAR'},
                          'discountedPrice': {
                            'amount': 34,
                            'currencyCode': 'QAR',
                          },
                        },
                      ],
                    },
                  ],
                },
              },
            ),
            _response(
              data: {
                'data': {'getProductsByCategory': []},
              },
            ),
            _response(
              data: {
                'data': {'getProducts': []},
              },
            ),
            _response(
              data: {
                'data': {'getFeaturedProducts': []},
              },
            ),
            _response(
              data: {
                'data': {'getPopularProducts': []},
              },
            ),
            _response(
              data: {
                'data': {'getRecentlyViewedProducts': []},
              },
            ),
          ],
        ),
      );

      final sections = await repository.getHomeSectionsGraphql(
        token: 'token',
        language: 'en',
      );

      expect(sections.isRight(), isTrue);
      sections.fold((_) => fail('Expected home sections'), (value) {
        expect(value.featuredCampaignTitle, 'Summer 50%');
        expect(value.featuredCampaignSections, hasLength(1));
        expect(
          value.featuredCampaignSections.first.categorySlug,
          'women-clothing',
        );
        expect(
          value.featuredCampaignSections.first.categoryName,
          'Women Clothing',
        );
        expect(value.featuredCampaignSections.first.products, hasLength(1));
        expect(
          value.featuredCampaignSections.first.products.first.uuid,
          'women-product-1',
        );
      });
    });

    test('maps GraphQL products and locale mapping safely', () async {
      final repository = HomeRepository(
        remoteDataSource: StubHomeRemoteDataSource(
          graphqlResponse: _response(
            data: {
              'data': {
                'getProducts': [
                  {
                    'uuid': 'product-1',
                    'slug': 'iphone-17',
                    'title': 'iPhone 17',
                    'brief': 'Popular flagship',
                    'description': 'Product description',
                    'status': 'ACTIVE',
                    'campaign': {
                      'uuid': 'campaign-1',
                      'name': 'Summer 50%',
                      'brief': 'Campaign brief',
                      'slug': 'summer-50',
                      'discountPercentage': 50,
                      'startsAt': '2026-01-01T00:00:00.000Z',
                      'finishesAt': '2026-12-31T00:00:00.000Z',
                    },
                    'variants': [
                      {
                        'uuid': 'variant-1',
                        'price': {'amount': 1000, 'currencyCode': 'QAR'},
                      },
                    ],
                  },
                ],
              },
            },
          ),
        ),
      );

      final result = await repository.getGraphqlProducts(
        token: 'token',
        language: ApiLocaleMapper.toGraphqlLocale('nl'),
        sort: 'popularity:desc',
      );

      expect(ApiLocaleMapper.toGraphqlLocale('nl'), 'en');
      expect(ApiLocaleMapper.toGraphqlLocale('ur'), 'en');
      expect(ApiLocaleMapper.toGraphqlLocale('ar'), 'ar');
      expect(ApiLocaleMapper.toGraphqlLocale('en-us'), 'en');
      expect(ApiLocaleMapper.toGraphqlLocale('unknown'), 'en');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected mapped products'), (products) {
        expect(products.first.uuid, 'product-1');
        expect(products.first.formattedPrice, '1000.00');
        expect(products.first.currencyCode, 'QAR');
        expect(products.first.campaign?.name, 'Summer 50%');
        expect(products.first.campaign?.finishesAt, isNotNull);
      });
    });

    test('maps legacy getProducts results with campaign data', () async {
      final remote = StubHomeRemoteDataSource(
        graphqlResponse: _response(
          data: {
            'data': {
              'getProducts': [
                {
                  'uuid': 'product-legacy-1',
                  'slug': 'legacy-product',
                  'title': 'Legacy Product',
                  'brief': 'Legacy brief',
                  'description': 'Legacy description',
                  'descriptionHtml': 'Legacy description',
                  'status': 'active',
                  'featuredThumbnailUrl':
                      'https://example.com/legacy-thumb.jpg',
                  'featuredImageUrl': 'https://example.com/legacy.jpg',
                  'campaign': {
                    'uuid': 'campaign-legacy',
                    'name': 'Legacy Summer 60%',
                    'brief': 'Legacy campaign brief',
                    'slug': 'legacy-summer-60',
                    'discountPercentage': 60,
                    'startsAt': '2026-01-01T00:00:00.000Z',
                    'finishesAt': '2026-12-31T00:00:00.000Z',
                  },
                  'variants': [
                    {
                      'uuid': 'variant-legacy-1',
                      'sku': 'legacy-sku',
                      'price': {'amount': 120, 'currencyCode': 'QAR'},
                      'discountedPrice': {'amount': 90, 'currencyCode': 'QAR'},
                      'images': [
                        {
                          'uuid': 'image-legacy-1',
                          'imageUrl': 'https://example.com/legacy-thumb.jpg',
                          'thumbnailUrl':
                              'https://example.com/legacy-thumb.jpg',
                          'alt': '',
                          'isFeatured': true,
                          'position': 0,
                        },
                      ],
                    },
                  ],
                  'salesCount': 1,
                  'likesCount': 7,
                  'reviewsCount': 2,
                  'ratingAvg': 4.8,
                },
              ],
            },
          },
        ),
      );
      final repository = HomeRepository(remoteDataSource: remote);

      final result = await repository.getProducts(
        page: 1,
        perPage: 10,
        lang: 'en',
        sort: 'best-match',
      );

      expect(remote.lastQuery, contains('GetProducts'));
      expect(remote.lastVariables['sort'], 'best-match');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected legacy products'), (products) {
        expect(products, hasLength(1));
        expect(products.first.campaign?.name, 'Legacy Summer 60%');
        expect(products.first.campaign?.discountPercentage, 60);
        expect(
          products.first.primaryImageUrl,
          'https://example.com/legacy-thumb.jpg',
        );
      });
    });

    test('passes new search sort values to GraphQL', () async {
      final remote = StubHomeRemoteDataSource(
        graphqlResponse: _response(
          data: {
            'data': {'searchProducts': []},
          },
        ),
      );
      final repository = HomeRepository(remoteDataSource: remote);

      await repository.searchGraphqlProducts(
        language: 'en',
        queryText: 'phone',
        sort: 'new-arrivals',
      );

      expect(remote.lastQuery, contains('searchProducts'));
      expect(remote.lastVariables['sort'], 'new-arrivals');
      expect(remote.lastVariables['query'], 'phone');
    });

    test('passes featured sort values to GraphQL', () async {
      final remote = StubHomeRemoteDataSource(
        graphqlResponse: _response(
          data: {
            'data': {'getFeaturedProducts': []},
          },
        ),
      );
      final repository = HomeRepository(remoteDataSource: remote);

      await repository.getFeaturedGraphqlProducts(
        language: 'en',
        sort: 'most-rated',
      );

      expect(remote.lastQuery, contains('getFeaturedProducts'));
      expect(remote.lastVariables['sort'], 'most-rated');
      expect(remote.lastVariables['language'], 'en');
    });

    test('passes popular sort values to GraphQL', () async {
      final remote = StubHomeRemoteDataSource(
        graphqlResponse: _response(
          data: {
            'data': {'getPopularProducts': []},
          },
        ),
      );
      final repository = HomeRepository(remoteDataSource: remote);

      await repository.getPopularGraphqlProducts(
        language: 'ar',
        sort: 'most-viewed',
      );

      expect(remote.lastQuery, contains('getPopularProducts'));
      expect(remote.lastVariables['sort'], 'most-viewed');
      expect(remote.lastVariables['language'], 'ar');
    });

    test('passes category sort values and campaign data to GraphQL', () async {
      final remote = StubHomeRemoteDataSource(
        graphqlResponse: _response(
          data: {
            'data': {
              'getProductsByCategory': [
                {
                  'uuid': 'category-product-1',
                  'slug': 'women-shirt',
                  'title': 'Women Shirt',
                  'brief': 'Category brief',
                  'description': 'Category description',
                  'descriptionHtml': 'Category description',
                  'salesCount': 3,
                  'likesCount': 4,
                  'reviewsCount': 5,
                  'ratingAvg': 4.2,
                  'featuredThumbnailUrl':
                      'https://example.com/category-thumb.jpg',
                  'featuredImageUrl': 'https://example.com/category.jpg',
                  'campaign': {
                    'uuid': 'campaign-category',
                    'name': 'Category Summer 70%',
                    'brief': 'Get 70% off on all summer wear',
                    'slug': 'category-summer-70',
                    'discountPercentage': 70,
                    'startsAt': '2026-01-01T00:00:00.000Z',
                    'finishesAt': '2026-12-31T00:00:00.000Z',
                  },
                  'variants': [
                    {
                      'uuid': 'variant-category-1',
                      'sku': 'women-shirt-sku',
                      'price': {'amount': 7500, 'currencyCode': 'QAR'},
                      'discountedPrice': {
                        'amount': 6750,
                        'currencyCode': 'QAR',
                      },
                      'images': [
                        {
                          'uuid': 'image-category-1',
                          'imageUrl': 'https://example.com/category-thumb.jpg',
                          'thumbnailUrl':
                              'https://example.com/category-thumb.jpg',
                          'alt': '',
                          'isFeatured': false,
                          'position': 0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        ),
      );
      final repository = HomeRepository(remoteDataSource: remote);

      final result = await repository.getProductsByCategoryGraphql(
        slug: 'women-shirts',
        language: 'en',
        sort: 'price:low-to-high',
        pageNumber: 1,
        itemsPerPage: 24,
      );

      expect(remote.lastQuery, contains('GetProductsByCategory'));
      expect(remote.lastVariables['sort'], 'price:low-to-high');
      expect(remote.lastVariables['slug'], 'women-shirts');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected category products'), (products) {
        expect(products, hasLength(1));
        expect(products.first.campaign?.name, 'Category Summer 70%');
        expect(products.first.campaign?.discountPercentage, 70);
        expect(
          products.first.primaryVariantImageUrl,
          'https://example.com/category-thumb.jpg',
        );
      });
    });

    test('passes category slug lists to the new GraphQL endpoint', () async {
      final remote = StubHomeRemoteDataSource(
        graphqlResponse: _response(
          data: {
            'data': {
              'getProductsByCategories': [
                {
                  'uuid': 'category-product-2',
                  'slug': 'women-skirt',
                  'title': 'Women Skirt',
                  'brief': 'Category list brief',
                  'description': 'Category list description',
                  'descriptionHtml': 'Category list description',
                  'variants': [
                    {
                      'uuid': 'variant-category-2',
                      'sku': 'women-skirt-sku',
                      'price': {'amount': 250, 'currencyCode': 'QAR'},
                    },
                  ],
                },
              ],
            },
          },
        ),
      );
      final repository = HomeRepository(remoteDataSource: remote);

      final result = await repository.getProductsByCategoriesGraphql(
        slugs: ['women-shirts', 'women-skirts'],
        language: 'en',
        sort: 'best-match',
        pageNumber: 1,
        itemsPerPage: 24,
      );

      expect(remote.lastQuery, contains('GetProductsByCategories'));
      expect(remote.lastVariables['slugs'], ['women-shirts', 'women-skirts']);
      expect(remote.lastVariables['sort'], 'best-match');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected category list products'), (products) {
        expect(products, hasLength(1));
        expect(products.first.slug, 'women-skirt');
      });
    });
  });
}

class StubHomeRemoteDataSource extends HomeRemoteDataSource {
  StubHomeRemoteDataSource({this.graphqlResponse})
    : responses = null,
      super(apiConsumer: _NoopApiConsumer());

  StubHomeRemoteDataSource.sequence({required this.responses})
    : graphqlResponse = null,
      super(apiConsumer: _NoopApiConsumer());

  final Response<dynamic>? graphqlResponse;
  final List<Response<dynamic>>? responses;
  String lastQuery = '';
  Map<String, dynamic> lastVariables = const {};
  int _index = 0;

  @override
  Future<Response> postGraphql({
    String? token,
    required String query,
    required Map<String, dynamic> variables,
    bool allowGraphqlPartialData = false,
    bool suppressBackendUnavailableBanner = false,
  }) async {
    lastQuery = query;
    lastVariables = variables;
    if (responses != null) {
      return responses![_index++];
    }
    return graphqlResponse ?? _response(data: {'data': {}});
  }
}

class _NoopApiConsumer implements ApiConsumer {
  @override
  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }
}

Response<dynamic> _response({required Map<String, dynamic> data}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/graphql'),
    data: data,
    statusCode: 200,
  );
}
