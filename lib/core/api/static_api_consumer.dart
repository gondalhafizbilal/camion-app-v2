import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/static_api_payloads.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:dio/dio.dart';

class StaticApiConsumer extends ApiConsumer {
  StaticApiConsumer({required this.liveApiConsumer});

  final ApiConsumer liveApiConsumer;

  static const List<String> _preservedApiMarkers = ['/graphql', '/v1/auth/'];

  bool _shouldUseStatic(String path) {
    if (!AppConfig.instance.staticScreensMode) {
      return false;
    }
    for (final marker in _preservedApiMarkers) {
      if (path.contains(marker)) {
        return false;
      }
    }
    return true;
  }

  Response<dynamic> _buildResponse(
    String path,
    dynamic data, {
    int statusCode = 200,
  }) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: statusCode,
    );
  }

  Response<dynamic> _mockResponse(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedPath = path.toLowerCase();
    if (normalizedPath.endsWith('/graphql') && method == 'POST') {
      final payload = data is Map<String, dynamic>
          ? data
          : const <String, dynamic>{};
      final query = payload['query']?.toString() ?? '';
      if (query.contains('getProductsByCategory') ||
          query.contains('getProducts') ||
          query.contains('getFeaturedProducts') ||
          query.contains('getPopularProducts') ||
          query.contains('getRecentlyViewedProducts') ||
          query.contains('getRecommendedProducts') ||
          query.contains('getRelatedProducts') ||
          query.contains('searchProducts')) {
        final field = query.contains('getProductsByCategory')
            ? 'getProductsByCategory'
            : query.contains('getFeaturedProducts')
            ? 'getFeaturedProducts'
            : query.contains('getPopularProducts')
            ? 'getPopularProducts'
            : query.contains('getRecentlyViewedProducts')
            ? 'getRecentlyViewedProducts'
            : query.contains('getRecommendedProducts')
            ? 'getRecommendedProducts'
            : query.contains('getRelatedProducts')
            ? 'getRelatedProducts'
            : query.contains('searchProducts')
            ? 'searchProducts'
            : 'getProducts';
        return _buildResponse(path, {
          'data': {
            field: [
              for (final product in StaticApiPayloads.products())
                {
                  'uuid': 'product-${product['id']}',
                  'slug': product['slug'],
                  'title': product['name'],
                  'brief': product['short_description'],
                  'description': product['description'],
                  'descriptionHtml': product['description'],
                  'status': 'ACTIVE',
                  'options': const [],
                  'variants': [
                    {
                      'uuid': 'variant-${product['id']}',
                      'title': product['name'],
                      'sku': product['sku'],
                      'barcode': product['id'].toString(),
                      'price': {
                        'amount':
                            num.tryParse(
                              product['prices']?['price']?.toString() ?? '',
                            ) ??
                            0,
                        'currencyCode':
                            product['prices']?['currency_code']?.toString() ??
                            'QAR',
                      },
                    },
                  ],
                },
            ],
          },
        });
      }
      if (query.contains('getProduct(')) {
        final product = StaticApiPayloads.products().isNotEmpty
            ? StaticApiPayloads.products().first
            : <String, dynamic>{};
        return _buildResponse(path, {
          'data': {
            'getProduct': {
              'uuid': 'product-${product['id'] ?? 0}',
              'slug': product['slug']?.toString() ?? '',
              'title': product['name']?.toString() ?? '',
              'brief': product['short_description']?.toString() ?? '',
              'description': product['description']?.toString() ?? '',
              'descriptionHtml': product['description']?.toString() ?? '',
              'status': 'ACTIVE',
              'options': const [],
              'variants': [
                {
                  'uuid': 'variant-${product['id'] ?? 0}',
                  'title': product['name']?.toString() ?? '',
                  'sku': product['sku']?.toString() ?? '',
                  'barcode': product['id']?.toString() ?? '',
                  'price': {
                    'amount':
                        num.tryParse(
                          product['prices']?['price']?.toString() ?? '',
                        ) ??
                        0,
                    'currencyCode':
                        product['prices']?['currency_code']?.toString() ??
                        'QAR',
                  },
                },
              ],
              'reviews': const [],
            },
          },
        });
      }
      if (query.contains('getCurrentCustomer')) {
        return _buildResponse(path, {
          'data': {
            'getCurrentCustomer': {
              'uuid': 'static-customer-id',
              'fullName': 'Static Demo User',
              'emailAddress': 'demo@camion.app',
              'phoneNumber': '+974 12345678',
            },
          },
        });
      }
      if (query.contains('getCustomerWishlist')) {
        final products = StaticApiPayloads.products();
        final productsById = {
          for (final product in products)
            product['id']?.toString() ?? '': product,
        };

        final wishlist = [
          for (final item in StaticApiPayloads.wishlist())
            (() {
              final matchedProduct =
                  productsById[item['productId']?.toString() ?? ''] ?? {};
              final resolvedSlug =
                  matchedProduct['slug']?.toString() ??
                  (item['productName']?.toString() ?? '')
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                      .replaceAll(RegExp(r'-+'), '-')
                      .replaceAll(RegExp(r'^-|-$'), '');
              final resolvedTitle =
                  matchedProduct['name']?.toString() ??
                  item['productName']?.toString() ??
                  '';
              final resolvedBrief =
                  matchedProduct['short_description']?.toString() ?? '';
              final resolvedDescription =
                  matchedProduct['description']?.toString() ?? '';
              final resolvedImage =
                  ((matchedProduct['images'] as List?)?.isNotEmpty ?? false)
                  ? (matchedProduct['images'] as List).first['src']
                            ?.toString() ??
                        ''
                  : item['productImage']?.toString() ?? '';
              final resolvedCurrency =
                  matchedProduct['prices']?['currency_code']?.toString() ??
                  'QAR';

              return {
                'uuid': item['id'],
                'product': {
                  'uuid': item['productId'],
                  'slug': resolvedSlug,
                  'title': resolvedTitle,
                  'brief': resolvedBrief,
                  'description': resolvedDescription,
                  'descriptionHtml': resolvedDescription,
                  'status': 'ACTIVE',
                  'options': const [],
                  'variants': [
                    {
                      'uuid': 'variant-${item['productId']}',
                      'title': resolvedTitle,
                      'sku':
                          matchedProduct['sku']?.toString() ??
                          item['productId']?.toString() ??
                          '',
                      'barcode':
                          matchedProduct['id']?.toString() ??
                          item['productId']?.toString() ??
                          '',
                      'price': {
                        'amount':
                            num.tryParse(
                              matchedProduct['prices']?['price']?.toString() ??
                                  item['price']?.toString() ??
                                  '',
                            ) ??
                            0,
                        'currencyCode': resolvedCurrency,
                      },
                      'discountedPrice': {
                        'amount':
                            num.tryParse(
                              matchedProduct['prices']?['sale_price']
                                      ?.toString() ??
                                  matchedProduct['prices']?['price']
                                      ?.toString() ??
                                  item['price']?.toString() ??
                                  '',
                            ) ??
                            0,
                        'currencyCode': resolvedCurrency,
                      },
                      'images': [
                        {
                          'uuid': 'image-${item['productId']}',
                          'imageUrl': resolvedImage,
                          'thumbnailUrl': resolvedImage,
                          'alt': resolvedTitle,
                          'isFeatured': true,
                          'position': 1,
                        },
                      ],
                    },
                  ],
                },
              };
            })(),
        ];

        final responseData = <String, dynamic>{'getCustomerWishlist': wishlist};
        if (query.contains('getPopularProducts')) {
          responseData['popularProductsSection'] = [
            for (final product in StaticApiPayloads.products())
              {
                'uuid': 'product-${product['id']}',
                'slug': product['slug'],
                'title': product['name'],
                'brief': product['short_description'],
                'description': product['description'],
                'descriptionHtml': product['description'],
                'status': 'ACTIVE',
                'options': const [],
                'variants': [
                  {
                    'uuid': 'variant-${product['id']}',
                    'title': product['name'],
                    'sku': product['sku'],
                    'barcode': product['id'].toString(),
                    'price': {
                      'amount':
                          num.tryParse(
                            product['prices']?['price']?.toString() ?? '',
                          ) ??
                          0,
                      'currencyCode':
                          product['prices']?['currency_code']?.toString() ??
                          'QAR',
                    },
                    'images': [
                      {
                        'uuid': 'image-${product['id']}',
                        'imageUrl':
                            ((product['images'] as List?)?.isNotEmpty ?? false)
                            ? (product['images'] as List).first['src']
                            : '',
                        'thumbnailUrl':
                            ((product['images'] as List?)?.isNotEmpty ?? false)
                            ? (product['images'] as List).first['thumbnail']
                            : '',
                        'alt': product['name'],
                        'isFeatured': true,
                        'position': 1,
                      },
                    ],
                  },
                ],
              },
          ];
        }
        return _buildResponse(path, {'data': responseData});
      }
      if (query.contains('getCustomerCartCount') ||
          query.contains('getCustomerWishlistCount')) {
        return _buildResponse(path, {
          'data': {
            'getCustomerCartCount': StaticApiPayloads.cartItems().length,
            'getCustomerWishlistCount': StaticApiPayloads.wishlist().length,
          },
        });
      }
      if (query.contains('getBannersByPlacement') ||
          query.contains('getBannersByCategory') ||
          query.contains('getBanners')) {
        final placement = payload['variables'] is Map<String, dynamic>
            ? payload['variables']['placement']?.toString().trim() ?? ''
            : '';
        final slug = payload['variables'] is Map<String, dynamic>
            ? payload['variables']['slug']?.toString().trim() ?? ''
            : '';
        final requestedByPlacement = query.contains('getBannersByPlacement');
        final requestedByCategory = query.contains('getBannersByCategory');
        final shouldReturnCategoryBanners =
            slug.isNotEmpty &&
            !slug.contains('no-banner') &&
            !slug.contains('empty');
        final banners = requestedByCategory
            ? (shouldReturnCategoryBanners
                  ? [
                      for (final slider in StaticApiPayloads.sliders())
                        {
                          'uuid': 'banner-${slider['id']}',
                          'title': slider['title'],
                          'imageUrl': slider['imageUrl'],
                          'imageUrlAr': slider['imageUrl'],
                          'imageUrlEn': slider['imageUrl'],
                          'linkUrl': slider['description'],
                          'placement': slug,
                          'color': '#fffaf6',
                          'isActive': true,
                        },
                    ]
                  : const <Map<String, dynamic>>[])
            : (!requestedByPlacement ||
                  placement.isEmpty ||
                  placement == 'homepage' ||
                  placement == 'all-categories' ||
                  placement == 'all-categories-mobile')
            ? [
                for (final slider in StaticApiPayloads.sliders())
                  {
                    'uuid': 'banner-${slider['id']}',
                    'title': slider['title'],
                    'imageUrl': slider['imageUrl'],
                    'imageUrlAr': slider['imageUrl'],
                    'imageUrlEn': slider['imageUrl'],
                    'linkUrl': slider['description'],
                    'placement': placement.isNotEmpty
                        ? placement
                        : slider['discount'],
                    'color': '#fffaf6',
                    'isActive': true,
                  },
              ]
            : const <Map<String, dynamic>>[];
        return _buildResponse(path, {
          'data': {
            if (query.contains('getBannersByCategory'))
              'getBannersByCategory': banners,
            if (query.contains('getBannersByPlacement'))
              'getBannersByPlacement': banners,
            if (query.contains('getBanners')) 'getBanners': banners,
          },
        });
      }
      if (query.contains('getCategories')) {
        return _buildResponse(path, {
          'data': {
            'getCategories': [
              for (final category in StaticApiPayloads.categories())
                {
                  'uuid': 'category-${category['id']}',
                  'slug': category['slug'],
                  'name': category['name'],
                  'thumbnailUrl':
                      category['image']?['thumbnail']?.toString() ?? '',
                  'children': const [],
                },
            ],
          },
        });
      }
      if (query.contains('getStories')) {
        return _buildResponse(path, {
          'data': {
            'getStories': [
              for (final story in StaticApiPayloads.stories())
                {
                  'uuid': story['id'],
                  'caption': story['title'],
                  'isHighlighted': false,
                  'frames': [
                    {
                      'uuid': '${story['id']}-frame',
                      'mediaType': story['mediaType'],
                      'mediaUrl': story['mediaUrl'],
                      'thumbnailUrl': story['mediaUrl'],
                      'duration': story['duration'],
                      'order': 0,
                    },
                  ],
                },
            ],
          },
        });
      }
      if (query.contains('getCustomerAddresses')) {
        return _buildResponse(path, {
          'data': {
            'getCustomerAddresses': [
              {
                'uuid': 'address-static-1',
                'fullName': 'Static Demo User',
                'countryCode': 'QA',
                'phoneNumber': '12345678',
                'streetAddress': 'Preview Street 1',
                'apartment': 'Apartment 2',
                'zipCode': '00001',
                'city': 'Doha',
                'state': 'Doha',
                'country': 'Qatar',
                'isDefault': true,
              },
            ],
          },
        });
      }
      if (query.contains('createCustomerAddress')) {
        return _buildResponse(path, {
          'data': {
            'createCustomerAddress': {'uuid': 'address-static-created'},
          },
        });
      }
      if (query.contains('updateCustomerAddress')) {
        return _buildResponse(path, {
          'data': {
            'updateCustomerAddress': {'uuid': 'address-static-updated'},
          },
        });
      }
      if (query.contains('patchCustomerAddress')) {
        return _buildResponse(path, {
          'data': {
            'patchCustomerAddress': {
              'uuid': 'address-static-patched',
              'isDefault': true,
            },
          },
        });
      }
      return _buildResponse(path, {'data': {}});
    }

    if (normalizedPath.contains('/v1/auth/customer/register')) {
      return _buildResponse(path, {
        'token': StaticApiPayloads.demoToken,
        'customer': {
          'uuid': 'static-customer-id',
          'fullName': 'Static Demo User',
          'emailAddress': 'demo@camion.app',
          'phoneNumber': '+974 12345678',
          'role': 'customer',
        },
      });
    }
    if (normalizedPath.contains('/v1/auth/customer/login/email-address') ||
        normalizedPath.contains('/v1/auth/customer/login/phone-number')) {
      return _buildResponse(path, {'token': StaticApiPayloads.demoToken});
    }
    if (normalizedPath.contains('/v1/auth/customer/verify/email-address') ||
        normalizedPath.contains('/v1/auth/customer/verify/phone-number')) {
      return _buildResponse(path, {
        'token': StaticApiPayloads.demoToken,
        'customer': {
          'uuid': 'static-customer-id',
          'fullName': 'Static Demo User',
          'emailAddress': 'demo@camion.app',
          'phoneNumber': '+974 12345678',
          'role': 'customer',
        },
      });
    }
    if (normalizedPath.contains('/v1/auth/customer/logout')) {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/v1/auth/guest/register')) {
      return _buildResponse(path, {'token': 'static-guest-access-token'});
    }
    if (normalizedPath.contains('/users/address/update')) {
      return _buildResponse(path, StaticApiPayloads.shippingAddress());
    }
    if (normalizedPath.contains('/users/address/me')) {
      return _buildResponse(path, StaticApiPayloads.shippingAddress());
    }
    if (normalizedPath.endsWith('/v1/cart-items') && method == 'GET') {
      return _buildResponse(path, StaticApiPayloads.cartItems());
    }
    if (normalizedPath.endsWith('/v1/cart-items') && method == 'POST') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/v1/cart-items/') && method == 'PATCH') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/v1/cart-items/') && method == 'DELETE') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.endsWith('/v1/cart-items') && method == 'DELETE') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.endsWith('/wishlist/get')) {
      return _buildResponse(path, StaticApiPayloads.wishlist());
    }
    if (normalizedPath.endsWith('/wishlist/add') ||
        normalizedPath.endsWith('/wishlist/remove')) {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.endsWith('/v1/wishlist') && method == 'GET') {
      return _buildResponse(path, StaticApiPayloads.wishlist());
    }
    if (normalizedPath.endsWith('/v1/wishlist') && method == 'POST') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/v1/wishlist/') && method == 'DELETE') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.endsWith('/v1/orders') && method == 'POST') {
      return _buildResponse(path, StaticApiPayloads.createOrderResponse());
    }
    if (normalizedPath.endsWith('/v1/orders') && method == 'GET') {
      return _buildResponse(path, StaticApiPayloads.orders());
    }
    if (normalizedPath.contains('/v1/orders?filters=')) {
      return _buildResponse(path, StaticApiPayloads.orders());
    }
    if (normalizedPath.endsWith('/v1/orders/order-preview')) {
      return _buildResponse(path, StaticApiPayloads.createOrderResponse());
    }
    if (normalizedPath.contains('/tracking/order/') ||
        normalizedPath.endsWith('/tracking')) {
      return _buildResponse(path, StaticApiPayloads.trackingResponse());
    }
    if (normalizedPath.contains('/v1/orders/')) {
      return _buildResponse(path, StaticApiPayloads.orders());
    }
    if (normalizedPath.contains('/users/notifications/me')) {
      return _buildResponse(path, StaticApiPayloads.notifications());
    }
    if (normalizedPath.contains('/users/notifications/token')) {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/users/') && method == 'GET') {
      return _buildResponse(path, StaticApiPayloads.userProfile());
    }
    if (normalizedPath.contains('/users/') && method == 'PATCH') {
      return _buildResponse(path, {
        ...StaticApiPayloads.userProfile(),
        ...(data is Map<String, dynamic> ? data : <String, dynamic>{}),
      });
    }
    if (normalizedPath.contains('/users/') && method == 'DELETE') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/currency/list')) {
      return _buildResponse(path, StaticApiPayloads.currencies());
    }
    if (normalizedPath.contains('/currency/convert-products')) {
      return _buildResponse(path, {
        'products': (data as Map?)?['products'] ?? [],
      });
    }
    if (normalizedPath.contains('/currency') && method == 'PATCH') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/affiliates/request')) {
      return _buildResponse(path, StaticApiPayloads.affiliateProfile());
    }
    if (normalizedPath.contains('/influencers/request')) {
      return _buildResponse(
        path,
        StaticApiPayloads.affiliateProfile(
          id: 'influencer-1',
          type: 'influencer',
        ),
      );
    }
    if (normalizedPath.contains('/affiliates/me/status')) {
      return _buildResponse(path, StaticApiPayloads.affiliateStatus());
    }
    if (normalizedPath.contains('/influencers/me/status')) {
      return _buildResponse(
        path,
        StaticApiPayloads.affiliateStatus(affiliateId: 'influencer-1'),
      );
    }
    if (normalizedPath.contains('/affiliates/coupon/me')) {
      return _buildResponse(path, StaticApiPayloads.affiliateCoupons());
    }
    if (normalizedPath.contains('/affiliates/coupon')) {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/affiliates/wallet/transactions')) {
      return _buildResponse(path, StaticApiPayloads.transactions());
    }
    if (normalizedPath.contains('/affiliates/wallet')) {
      return _buildResponse(path, StaticApiPayloads.wallet());
    }
    if (normalizedPath.contains('/v1/chatbot/sessions') &&
        method == 'POST' &&
        !normalizedPath.contains('/ask')) {
      return _buildResponse(path, StaticApiPayloads.chatbotSession());
    }
    if (normalizedPath.contains('/v1/chatbot/sessions/') &&
        normalizedPath.contains('/history')) {
      return _buildResponse(path, StaticApiPayloads.chatbotHistory());
    }
    if (normalizedPath.contains('/v1/chatbot/sessions/') &&
        normalizedPath.contains('/ask')) {
      return _buildResponse(path, StaticApiPayloads.chatbotAnswer());
    }
    if (normalizedPath.endsWith('/products') ||
        normalizedPath.contains('/products?')) {
      return _buildResponse(path, {'products': StaticApiPayloads.products()});
    }
    if (normalizedPath.contains('/products/reviews') && method == 'GET') {
      return _buildResponse(path, StaticApiPayloads.reviews());
    }
    if (normalizedPath.contains('/products/reviews') && method == 'POST') {
      return _buildResponse(path, StaticApiPayloads.genericSuccess());
    }
    if (normalizedPath.contains('/products/')) {
      final id = int.tryParse(path.split('/').last) ?? 101;
      final product = StaticApiPayloads.products().firstWhere(
        (item) => item['id'] == id,
        orElse: () => StaticApiPayloads.demoProduct(id: id),
      );
      return _buildResponse(path, product);
    }
    if (normalizedPath.endsWith('/categories')) {
      return _buildResponse(path, StaticApiPayloads.categories());
    }
    if (normalizedPath.contains('/categories/')) {
      return _buildResponse(path, {
        'subcategories': StaticApiPayloads.categories(),
      });
    }
    if (normalizedPath.endsWith('/sliders')) {
      return _buildResponse(path, StaticApiPayloads.sliders());
    }
    if (normalizedPath.contains('/stories/active')) {
      return _buildResponse(path, StaticApiPayloads.stories());
    }
    if (normalizedPath.contains('/stories/')) {
      return _buildResponse(path, StaticApiPayloads.stories().first);
    }

    return _buildResponse(path, StaticApiPayloads.genericSuccess());
  }

  Future<Response<dynamic>> _callWithFallback({
    required String method,
    required String path,
    required Object? data,
    required Map<String, dynamic>? queryParameters,
    required Future<Response<dynamic>> Function() liveCall,
  }) async {
    if (_shouldUseStatic(path)) {
      return _mockResponse(
        method,
        path,
        data: data,
        queryParameters: queryParameters,
      );
    }

    try {
      final response = await liveCall();
      final statusCode = response.statusCode ?? 500;
      if (statusCode >= 500) {
        return _mockResponse(
          method,
          path,
          data: data,
          queryParameters: queryParameters,
        );
      }
      return response;
    } catch (_) {
      return _mockResponse(
        method,
        path,
        data: data,
        queryParameters: queryParameters,
      );
    }
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _callWithFallback(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      liveCall: () => liveApiConsumer.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _callWithFallback(
      method: 'GET',
      path: path,
      data: data,
      queryParameters: queryParameters,
      liveCall: () => liveApiConsumer.get(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _callWithFallback(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      liveCall: () => liveApiConsumer.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _callWithFallback(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      liveCall: () => liveApiConsumer.post(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _callWithFallback(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      liveCall: () => liveApiConsumer.put(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );
  }
}
