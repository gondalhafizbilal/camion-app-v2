import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:dio/dio.dart';

class CartRemoteDataSource {
  final ApiConsumer apiConsumer;

  CartRemoteDataSource({required this.apiConsumer});

  static const String _getCustomerCartGraphql = r'''
    query GetCustomerCart($language: String, $currency: String) {
      getCustomerCart(language: $language, currency: $currency) {
        uuid
        product {
          uuid
          slug
          title(language: $language)
          featuredThumbnailUrl
          featuredImageUrl
          brief(language: $language)
          description(language: $language)
          descriptionHtml(language: $language)
          status
          salesCount
          likesCount
          reviewsCount
          ratingAvg
          ratingOneStarCount
          ratingTwoStarCount
          ratingThreeStarCount
          ratingFourStarCount
          ratingFiveStarCount
          campaign {
            uuid
            name(language: $language)
            brief(language: $language)
            slug
            discountPercentage
            startsAt
            finishesAt
          }
        }
        variant {
          uuid
          title(language: $language)
          sku
          barcode
          price(currency: $currency) {
            amount
            minorAmount
            currencyCode
          }
          discountedPrice(currency: $currency) {
            amount
            minorAmount
            currencyCode
          }
          weight {
            amount
            unit
          }
          dimensions {
            width
            height
            length
            unit
          }
          images {
            uuid
            imageUrl
            thumbnailUrl
            alt
            isFeatured
            position
          }
          optionValues{
            optionValue{
              uuid
              value(language: $language)
              position
              option {
                uuid
                name(language: $language)
                position
              }
            }
          }
        }
        availableStock
        subTotal {
          amount
          minorAmount
          currencyCode
        }
        quantity
      }
    }
  ''';

  String _selectedCurrencyCodeForApi() {
    final code = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (code == null || code.trim().isEmpty) {
      return AppDefaults.defaultCurrencyCode.toLowerCase();
    }
    return code.trim().toLowerCase();
  }

  Future<Response> addToCart({
    String? token,
    required String productUuid,
    required String variantUuid,
    required int quantity,
  }) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final normalizedProductUuid = productUuid.trim();
    final normalizedVariantUuid = variantUuid.trim();
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/v1/cart-items",

      headers: headers.isEmpty ? null : headers,
      data: {
        "currency": _selectedCurrencyCodeForApi(),
        "productUuid": normalizedProductUuid,
        "variantUuid": normalizedVariantUuid,
        "quantity": quantity,
      },
    );
    return response;
  }

  Future<Response> getCart({String? token, String? lang}) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    headers['x-allow-graphql-partial-data'] = 'true';
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: headers.isEmpty ? null : headers,
      data: {
        "query": _getCustomerCartGraphql,
        "variables": {
          "language": lang ?? AppDefaults.defaultLanguageCode,
          "currency": _selectedCurrencyCodeForApi(),
        },
      },
    );
    return response;
  }

  Future<Response> updateCart({
    String? token,
    required String cartItemUuid,
    required String productUuid,
    required String variantUuid,
    required int quantity,
  }) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final normalizedProductUuid = productUuid.trim();
    final normalizedVariantUuid = variantUuid.trim();
    final response = await apiConsumer.patch(
      "${EndPoints.baseUrl}/v1/cart-items/$cartItemUuid",
      headers: headers.isEmpty ? null : headers,
      data: {
        "currency": _selectedCurrencyCodeForApi(),
        "productUuid": normalizedProductUuid,
        "variantUuid": normalizedVariantUuid,
        "quantity": quantity,
      },
    );
    return response;
  }

  Future<Response> deleteFromCart({
    String? token,
    required String cartItemUuid,
  }) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await apiConsumer.delete(
      "${EndPoints.baseUrl}/v1/cart-items/$cartItemUuid",
      headers: headers.isEmpty ? null : headers,
    );
    return response;
  }

  Future<Response> clearCart({String? token}) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return apiConsumer.delete(
      "${EndPoints.baseUrl}/v1/cart-items",
      headers: headers.isEmpty ? null : headers,
    );
  }

  Future<Response> getUserAddress({required String token}) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/users/address/me",
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }
}
