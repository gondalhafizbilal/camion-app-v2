import 'dart:convert';

import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UnauthorizedRecoveryInterceptor extends Interceptor {
  UnauthorizedRecoveryInterceptor(this._dio);

  final Dio _dio;

  static const String _retryAttemptedKey = 'unauthorizedRetryAttempted';
  static const String _skipRecoveryKey = 'skipUnauthorizedRecovery';
  static const String _skipAuthHeaderForRetryKey = 'skipAuthHeaderForRetry';

  DateTime? _lastLoginRedirectAt;
  bool _isRedirectingToLogin = false;

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final request = response.requestOptions;
    if (request.extra[_skipRecoveryKey] == true ||
        request.extra[_retryAttemptedKey] == true) {
      handler.next(response);
      return;
    }
    final statusCode = response.statusCode ?? 0;
    final hasAuthStatus = statusCode == 401 || statusCode == 403;
    final normalizedPayload = _normalizePayload(response.data);
    final hasGraphqlUnauthorized =
        normalizedPayload != null &&
        _isGraphqlUnauthorizedPayload(normalizedPayload);
    final hasUnauthorizedSignal = _containsUnauthorizedSignal(response.data);
    if (!hasAuthStatus && !hasGraphqlUnauthorized && !hasUnauthorizedSignal) {
      handler.next(response);
      return;
    }

    request.extra[_retryAttemptedKey] = true;
    final recovered = await _recoverByRetryingWithoutAuth(request);
    if (recovered != null) {
      handler.resolve(recovered);
      return;
    }
    await _recoverAndRedirectToLogin();
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldHandle(err)) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    requestOptions.extra[_retryAttemptedKey] = true;
    final recovered = await _recoverByRetryingWithoutAuth(requestOptions);
    if (recovered != null) {
      handler.resolve(recovered);
      return;
    }
    await _recoverAndRedirectToLogin();
    handler.next(err);
  }

  Future<Response<dynamic>?> _recoverByRetryingWithoutAuth(
    RequestOptions request,
  ) async {
    final hadAuthorization =
        request.headers['Authorization']?.toString().trim().isNotEmpty == true;
    if (!hadAuthorization) return null;

    if (await _isCustomerSession() && _isProtectedRequest(request)) {
      return null;
    }

    await _clearSessionForUnauthorizedRetry();

    final retryHeaders = Map<String, dynamic>.from(request.headers)
      ..remove('Authorization');
    final retryExtra = Map<String, dynamic>.from(request.extra)
      ..[_skipRecoveryKey] = true
      ..[_retryAttemptedKey] = true
      ..[_skipAuthHeaderForRetryKey] = true;

    final retryOptions = Options(
      method: request.method,
      headers: retryHeaders,
      responseType: request.responseType,
      contentType: request.contentType,
      sendTimeout: request.sendTimeout,
      receiveTimeout: request.receiveTimeout,
      extra: retryExtra,
      followRedirects: request.followRedirects,
      validateStatus: request.validateStatus,
      receiveDataWhenStatusError: request.receiveDataWhenStatusError,
      listFormat: request.listFormat,
    );

    try {
      return await _dio.request<dynamic>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: retryOptions,
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
        onSendProgress: request.onSendProgress,
      );
    } catch (_) {
      return null;
    }
  }

  bool _shouldHandle(DioException err) {
    final request = err.requestOptions;
    if (request.extra[_skipRecoveryKey] == true) return false;
    if (request.extra[_retryAttemptedKey] == true) return false;

    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) return true;

    final payload = err.response?.data;
    final normalizedPayload = _normalizePayload(payload);
    if (normalizedPayload != null) {
      if (_isGraphqlUnauthorizedPayload(normalizedPayload) ||
          _containsUnauthorizedSignal(normalizedPayload)) {
        return true;
      }
    }

    if (_containsUnauthorizedSignal(err.error)) {
      return true;
    }

    return false;
  }

  Future<void> _recoverAndRedirectToLogin() async {
    await _redirectToLogin();
  }

  bool _isProtectedRequest(RequestOptions request) {
    final lowerPath = request.path.toLowerCase();

    const protectedRestPathMarkers = <String>{
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
    for (final marker in protectedRestPathMarkers) {
      if (lowerPath.contains(marker)) return true;
    }

    if (!lowerPath.contains('/graphql')) return false;

    final body = _normalizeRequestBody(request.data);
    final query = (body['query'] ?? '').toString().toLowerCase();
    const protectedGraphqlOperations = <String>{
      'getcurrentcustomer',
      'getcurrentaffiliate',
      'getcurrentaffiliatecoupons',
      'getcurrentaffiliatewallettransactions',
      'getcurrentcustomerorders',
      'getcurrentcustomerorder',
      'getcurrentcustomerreturnrequests',
      'getcurrentcustomerreturnrequest',
      'getcustomercart',
      'getcustomercartcount',
      'getcustomerwishlist',
      'getcustomerwishlistcount',
      'createorder',
      'createreturnrequest',
      'cancelreturnrequest',
      'uploadreturnrequestevidence',
    };
    for (final operation in protectedGraphqlOperations) {
      if (query.contains(operation)) return true;
    }

    return false;
  }

  bool _containsUnauthorizedSignal(dynamic payload, {int depth = 0}) {
    if (payload == null || depth > 6) return false;

    if (payload is String) {
      final text = payload.trim();
      if (_containsUnauthorizedText(text)) return true;
      if ((text.startsWith('{') && text.endsWith('}')) ||
          (text.startsWith('[') && text.endsWith(']'))) {
        try {
          return _containsUnauthorizedSignal(
            jsonDecode(text),
            depth: depth + 1,
          );
        } catch (_) {}
      }
      return false;
    }

    if (payload is Map) {
      for (final entry in payload.entries) {
        if (_containsUnauthorizedSignal(
          entry.key.toString(),
          depth: depth + 1,
        )) {
          return true;
        }
        if (_containsUnauthorizedSignal(entry.value, depth: depth + 1)) {
          return true;
        }
      }
      return false;
    }

    if (payload is Iterable) {
      for (final item in payload) {
        if (_containsUnauthorizedSignal(item, depth: depth + 1)) {
          return true;
        }
      }
      return false;
    }

    return _containsUnauthorizedText(payload.toString());
  }

  bool _containsUnauthorizedText(String text) {
    final lower = text.toLowerCase();
    return lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('access denied') ||
        lower.contains('not authorized') ||
        lower.contains('unauthenticated') ||
        lower.contains('authentication failed') ||
        lower.contains('token expired') ||
        lower.contains('invalid token') ||
        lower.contains('jwt');
  }

  Map<String, dynamic>? _normalizePayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map(
        (key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  Map<String, dynamic> _normalizeRequestBody(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map(
        (key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    if (payload is String && payload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          return decoded.map(
            (key, dynamic value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  bool _isGraphqlUnauthorizedPayload(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is! List || errors.isEmpty) return false;

    for (final entry in errors) {
      if (entry is! Map) continue;
      final error = entry.map(
        (key, dynamic value) => MapEntry(key.toString(), value),
      );

      final code = error['extensions'] is Map
          ? (error['extensions'] as Map)['code']?.toString().toUpperCase()
          : null;
      if (code == 'UNAUTHENTICATED' || code == 'FORBIDDEN') return true;

      final originalStatus = error['extensions'] is Map
          ? (((error['extensions'] as Map)['originalError']
                as Map?)?['statusCode'])
          : null;
      if (originalStatus == 401 ||
          originalStatus?.toString() == '401' ||
          originalStatus == 403 ||
          originalStatus?.toString() == '403') {
        return true;
      }

      final message = error['message']?.toString().toLowerCase() ?? '';
      if (message.contains('unauthorized') ||
          message.contains('unauthenticated') ||
          message.contains('forbidden') ||
          message.contains('access denied') ||
          message.contains('not authorized')) {
        return true;
      }
    }

    return false;
  }

  Future<void> _redirectToLogin() async {
    if (_isRedirectingToLogin) return;
    final now = DateTime.now();
    if (_lastLoginRedirectAt != null &&
        now.difference(_lastLoginRedirectAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastLoginRedirectAt = now;
    _isRedirectingToLogin = true;

    await _clearAuthSessionOnly();
    debugPrint('[AUTH][401] Unauthorized detected. Redirecting to login.');

    final location =
        '${AppRouter.login}?expired=1&ts=${DateTime.now().millisecondsSinceEpoch}';
    Future<void>.microtask(() {
      try {
        RouterGenerator.mainRouting.go(location);
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          try {
            RouterGenerator.mainRouting.replace(location);
          } catch (_) {}
        });
      } catch (_) {}
      _isRedirectingToLogin = false;
    });
  }

  Future<void> _clearAuthSessionOnly() async {
    if (!sl.isRegistered<SecureCacheHelper>()) return;
    final secure = sl<SecureCacheHelper>();
    final keys = <String>[
      'token',
      'authSessionToken',
      'id',
      'userRole',
      'email',
      'userName',
      'phoneNumber',
      'authLoginMethod',
    ];
    for (final key in keys) {
      await secure.removeData(key: key);
    }
  }

  Future<bool> _isCustomerSession() async {
    if (!sl.isRegistered<SecureCacheHelper>()) return false;
    final secure = sl<SecureCacheHelper>();
    final loginMethod = ((await secure.getData(key: 'authLoginMethod')) ?? '')
        .trim()
        .toLowerCase();
    return const <String>{
      'email',
      'phone',
      'google',
      'facebook',
      'apple',
    }.contains(loginMethod);
  }

  Future<void> _clearGuestSessionOnly() async {
    if (!sl.isRegistered<SecureCacheHelper>()) return;
    final secure = sl<SecureCacheHelper>();
    final keys = <String>[
      'token',
      'authSessionToken',
      'authLoginMethod',
      'guestUUID',
    ];
    for (final key in keys) {
      await secure.removeData(key: key);
    }
  }

  Future<void> _clearSessionForUnauthorizedRetry() async {
    if (await _isCustomerSession()) {
      await _clearAuthSessionOnly();
      return;
    }
    await _clearGuestSessionOnly();
  }
}
