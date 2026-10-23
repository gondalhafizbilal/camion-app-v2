// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/api/graphql_error_parser.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HomeRemoteDataSource {
  final ApiConsumer apiConsumer;
  HomeRemoteDataSource({required this.apiConsumer});

  void _logRequest({
    required String method,
    required String url,
    dynamic payload,
  }) {
    if (!AppConfig.instance.enableNetworkLogs) return;
    debugPrint('[HOME][REQ] $method $url payload: $payload');
  }

  void _logResponse({
    required String method,
    required String url,
    required Response response,
  }) {
    if (!AppConfig.instance.enableNetworkLogs) return;
    debugPrint(
      '[HOME][RES] $method $url responded: ${response.requestOptions.uri} status: ${response.statusCode}',
    );
  }

  String _buildRandomSeed() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_'
        '${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';
  }

  String _selectedCurrencyCode() {
    final code = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (code == null || code.trim().isEmpty) {
      return AppDefaults.defaultCurrencyCode.toLowerCase();
    }
    return code.trim().toLowerCase();
  }

  String _selectedLanguageCode() {
    final lang = sl<CacheHelper>().getDataString(key: 'languageCode');
    if (lang == null || lang.trim().isEmpty) {
      return AppDefaults.defaultLanguageCode;
    }
    return lang.trim();
  }

  Future<Response> postGraphql({
    String? token,
    required String query,
    required Map<String, dynamic> variables,
    bool allowGraphqlPartialData = false,
    bool suppressBackendUnavailableBanner = false,
  }) async {
    final url = EndPoints.graphql;
    final data = {'query': query, 'variables': variables};
    _logRequest(method: 'POST', url: url, payload: data);
    final response = await apiConsumer.post(
      url,
      data: data,
      headers: {
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer $token',
        if (allowGraphqlPartialData) 'x-allow-graphql-partial-data': 'true',
        if (suppressBackendUnavailableBanner)
          'x-suppress-backend-unavailable': 'true',
      },
    );
    GraphqlErrorParser.throwIfAny(response);
    _logResponse(method: 'POST', url: url, response: response);
    return response;
  }

  Future<Response> getProducts({
    required int page,
    required int perPage,
    required String lang,
    String? search,
    String? sort,
    num? minPrice,
    num? maxPrice,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/${EndPoints.products}",
      headers: {},

      queryParameters: {
        "page": page,
        "per_page": perPage,
        "lang": lang,
        "currency": _selectedCurrencyCode(),
        "random_seed": _buildRandomSeed(),
        if (search != null && search.isNotEmpty) "search": search,
        if (sort != null && sort.trim().isNotEmpty) "sort": sort.trim(),
        if (minPrice != null) "min_price": minPrice,
        if (maxPrice != null) "max_price": maxPrice,
      },
    );

    return response;
  }

  Future<Response> searchProducts({
    required String query,
    String? sort,
    num? minPrice,
    num? maxPrice,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/${EndPoints.products}",
      queryParameters: {
        "search": query,
        "lang": _selectedLanguageCode(),
        "currency": _selectedCurrencyCode(),
        "random_seed": _buildRandomSeed(),
        if (sort != null && sort.trim().isNotEmpty) "sort": sort.trim(),
        if (minPrice != null) "min_price": minPrice,
        if (maxPrice != null) "max_price": maxPrice,
      },
      headers: {},
    );

    return response;
  }

  Future<Response> getProductById({
    required String id,
    String? token,
    required String lang,
  }) async {
    final headers = {"Authorization": "Bearer $token"};
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/${EndPoints.products}/$id",
      headers: headers,
      queryParameters: {"lang": lang, "currency": _selectedCurrencyCode()},
    );

    return response;
  }

  Future<Response> getStories({required String token}) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/${EndPoints.stories}/active",
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  Future<Response> getStoryById({
    required String id,
    required String token,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/${EndPoints.stories}/$id",
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  Future<Response> getCategories({required String lang}) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/categories",
      queryParameters: {"lang": lang},
      headers: {},
    );

    return response;
  }

  Future<Response> getSubCategories({
    required int id,
    required String lang,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/categories/$id",
      queryParameters: {"lang": lang},
      headers: {},
    );
    return response;
  }

  Future<Response> getProductsByCategory({
    required String slug,
    required int page,
    required int perPage,
    required String lang,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/${EndPoints.products}",
      queryParameters: {
        "category": slug,
        "page": page,
        "per_page": perPage,
        "lang": lang,
        "currency": _selectedCurrencyCode(),
        "random_seed": _buildRandomSeed(),
      },
      headers: {},
    );
    return response;
  }

  Future<Response> getProductsOnSale({
    required int page,
    required int perPage,
    required String lang,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/products",

      queryParameters: {
        "on_sale": true,
        "page": page,
        "per_page": perPage,
        "lang": lang,
        "currency": _selectedCurrencyCode(),
        "random_seed": _buildRandomSeed(),
      },
      headers: {},
    );
    return response;
  }

  Future<Response> getSliders() async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/sliders",
      headers: {},
    );
    return response;
  }

  Future<Response> sendFcmToken({
    required String fcmToken,
    required String token,
  }) async {
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/users/notifications/token",
      data: {"token": fcmToken},
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  // Future<Response> canReview({
  //   required String token,
  //   required String productId,
  // }) async {
  //   final response = await apiConsumer.get(
  //     "${EndPoints.baseUrl}/api/reviews/can-review/$productId",
  //     headers: {"Authorization": "Bearer $token"},
  //   );
  //   return response;
  // }

  Future<Response> createReview({
    required String token,
    required String productId,
    required FormData formData,
  }) async {
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/v2/products/$productId/reviews",
      data: formData,
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  Future<Response> getReviews({
    required String token,
    required String productId,
  }) async {
    final response = await apiConsumer.get(
      "${EndPoints.baseUrl}/v1/products/$productId/reviews",
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  Future<Response> createReviewImage({
    required String token,
    required String productId,
    required String reviewId,
    required FormData formData,
  }) async {
    return apiConsumer.post(
      "${EndPoints.baseUrl}/v1/products/$productId/reviews/$reviewId/images",
      data: formData,
      headers: {"Authorization": "Bearer $token"},
    );
  }

  Future<Response> deleteReviewImage({
    required String token,
    required String productId,
    required String reviewId,
    required String imageId,
  }) async {
    return apiConsumer.delete(
      "${EndPoints.baseUrl}/v1/products/$productId/reviews/$reviewId/images/$imageId",
      headers: {"Authorization": "Bearer $token"},
    );
  }

  Future<Response> getReviewById({
    required String token,
    required String productId,
    required String reviewId,
  }) async {
    return apiConsumer.get(
      "${EndPoints.baseUrl}/v1/products/$productId/reviews/$reviewId",
      headers: {"Authorization": "Bearer $token"},
    );
  }

  Future<Response> updateReview({
    required String token,
    required String productId,
    required String reviewId,
    required String comment,
    required double rating,
  }) async {
    return apiConsumer.put(
      "${EndPoints.baseUrl}/v1/products/$productId/reviews/$reviewId",
      data: {"comment": comment, "rating": rating},
      headers: {"Authorization": "Bearer $token"},
    );
  }

  Future<Response> deleteReview({
    required String token,
    required String productId,
    required String reviewId,
  }) async {
    return apiConsumer.delete(
      "${EndPoints.baseUrl}/v1/products/$productId/reviews/$reviewId",
      headers: {"Authorization": "Bearer $token"},
    );
  }
}
