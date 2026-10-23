import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:dio/dio.dart';

class WishListRemoteDataSource {
  final ApiConsumer apiConsumer;

  WishListRemoteDataSource({required this.apiConsumer});

  static const String _customerWishlistGraphql = r'''
    query GetCustomerWishlist(
      $language: String
      $currency: String
      $pageNumber: Int
      $itemsPerPage: Int
    ) {
      getCustomerWishlist(
        language: $language
        currency: $currency
        pageNumber: $pageNumber
        itemsPerPage: $itemsPerPage
      ) {
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
            name
            brief
            slug
            discountPercentage
            startsAt
            finishesAt
          }
        }
        variant {
          uuid
          title
          sku
          barcode
          price(currency: $currency) {
            amount
            currencyCode
          }
          discountedPrice(currency: $currency) {
            amount
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
        }
      }
    }
  ''';

  static const String _wishlistAndPopularGraphql = r'''
    query GetWishlistAndPopular(
      $language: String
      $currency: String!
      $popularPageNumber: Int
      $popularItemsPerPage: Int
    ) {
      getCustomerWishlist(
        language: $language
        currency: $currency
        pageNumber: 1
        itemsPerPage: 100
      ) {
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
            name
            brief
            slug
            discountPercentage
            startsAt
            finishesAt
          }
        }
        variant {
          uuid
          title
          sku
          barcode
          price(currency: $currency) {
            amount
            currencyCode
          }
          discountedPrice(currency: $currency) {
            amount
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
        }
      }
      popularProductsSection: getPopularProducts(
        language: $language
        currency: $currency
        pageNumber: $popularPageNumber
        itemsPerPage: $popularItemsPerPage
      ) {
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
        options {
          uuid
          name(language: $language)
          position
          values {
            uuid
            value(language: $language)
            position
          }
        }
        variants {
          uuid
          title(language: $language)
          sku
          barcode
          price(currency: $currency) {
            amount
            currencyCode
          }
          discountedPrice(currency: $currency) {
            amount
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
          optionValues {
            optionValue {
              uuid
            }
          }
          images {
            uuid
            imageUrl
            thumbnailUrl
            alt
            isFeatured
            position
          }
        }
        reviews {
          uuid
          rating
          comment
          customer {
            uuid
            fullName
          }
          images {
            uuid
            thumbnailUrl
            imageUrl
          }
        }
      }
    }
  ''';

  static const String _popularProductsGraphql = r'''
    query GetPopularProducts(
      $language: String
      $currency: String!
      $pageNumber: Int
      $itemsPerPage: Int
    ) {
      getPopularProducts(
        language: $language
        currency: $currency
        pageNumber: $pageNumber
        itemsPerPage: $itemsPerPage
      ) {
        uuid
        slug
        title(language: $language)
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
        options {
          uuid
          name(language: $language)
          position
          values {
            uuid
            value(language: $language)
            position
          }
        }
        variants {
          uuid
          title(language: $language)
          sku
          barcode
          price(currency: $currency) {
            amount
            currencyCode
          }
          discountedPrice(currency: $currency) {
            amount
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
          optionValues {
            optionValue {
              uuid
            }
          }
          images {
            uuid
            imageUrl
            thumbnailUrl
            alt
            isFeatured
            position
          }
        }
        reviews {
          uuid
          rating
          comment
          customer {
            uuid
            fullName
          }
          images {
            uuid
            thumbnailUrl
            imageUrl
          }
        }
      }
    }
  ''';

  String _selectedLanguageCode() {
    final lang = sl<CacheHelper>().getDataString(key: 'languageCode');
    if (lang == null || lang.trim().isEmpty) {
      return AppDefaults.defaultLanguageCode;
    }
    return lang.trim();
  }

  String _selectedCurrencyCode() {
    final code = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (code == null || code.trim().isEmpty) {
      return AppDefaults.defaultCurrencyCode.toLowerCase();
    }
    return code.trim().toLowerCase();
  }

  Future<Response> addToWishList({
    required String token,
    required String productId,
    String? variantUuid,
    required String title,
    required String price,
    required String image,
  }) async {
    final normalizedVariantUuid = (variantUuid ?? '').trim();
    final payload = <String, dynamic>{
      // Keep both key styles for backward compatibility across environments.
      "productUUID": productId,
      "productUuid": productId,
      if (normalizedVariantUuid.isNotEmpty) ...{
        "variantUUID": normalizedVariantUuid,
        "variantUuid": normalizedVariantUuid,
      },
    };
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/v1/wishlist",
      headers: {"Authorization": "Bearer $token"},
      data: payload,
    );
    return response;
  }

  Future<Response> getWishList({
    required String token,
    int pageNumber = 1,
    int itemsPerPage = 100,
  }) async {
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _customerWishlistGraphql,
        "variables": {
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
          "pageNumber": pageNumber,
          "itemsPerPage": itemsPerPage,
        },
      },
    );
    return response;
  }

  Future<Response> getWishListAndPopularGraphql({
    required String token,
    int popularPageNumber = 1,
    int popularItemsPerPage = 4,
  }) async {
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _wishlistAndPopularGraphql,
        "variables": {
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
          "popularPageNumber": popularPageNumber,
          "popularItemsPerPage": popularItemsPerPage,
        },
      },
    );
    return response;
  }

  Future<Response> getPopularProductsGraphql({
    String? token,
    int pageNumber = 1,
    int itemsPerPage = 4,
  }) async {
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: token == null || token.trim().isEmpty
          ? null
          : {"Authorization": "Bearer $token"},
      data: {
        "query": _popularProductsGraphql,
        "variables": {
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
          "pageNumber": pageNumber,
          "itemsPerPage": itemsPerPage,
        },
      },
    );
    return response;
  }

  Future<Response> removeFromWishList({
    required String token,
    required String productId,
  }) async {
    final response = await apiConsumer.delete(
      "${EndPoints.baseUrl}/v1/wishlist/$productId",
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }
}
