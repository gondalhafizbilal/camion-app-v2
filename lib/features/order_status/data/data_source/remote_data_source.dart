import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';

import 'package:dio/dio.dart';

class OrderStatusRemoteDataSource {
  final ApiConsumer apiConsumer;
  OrderStatusRemoteDataSource({required this.apiConsumer});
  static const String _suppressBackendUnavailableHeader =
      'x-suppress-backend-unavailable';

  static const String _currentCustomerOrdersGraphql = r'''
    query GetCurrentCustomerOrders($status: String, $pageNumber: Int, $itemsPerPage: Int, $currency: String, $language: String) {
      getCurrentCustomerOrders(status: $status, pageNumber: $pageNumber, itemsPerPage: $itemsPerPage) {
        uuid
        status
        tracking {
          stage
          status
          waybillNo
        }
        subTotal {
          amount
          minorAmount
          currencyCode
        }
        shippingCost {
          amount
          minorAmount
          currencyCode
        }
        discount {
          amount
          minorAmount
          currencyCode
        }
        total {
          amount
          minorAmount
          currencyCode
        }
        eta
        orderPlacementDate
        shippingAddress {
          uuid
          fullName
          country
          city
          state
          apartment
          streetAddress
          zipCode
          phoneNumber
        }
        orderItems {
          uuid
          price {
            amount
            minorAmount
            currencyCode
          }
          discountedPrice {
            amount
            minorAmount
            currencyCode
          }
          quantity
          total {
            amount
            currencyCode
          }
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
    }
  ''';

  static const String _currentCustomerOrderGraphql = r'''
    query GetCurrentCustomerOrder($uuid: String!, $currency: String, $language: String) {
      getCurrentCustomerOrder(uuid: $uuid) {
        uuid
        status
        tracking {
          stage
          status
          waybillNo
        }
        subTotal {
          amount
          minorAmount
          currencyCode
        }
        shippingCost {
          amount
          minorAmount
          currencyCode
        }
        discount {
          amount
          minorAmount
          currencyCode
        }
        total {
          amount
          minorAmount
          currencyCode
        }
        eta
        orderPlacementDate
        shippingAddress {
          uuid
          fullName
          country
          city
          state
          apartment
          streetAddress
          zipCode
          phoneNumber
        }
        orderItems {
          uuid
          price {
            amount
            minorAmount
            currencyCode
          }
          discountedPrice {
            amount
            minorAmount
            currencyCode
          }
          quantity
          total {
            amount
            currencyCode
          }
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
          }
          variant {
            uuid
            title(language: $language)
            optionValues {
              optionValue {
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
    }
  ''';

  static const String _orderTrackingGraphql = r'''
    query GetOrderTracking($uuid: String!, $language: String) {
      getOrderTracking(uuid: $uuid, language: $language) {
        id
        name
        checked
        date
        metadata {
          trackingId
          cancellationReason
          reviewText
          reviewRating
        }
      }
    }
  ''';

  static const String _currentCustomerOrderPreviewGraphql = r'''
    query GetCurrentCustomerOrderPreview($language: String, $currency: String, $couponCode: String) {
      getCurrentCustomerOrderPreview(language: $language, currency: $currency, couponCode: $couponCode) {
        items {
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
          }
          variant {
            uuid
            title(language: $language)
            optionValues {
              optionValue {
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
        shippingAddress {
          uuid
          fullName
          phoneNumber
          streetAddress
          apartment
          zipCode
          city
          state
          country
          isDefault
        }
        cart_total
        discount
        shippingTotal
        grand_total
        eta
      }
    }
  ''';

  static const String _currentCustomerOrderPreviewV2Graphql = r'''
    query GetCurrentCustomerOrderPreviewV2($language: String, $currency: String, $couponCode: String, $cartItemUuids: [String!]) {
      getCurrentCustomerOrderPreviewV2(language: $language, currency: $currency, couponCode: $couponCode, cartItemUuids: $cartItemUuids) {
        items {
          uuid
          product {
            uuid
            slug
            title(language: $language)
            brief(language: $language)
            description(language: $language)
            descriptionHtml(language: $language)
            featuredImageUrl
            featuredThumbnailUrl
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
          }
          variant {
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
            images {
              uuid
              imageUrl
              thumbnailUrl
              alt
              isFeatured
              position
            }
            optionValues {
              optionValue {
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
          quantity
          subTotal {
            amount
            minorAmount
            currencyCode
          }
          discountPrice {
            amount
            minorAmount
            currencyCode
          }
          total {
            amount
            minorAmount
            currencyCode
          }
        }
        shippingAddress {
          uuid
          fullName
          phoneNumber
          streetAddress
          apartment
          zipCode
          city
          state
          country
          isDefault
        }
        cart_total
        discount
        shippingTotal
        grand_total
        eta
        orderTotalWarning
      }
    }
  ''';

