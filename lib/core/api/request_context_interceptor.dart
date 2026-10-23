import 'dart:convert';

import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class RequestContextInterceptor extends Interceptor {
  static const String _skipAuthHeaderForRetryKey = 'skipAuthHeaderForRetry';
  static const Set<String> _currencyBodyPaths = {
    '/cart/add',
    '/cart/get-with-shipping',
    '/checkout/complete',
    '/v1/cart-items',
    '/v1/wishlist',
  };
  static const Set<String> _protectedRestPathMarkers = {
    '/v1/auth/customer/self',
    '/v1/auth/customer/self/email-address',
    '/v1/customer-addresses',
    '/v1/customers/me',
    '/v1/return-requests',
    '/v1/orders',
    '/users/address/me',
    '/users/address/update',
    '/v1/referral/affiliates',
    '/v1/referral/coupons',
  };

  static const Set<String> _protectedGraphqlOperations = {
    'getcurrentcustomer',
    'getcurrentaffiliate',
    'getcurrentaffiliatecoupons',
    'getcurrentaffiliatewallettransactions',
    'getcurrentcustomerorders',
    'getcurrentcustomerorder',
    'getcurrentcustomerreturnrequests',
    'getcurrentcustomerreturnrequest',
    'createorder',
    'createreturnrequest',
    'cancelreturnrequest',
    'uploadreturnrequestevidence',
    'getcustomerwishlist',
  };

  DateTime? _lastGuardRedirectAt;
  bool _isGuardRedirecting = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final isGraphqlRequest = _isGraphqlRequest(options);
      final guestId = await _guestId();
      options.headers.putIfAbsent('x-guest-id', () => guestId);

      if (_shouldAttachAuthorization(options)) {
        final token = await _sessionToken();
        if (token != null && token.isNotEmpty) {
          options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
        } else {
          if (_requiresAuthenticatedSession(options)) {
            await _redirectToLoginForMissingToken();
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 401,
                  data: <String, dynamic>{
                    'message': 'Unauthorized request. Please login and try again.',
                  },
                ),
                message: 'Missing access token for protected endpoint.',
              ),
            );
            return;
          }
          debugPrint(
            '[REQ][AUTH] Authorization header skipped method=${options.method} path=${options.path} hasPendingOtp=${await _hasPendingOtpSession()}',
          );
        }
      }

      final cache = sl<CacheHelper>();
      final lang = _cachedOrDefault(
        cache.getDataString(key: 'languageCode'),
        AppDefaults.defaultLanguageCode,
      );
      final currencyCode = _cachedOrDefault(
        cache.getDataString(key: 'currencyCode')?.toLowerCase(),
        AppDefaults.defaultCurrencyCode.toLowerCase(),
      );

      if (_shouldInjectLocaleAndCurrency(options, isGraphqlRequest)) {
        final query = Map<String, dynamic>.from(options.queryParameters);
        final requestLanguage = lang;
        final normalizedRequestCurrency = currencyCode.toLowerCase();
        query
          ..remove('currencyCode')
          ..['language'] = requestLanguage
          ..['lang'] = requestLanguage
          ..['currency'] = normalizedRequestCurrency;
        options.queryParameters = query;

        if (_requiresCurrencyBody(options)) {
          final body = _normalizeBody(options.data);
          final normalizedPayloadCurrency = currencyCode.toLowerCase();
          body
            ..remove('currencyCode')
            ..['currency'] = normalizedPayloadCurrency;
          options.data = body;
        }
      }

      if (isGraphqlRequest) {
        final body = _normalizeBody(options.data);
        final variables = _normalizeVariables(body['variables']);
        final requestLanguage = lang;
        final existingLanguage = variables['language']?.toString().trim() ?? '';
        final existingLang = variables['lang']?.toString().trim() ?? '';
        if (existingLanguage.isEmpty) {
          variables['language'] = requestLanguage;
        }
        if (existingLang.isEmpty) {
          variables['lang'] = requestLanguage;
        }
        if (_queryExpectsCurrency(body['query']?.toString() ?? '')) {
          final normalizedRequestCurrency = currencyCode.toLowerCase();
          variables.remove('currencyCode');
          final existingCurrency =
              variables['currency']?.toString().trim().toLowerCase() ?? '';
          if (existingCurrency.isEmpty) {
            variables['currency'] = normalizedRequestCurrency;
          }
        }
        body['variables'] = variables;
        options.data = body;
      }
    } catch (_) {}

    handler.next(options);
  }

  Future<String> _guestId() async {
    String? guestId = await sl<SecureCacheHelper>().getData(key: 'guestId');
    if (guestId == null || guestId.isEmpty) {
      guestId = const Uuid().v4();
      await sl<SecureCacheHelper>().saveData(key: 'guestId', value: guestId);
    }
    return guestId;
  }

  Future<String?> _sessionToken() async {
    final pendingAuthSession =
        (await sl<SecureCacheHelper>().getData(
          key: 'authSessionToken',
        ))?.trim() ??
        '';
    if (pendingAuthSession.isNotEmpty) {
      // OTP verification in progress; avoid sending a stale guest/customer
      // access token on non-auth APIs during session transition.
      return null;
    }

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<bool> _hasPendingOtpSession() async {
    final pendingAuthSession =
        (await sl<SecureCacheHelper>().getData(
          key: 'authSessionToken',
        ))?.trim() ??
        '';
    return pendingAuthSession.isNotEmpty;
  }

  String _cachedOrDefault(String? value, String fallback) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
  }

  bool _isCommerceApi(String path) {
    final parsed = Uri.tryParse(path);
    if (parsed == null) return false;

    // Relative API paths should still receive context parameters.
    if (!parsed.hasScheme || parsed.host.isEmpty) {
      return true;
    }

    final host = parsed.host;
    final baseHost = Uri.tryParse(AppConfig.instance.baseUrl)?.host;
    return baseHost != null && host.contains(baseHost);
  }

  bool _isGraphqlRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (method != 'POST') return false;
    return options.path.toLowerCase().contains('/graphql');
  }

  bool _shouldAttachAuthorization(RequestOptions options) {
    if (options.extra[_skipAuthHeaderForRetryKey] == true) return false;
    if (!_isCommerceApi(options.path)) return false;
    final path = options.path.toLowerCase();
    if (_isAuthEndpoint(path)) return false;
    return true;
  }

  bool _shouldInjectLocaleAndCurrency(
    RequestOptions options,
    bool isGraphqlRequest,
  ) {
    if (!_isCommerceApi(options.path)) return false;
    if (isGraphqlRequest) return false;
    if (_isAuthEndpoint(options.path.toLowerCase())) return false;
    return true;
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/v1/auth/');
  }

  bool _requiresAuthenticatedSession(RequestOptions options) {
    final lowerPath = options.path.toLowerCase();

    for (final marker in _protectedRestPathMarkers) {
      if (lowerPath.contains(marker)) {
        return true;
      }
    }

    if (_isGraphqlRequest(options)) {
      final body = _normalizeBody(options.data);
      final query = (body['query'] ?? '').toString();
      final loweredQuery = query.toLowerCase();
      for (final operation in _protectedGraphqlOperations) {
        if (loweredQuery.contains(operation)) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _redirectToLoginForMissingToken() async {
    if (_isGuardRedirecting) return;
    final now = DateTime.now();
    if (_lastGuardRedirectAt != null &&
        now.difference(_lastGuardRedirectAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastGuardRedirectAt = now;
    _isGuardRedirecting = true;

    final location =
        '${AppRouter.login}?unauthorized=1&ts=${DateTime.now().millisecondsSinceEpoch}';
    Future<void>.microtask(() {
      try {
        RouterGenerator.mainRouting.go(location);
      } catch (_) {}
      _isGuardRedirecting = false;
    });
  }

  bool _queryExpectsCurrency(String query) {
    if (query.trim().isEmpty) return false;
    return RegExp(r'\$currency\b').hasMatch(query);
  }

  bool _requiresCurrencyBody(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (!(method == 'POST' || method == 'PUT' || method == 'PATCH')) {
      return false;
    }
    return _currencyBodyPaths.any(options.path.contains);
  }

  Map<String, dynamic> _normalizeBody(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeVariables(dynamic variables) {
    if (variables is Map) {
      return Map<String, dynamic>.from(variables);
    }
    return <String, dynamic>{};
  }
}
