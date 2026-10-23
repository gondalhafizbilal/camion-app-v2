import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:dio/dio.dart';

class CurrencyRemoteDataSource {
  final ApiConsumer apiConsumer;
  CurrencyRemoteDataSource({required this.apiConsumer});
  static const String _currenciesGraphqlQuery = r'''
    query GetCurrencies {
      getCurrencies {
        uuid
        name
        alphaCode
      }
    }
  ''';

  // GET <baseUrl>/currency/list
  Future<Response> getCurrencies({String? token}) async {
    final headers = <String, String>{};
    headers['Authorization'] = 'Bearer $token';

    final response = await apiConsumer.get(
      '${EndPoints.baseUrl}/currency/list',
      headers: headers.isEmpty ? null : headers,
    );
    return response;
  }

  Future<Response> getCurrenciesGraphql({String? token}) async {
    final headers = <String, String>{};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await apiConsumer.post(
      EndPoints.graphql,
      headers: headers.isEmpty ? null : headers,
      data: {"query": _currenciesGraphqlQuery, "variables": const {}},
    );
    return response;
  }

  // PATCH <baseUrl>/users/{userId}/currency
  Future<Response> updateUserCurrency({
    required String token,
    required String userId,
    required String currencyCode,
  }) async {
    final response = await apiConsumer.patch(
      '${EndPoints.baseUrl}/users/$userId/currency',
      headers: {
        'Authorization': 'Bearer $token',

        'Content-Type': 'application/json',
      },
      data: {'currency': currencyCode},
    );
    return response;
  }

  // POST <baseUrl>/currency/convert-products
  // Accepts: { fromCurrency: 'USD', products: [{id, name, price, regular_price}] }
  Future<Response> convertProducts({
    required String token,
    required String fromCurrency,
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await apiConsumer.post(
      '${EndPoints.baseUrl}/currency/convert-products',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      data: {'fromCurrency': fromCurrency, 'products': products},
    );
    return response;
  }
}