  static const String _currentCustomerReturnRequestsGraphql = r'''
    query GetCurrentCustomerReturnRequests($currency: String, $language: String) {
      getCurrentCustomerReturnRequests {
        uuid
        order {
          uuid
          status
          subTotal {
            amount
            minorAmount
            currencyCode
          }
          shippingCost {
            amount
            minorAmount
            currencyCode
          }
          discount {
            amount
            minorAmount
            currencyCode
          }
          total {
            amount
            minorAmount
            currencyCode
          }
        }
        orderItem {
          uuid
          price {
            amount
            minorAmount
            currencyCode
          }
          discountedPrice {
            amount
            minorAmount
            currencyCode
          }
          quantity
          total {
            amount
            currencyCode
          }
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
            productCategories {
              category {
                uuid
                slug
                name
                nameEn
                nameAr
                thumbnailUrl
              }
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
        reason
        reasonDetail
        status
        adminNote
        refundAmount {
          amount
          minorAmount
          currencyCode
        }
        evidence {
          uuid
          url
          mimeType
        }
      }
    }
  ''';

  static const String _currentCustomerReturnRequestGraphql = r'''
    query GetCurrentCustomerReturnRequest($uuid: String!, $currency: String, $language: String) {
      getCurrentCustomerReturnRequest(uuid: $uuid) {
        uuid
        order {
          uuid
          status
          subTotal {
            amount
            minorAmount
            currencyCode
          }
          shippingCost {
            amount
            minorAmount
            currencyCode
          }
          discount {
            amount
            minorAmount
            currencyCode
          }
          total {
            amount
            minorAmount
            currencyCode
          }
        }
        orderItem {
          uuid
          price {
            amount
            minorAmount
            currencyCode
          }
          discountedPrice {
            amount
            minorAmount
            currencyCode
          }
          quantity
          total {
            amount
            currencyCode
          }
          product {
            uuid
            slug
            title(language: $language)
            brief(language: $language)
            description(language: $language)
            descriptionHtml(language: $language)
            status
            productCategories {
              category {
                uuid
                slug
                name
                nameEn
                nameAr
                thumbnailUrl
              }
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
        reason
        reasonDetail
        status
        adminNote
        refundAmount {
          amount
          minorAmount
          currencyCode
        }
        evidence {
          uuid
          url
          mimeType
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

  String? _normalizedOrderStatus(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  // Future<Response> calculateShippingAddress({
  //   required List<GetCartModel> items,
  //   required String firstName,
  //   required String lastName,
  //   required String address1,
  //   required String city,
  //   required String postcode,
  //   required String country,
  // }) async {
  //   List<Map<String, dynamic>> itemsData = items
  //       .map(
  //         (item) => {
  //           'id': item.id,
  //           'quantity': item.quantity,
  //           'variation': item.variation,
  //         },
  //       )
  //       .toList();
  //   final response = await apiConsumer.post(
  //     "${EndPoints.baseUrl}/shipping/calculate",
  //     data: {
  //       "items": itemsData,
  //       "shippingAddress": {
  //         "first_name": firstName,
  //         "last_name": lastName,
  //         "address_1": address1,
  //         "city": city,
  //         "postcode": postcode,
  //         "country": country,
  //       },
  //     },
  //   );
  //   return response;
  // }

  Future<Response> createOrder({
    required String token,
    required List<String> cartItemUuids,
    required String paymentMethod,
    required String currency,
    String? couponCode,
  }) async {
    final normalizedCouponCode = couponCode?.trim();
    final payload = <String, dynamic>{
      "cartItemUuids": cartItemUuids,
      "paymentMethod": paymentMethod,
      "currency": currency.trim().toLowerCase(),
      if (normalizedCouponCode != null && normalizedCouponCode.isNotEmpty)
        "couponCode": normalizedCouponCode,
    };
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/v1/orders",
      data: payload,
      headers: {
        "Authorization": "Bearer $token",
        _suppressBackendUnavailableHeader: 'true',
      },
    );

    return response;
  }

  Future<Response> retryPayment({
    required String token,
    required String orderUuid,
  }) async {
    return apiConsumer.post(
      EndPoints.retryOrderPayment(orderUuid.trim()),
      headers: {
        "Authorization": "Bearer $token",
        _suppressBackendUnavailableHeader: 'true',
      },
    );
  }

  Future<Response> getOrderPreview({
    required String token,
    String? couponCode,
    List<String>? cartItemUuids,
  }) async {
    final normalizedCouponCode = couponCode?.trim();
    final normalizedCartItemUuids = cartItemUuids
        ?.map((uuid) => uuid.trim())
        .where((uuid) => uuid.isNotEmpty)
        .toList();
    final useV2 = normalizedCartItemUuids?.isNotEmpty == true;
    return apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": useV2
            ? _currentCustomerOrderPreviewV2Graphql
            : _currentCustomerOrderPreviewGraphql,
        "variables": {
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
          "couponCode": normalizedCouponCode,
          if (useV2) "cartItemUuids": normalizedCartItemUuids,
        },
      },
    );
  }

  Future<Response> getOrders({
    required String token,
    required String userId,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _currentCustomerOrdersGraphql,
        "variables": {
          "status": null,
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
          "pageNumber": pageNumber,
          "itemsPerPage": itemsPerPage,
        },
      },
    );
    return response;
  }

  Future<Response> getOrderStatus({
    required String token,
    required String status,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    final normalizedStatus = _normalizedOrderStatus(status);
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _currentCustomerOrdersGraphql,
        "variables": {
          "status": normalizedStatus,
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
          "pageNumber": pageNumber,
          "itemsPerPage": itemsPerPage,
        },
      },
    );
    return response;
  }

  Future<Response> getCurrentCustomerOrder({
    required String token,
    required String uuid,
  }) async {
    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _currentCustomerOrderGraphql,
        "variables": {
          "uuid": uuid,
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
        },
      },
    );
    return response;
  }

  Future<Response> getOrderTracking({
    required String token,
    required String uuid,
  }) async {
    return apiConsumer.post(
      EndPoints.graphql,
      headers: {
        "Authorization": "Bearer $token",
        _suppressBackendUnavailableHeader: 'true',
      },
      data: {
        "query": _orderTrackingGraphql,
        "variables": {
          "uuid": uuid,
          "language": _selectedLanguageCode().toLowerCase() == 'ar'
              ? 'ar'
              : 'en',
        },
      },
    );
  }

  Future<Response> getCurrentCustomerReturnRequests({
    required String token,
  }) async {
    return apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _currentCustomerReturnRequestsGraphql,
        "variables": {
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
        },
      },
    );
  }

  Future<Response> getCurrentCustomerReturnRequest({
    required String token,
    required String uuid,
  }) async {
    return apiConsumer.post(
      EndPoints.graphql,
      headers: {"Authorization": "Bearer $token"},
      data: {
        "query": _currentCustomerReturnRequestGraphql,
        "variables": {
          "uuid": uuid,
          "language": _selectedLanguageCode(),
          "currency": _selectedCurrencyCode(),
        },
      },
    );
  }

  Future<Response> deleteOrder({
    required String token,
    required String uuid,
  }) async {
    return apiConsumer.delete(
      EndPoints.orderByUuid(uuid),
      headers: {
        "Authorization": "Bearer $token",
        _suppressBackendUnavailableHeader: 'true',
      },
    );
  }

  Future<Response> createReturnRequest({
    required String token,
    required String orderUuid,
    String? orderItemUuid,
    required String reason,
    required String reasonDetail,
  }) async {
    final payload = <String, dynamic>{
      "orderUuid": orderUuid,
      "reason": reason,
      "reasonDetail": reasonDetail,
      if (orderItemUuid != null && orderItemUuid.trim().isNotEmpty)
        "orderItemUuid": orderItemUuid.trim(),
    };
    return apiConsumer.post(
      EndPoints.returnRequests,
      data: payload,
      headers: {
        "Authorization": "Bearer $token",
        _suppressBackendUnavailableHeader: 'true',
      },
    );
  }

  Future<Response> uploadReturnRequestEvidence({
    required String token,
    required String requestUuid,
    required FormData formData,
  }) async {
    return apiConsumer.post(
      "${EndPoints.returnRequests}/$requestUuid/evidence",
      data: formData,
      headers: {
        "Authorization": "Bearer $token",
        _suppressBackendUnavailableHeader: 'true',
      },
    );
  }
}
