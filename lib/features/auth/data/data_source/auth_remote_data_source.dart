import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/features/auth/data/models/customer_auth/customer_auth_payloads.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthRemoteDataSource {
  final ApiConsumer apiConsumer;
  AuthRemoteDataSource({required this.apiConsumer});

  void _logRequest({
    required String method,
    required String url,
    dynamic payload,
  }) {
    if (!AppConfig.instance.enableNetworkLogs) return;
    debugPrint('[AUTH][REQ] $method $url payload: $payload');
  }

  void _logResponse({
    required String method,
    required String url,
    required Response response,
  }) {
    if (!AppConfig.instance.enableNetworkLogs) return;
    debugPrint(
      '[AUTH][RES] $method $url responded: ${response.requestOptions.uri} status: ${response.statusCode}',
    );
  }

  Future<Response> registerCustomer({
    required RegisterCustomerPayload payload,
  }) async {
    final url = EndPoints.customerRegister;
    final data = payload.toJson();
    _logRequest(method: 'POST', url: url, payload: data);
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    return response;
  }

  Future<Response> loginWithEmail({
    required LoginWithEmailPayload payload,
  }) async {
    final url = EndPoints.customerLoginWithEmail;
    final data = payload.toJson();
    _logRequest(method: 'POST', url: url, payload: data);
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    return response;
  }

  Future<Response> loginWithPhone({
    required LoginWithPhonePayload payload,
  }) async {
    final url = EndPoints.customerLoginWithPhone;
    final data = payload.toJson();
    _logRequest(method: 'POST', url: url, payload: data);
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    return response;
  }

  Future<Response> loginWithGoogleOauth({
    required GoogleOauthPayload payload,
  }) async {
    final url = EndPoints.customerGoogleOauthLogin;
    final data = payload.toJson();
    _logRequest(
      method: 'POST',
      url: url,
      payload: {
        'idToken': '<redacted>',
        'idTokenLength': (payload.idToken).trim().length,
      },
    );
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    if (AppConfig.instance.enableNetworkLogs) {
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final token = (map['token'] ?? '').toString();
      final customer = map['customer'];
      final uuid = customer is Map<String, dynamic>
          ? (customer['uuid'] ?? '').toString()
          : '';
      debugPrint(
        '[AUTH][RES][GOOGLE] tokenLength=${token.trim().length} customerUuid=$uuid',
      );
    }
    return response;
  }

  Future<Response> loginWithFacebookOauth({
    required FacebookOauthPayload payload,
  }) async {
    final url = EndPoints.customerFacebookOauthLogin;
    final data = payload.toJson();
    if (AppConfig.instance.enableNetworkLogs) {
      debugPrint(
        '[AUTH][FACEBOOK][REMOTE] preparing POST $url tokenLength=${payload.accessToken.trim().length}',
      );
    }
    _logRequest(
      method: 'POST',
      url: url,
      payload: {
        'accessToken': '<redacted>',
        'accessTokenLength': (payload.accessToken).trim().length,
      },
    );
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    if (AppConfig.instance.enableNetworkLogs) {
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final token = (map['token'] ?? '').toString();
      final customer = map['customer'];
      final uuid = customer is Map<String, dynamic>
          ? (customer['uuid'] ?? '').toString()
          : '';
      final email = customer is Map<String, dynamic>
          ? (customer['emailAddress'] ?? '').toString()
          : '';
      debugPrint(
        '[AUTH][RES][FACEBOOK] tokenLength=${token.trim().length} customerUuid=$uuid emailPresent=${email.trim().isNotEmpty}',
      );
    }
    return response;
  }

  Future<Response> loginWithAppleOauth({
    required AppleOauthPayload payload,
  }) async {
    final url = EndPoints.customerAppleOauthLogin;
    final data = payload.toJson();
    _logRequest(
      method: 'POST',
      url: url,
      payload: {
        'identityToken': '<redacted>',
        'identityTokenLength': (payload.identityToken).trim().length,
        'authorizationCodePresent':
            payload.authorizationCode != null &&
            payload.authorizationCode!.trim().isNotEmpty,
        'fullNamePresent':
            payload.fullName != null && payload.fullName!.trim().isNotEmpty,
      },
    );
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    if (AppConfig.instance.enableNetworkLogs) {
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final token = (map['token'] ?? '').toString();
      final customer = map['customer'];
      final uuid = customer is Map<String, dynamic>
          ? (customer['uuid'] ?? '').toString()
          : '';
      debugPrint(
        '[AUTH][RES][APPLE] tokenLength=${token.trim().length} customerUuid=$uuid',
      );
    }
    return response;
  }

  Future<Response> verifyEmail({required VerifyCustomerPayload payload}) async {
    final url = EndPoints.customerVerifyEmail;
    final data = payload.toJson();
    _logRequest(method: 'POST', url: url, payload: data);
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    return response;
  }

  Future<Response> verifyPhone({required VerifyCustomerPayload payload}) async {
    final url = EndPoints.customerVerifyPhone;
    final data = payload.toJson();
    _logRequest(method: 'POST', url: url, payload: data);
    final response = await apiConsumer.post(url, data: data);
    _logResponse(method: 'POST', url: url, response: response);
    return response;
  }

  Future<Response> registerGuest({
    required RegisterGuestPayload payload,
  }) async {
    final url = EndPoints.guestRegister;
    final data = payload.toJson();
    final masked = Map<String, dynamic>.from(data);
    if (masked.containsKey('token')) {
      final token = masked['token']?.toString() ?? '';
      masked['token'] = token.isEmpty
          ? '<empty>'
          : '${token.substring(0, token.length > 6 ? 6 : token.length)}...(${token.length})';
    }
    _logRequest(method: 'POST', url: url, payload: masked);
    try {
      final response = await apiConsumer.post(
        url,
        data: data,
        headers: const {
          'x-suppress-error-toast': 'true',
          'x-suppress-backend-unavailable': 'true',
        },
      );
      _logResponse(method: 'POST', url: url, response: response);
      if (AppConfig.instance.enableNetworkLogs) {
        debugPrint('[AUTH][RES][GUEST] body: ${response.data}');
      }
      return response;
    } catch (e, st) {
      if (AppConfig.instance.enableNetworkLogs) {
        debugPrint('[AUTH][ERR][GUEST] POST $url failed: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<Response> logoutCustomer({required String accessToken}) async {
    return apiConsumer.post(
      EndPoints.customerLogout,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<Response> updateCustomerProfile({
    required String accessToken,
    required UpdateCustomerProfilePayload payload,
  }) async {
    return apiConsumer.put(
      EndPoints.customerSelf,
      data: payload.toJson(),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<Response> updateCustomerEmailAddress({
    required String accessToken,
    required UpdateCustomerEmailPayload payload,
  }) async {
    return apiConsumer.put(
      EndPoints.customerSelfEmail,
      data: payload.toJson(),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<Response> sendUserShippingAddress({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String postcode,
    required String country,
    required String shippingFirstName,
    required String shippingLastName,
    required String shippingEmail,
    required String shippingPhone,
    required String shippingAddress1,
    required String shippingAddress2,
    required String shippingCity,
    required String shippingState,
    required String shippingPostcode,
    required String shippingCountry,
  }) async {
    final resolvedPostcode = postcode.trim().isEmpty ? '0000' : postcode.trim();
    final resolvedShippingPostcode = shippingPostcode.trim().isEmpty
        ? '0000'
        : shippingPostcode.trim();
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/users/address/update",
      data: {
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "phone": phone,
        "address_1": address1,
        "address_2": address2,
        "city": city,
        "state": state,
        "postcode": resolvedPostcode,
        "country": country,
        "shipping_address": {
          "first_name": shippingFirstName,
          "last_name": shippingLastName,
          "email": shippingEmail,
          "phone": shippingPhone,
          "address_1": shippingAddress1,
          "address_2": shippingAddress2,
          "city": shippingCity,
          "state": shippingState,
          "postcode": resolvedShippingPostcode,
          "country": shippingCountry,
        },

        "shipping_option": {
          "method_id": "flat_rate",
          "title": "Shipping",
          "cost": "100",
        },
      },
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }
}
