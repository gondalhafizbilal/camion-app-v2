import 'dart:convert';

import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiErrorToastInterceptor extends Interceptor {
  static const String _toastShownKey = 'apiErrorToastShown';
  static const String _suppressBackendUnavailableHeader =
      'x-suppress-backend-unavailable';
  static const String _suppressErrorToastHeader = 'x-suppress-error-toast';
  static DateTime? _lastToastAt;
  static String _lastToastMessage = '';

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_shouldSuppressErrorToast(response.requestOptions)) {
      handler.next(response);
      return;
    }

    final payload = response.data;
    if (payload is Map<String, dynamic> &&
        _isSemanticFailure(payload, response)) {
      _logGraphqlErrorsIfAny(
        response.requestOptions,
        payload,
        response.statusCode,
      );
      final message = ApiErrorModel.fromDynamic(payload).message.trim();
      final isBackendUnavailable =
          BackendUnavailableDetector.isBackendUnavailableStatusCode(
            response.statusCode,
          );
      final suppressBackendUnavailable = _shouldSuppressBackendUnavailable(
        response.requestOptions,
      );

      if (isBackendUnavailable && !suppressBackendUnavailable) {
        BackendUnavailableNotifier.show();
        response.requestOptions.extra['backendUnavailable'] = true;
      } else {
        if (_shouldSuppressGuestRegisterDuplicateDeviceToast(
          requestOptions: response.requestOptions,
          responseData: payload,
          fallbackMessage: message,
        )) {
          response.requestOptions.extra[_toastShownKey] = true;
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: message,
              message: message,
            ),
          );
          return;
        }
        final suppressed = await _shouldSuppressUnauthorizedToast(message);
        _logUnauthorizedDecision(
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          message: message,
          suppressed: suppressed,
          source: 'onResponse',
        );
        if (!suppressed) {
          _showErrorToast(message);
        }
        response.requestOptions.extra[_toastShownKey] = true;
      }

      final normalizedResponse =
          isBackendUnavailable &&
              !BackendUnavailableDetector.isBackendUnavailableStatusCode(
                response.statusCode,
              )
          ? Response<dynamic>(
              requestOptions: response.requestOptions,
              data: response.data,
              statusCode: 503,
              statusMessage: response.statusMessage,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
              extra: response.extra,
              headers: response.headers,
            )
          : response;
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: normalizedResponse,
          type: DioExceptionType.badResponse,
          error: message,
          message: message,
        ),
      );
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldSuppressErrorToast(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final isBackendUnavailable =
        BackendUnavailableDetector.isBackendUnavailableDioException(err);
    final suppressBackendUnavailable = _shouldSuppressBackendUnavailable(
      err.requestOptions,
    );
    if (isBackendUnavailable && !suppressBackendUnavailable) {
      BackendUnavailableNotifier.show();
      err.requestOptions.extra['backendUnavailable'] = true;
    }

    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      _logGraphqlErrorsIfAny(
        err.requestOptions,
        data,
        err.response?.statusCode,
      );
    }
    final alreadyShown = err.requestOptions.extra[_toastShownKey] == true;
    if (!alreadyShown) {
      final message = _resolveErrorMessage(err).trim();
      if (_shouldSuppressGuestRegisterDuplicateDeviceToast(
        requestOptions: err.requestOptions,
        responseData: err.response?.data,
        fallbackMessage: message,
      )) {
        err.requestOptions.extra[_toastShownKey] = true;
        handler.next(err);
        return;
      }
      if (!isBackendUnavailable) {
        final suppressed = await _shouldSuppressUnauthorizedToast(message);
        _logUnauthorizedDecision(
          requestOptions: err.requestOptions,
          statusCode: err.response?.statusCode,
          message: message,
          suppressed: suppressed,
          source: 'onError',
        );
        if (!suppressed) {
          _showErrorToast(message);
        }
        err.requestOptions.extra[_toastShownKey] = true;
      }
    }
    handler.next(err);
  }

  Future<bool> _shouldSuppressUnauthorizedToast(String message) async {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final isUnauthorizedMessage =
        normalized.contains('unauthorized') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('invalid token') ||
        normalized.contains('session expired') ||
        normalized.contains('please login') ||
        normalized.contains('please log in');
    return isUnauthorizedMessage;
  }

  void _logUnauthorizedDecision({
    required RequestOptions requestOptions,
    required int? statusCode,
    required String message,
    required bool suppressed,
    required String source,
  }) {
    final normalized = message.trim().toLowerCase();
    final isUnauthorizedMessage =
        normalized.contains('unauthorized') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('invalid token') ||
        normalized.contains('session expired') ||
        normalized.contains('please login') ||
        normalized.contains('please log in');
    if (!isUnauthorizedMessage) return;

    final currentLocation = RouterGenerator
        .mainRouting
        .routeInformationProvider
        .value
        .uri
        .toString();
    debugPrint(
      '[AUTH][TOAST][$source] unauthorized message="$message" status=${statusCode ?? 'N/A'} '
      'method=${requestOptions.method} path=${requestOptions.path} uri=${requestOptions.uri} '
      'route=$currentLocation suppressed=$suppressed',
    );
  }

  bool _isSemanticFailure(Map<String, dynamic> payload, Response response) {
    final lowerPath = response.requestOptions.path.toLowerCase();
    final isGraphql = lowerPath.contains('/graphql');

    if (isGraphql) {
      final allowPartialHeader = response
          .requestOptions
          .headers['x-allow-graphql-partial-data']
          ?.toString()
          .toLowerCase();
      final allowGraphqlPartialData =
          allowPartialHeader == 'true' || allowPartialHeader == '1';
      final data = payload['data'];
      if (_hasGraphqlData(data)) {
        return false;
      }
      if (allowGraphqlPartialData) {
        if (_hasGraphqlData(data)) {
          return false;
        }
      }
      final errors = payload['errors'];
      if (_hasContent(errors)) {
        return true;
      }
      return false;
    }

    final success = payload['success'];
    if (success is bool && success == false) return true;

    final status = payload['status'];
    if (status is bool && status == false) return true;

    final ok = payload['ok'];
    if (ok is bool && ok == false) return true;

    final hasError = _hasContent(payload['error']);
    if (hasError) return true;

    final hasErrors = _hasContent(payload['errors']);
    if (hasErrors) {
      final hasData = payload.containsKey('data') && payload['data'] != null;
      if (!hasData) return true;
    }

    return false;
  }

  bool _hasContent(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  bool _hasGraphqlData(dynamic data) {
    if (data == null) return false;
    if (data is Map) {
      if (data.isEmpty) return false;
      for (final value in data.values) {
        if (value != null) return true;
      }
      return false;
    }
    if (data is List) {
      return data.isNotEmpty;
    }
    if (data is String) {
      return data.trim().isNotEmpty;
    }
    return true;
  }

  bool _shouldSuppressBackendUnavailable(RequestOptions requestOptions) {
    final rawHeader = requestOptions.headers[_suppressBackendUnavailableHeader]
        ?.toString()
        .toLowerCase()
        .trim();
    return rawHeader == 'true' || rawHeader == '1';
  }

  bool _shouldSuppressErrorToast(RequestOptions requestOptions) {
    final rawHeader = requestOptions.headers[_suppressErrorToastHeader]
        ?.toString()
        .toLowerCase()
        .trim();
    return rawHeader == 'true' || rawHeader == '1';
  }

  bool _shouldSuppressGuestRegisterDuplicateDeviceToast({
    required RequestOptions requestOptions,
    required dynamic responseData,
    required String fallbackMessage,
  }) {
    final path = requestOptions.path.toLowerCase();
    final isGuestRegister =
        path.contains('/v1/auth/guest/register') ||
        path.contains('/auth/guest/register');
    if (!isGuestRegister) return false;

    final normalizedMessage = _normalizeForMatch(fallbackMessage);
    if (_isDuplicateDeviceIdMessage(normalizedMessage)) return true;

    if (responseData is Map) {
      final mapped = responseData.map(
        (key, dynamic value) => MapEntry(key.toString(), value),
      );
      final errors = mapped['errors'];
      if (errors is Map) {
        final deviceIdError = errors['deviceId']?.toString() ?? '';
        if (_isDuplicateDeviceIdMessage(_normalizeForMatch(deviceIdError))) {
          return true;
        }
      }
      final topLevelDeviceId = mapped['deviceId']?.toString() ?? '';
      if (_isDuplicateDeviceIdMessage(_normalizeForMatch(topLevelDeviceId))) {
        return true;
      }
    }

    return false;
  }

  String _normalizeForMatch(String input) {
    return input.trim().toLowerCase();
  }

  bool _isDuplicateDeviceIdMessage(String normalized) {
    if (normalized.isEmpty) return false;
    return normalized.contains(
          'a device using the provided device id has already been registered',
        ) ||
        normalized.contains('device id has already been registered') ||
        normalized.contains('deviceid has already been registered');
  }

  void _logGraphqlErrorsIfAny(
    RequestOptions requestOptions,
    Map<String, dynamic> payload,
    int? statusCode,
  ) {
    final lowerPath = requestOptions.path.toLowerCase();
    if (!lowerPath.contains('/graphql')) return;

    final errors = payload['errors'];
    if (!_hasContent(errors)) return;

    final body = requestOptions.data is Map
        ? Map<String, dynamic>.from(requestOptions.data as Map)
        : const <String, dynamic>{};
    final query = body['query']?.toString() ?? '';
    final operationName =
        _extractOperationName(query) ??
        requestOptions.extra['graphqlOperation']?.toString() ??
        'unknown_operation';

    final variables = body['variables'];
    debugPrint(
      '[GRAPHQL][ERROR] op=$operationName status=${statusCode ?? 'N/A'} uri=${requestOptions.uri}\n'
      'variables: ${_safePretty(variables)}\n'
      'errors: ${_safePretty(errors)}',
    );
  }

  String? _extractOperationName(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(
      r'(query|mutation|subscription)\s+([A-Za-z_][A-Za-z0-9_]*)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    return match?.group(2);
  }

  String _safePretty(dynamic value) {
    try {
      if (value == null) return 'null';
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return value;
        final decoded = jsonDecode(trimmed);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _resolveErrorMessage(DioException err) {
    final responseData = err.response?.data;
    if (responseData != null) {
      return ApiErrorModel.fromDynamic(
        responseData,
        fallbackMessage: _fallbackMessageForStatus(err.response?.statusCode),
      ).message;
    }

    final message = err.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return _fallbackMessageForStatus(err.response?.statusCode);
  }

  String _fallbackMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input and try again.';
      case 401:
        return 'Unauthorized request. Please login and try again.';
      case 403:
        return 'Access denied for this request.';
      case 404:
        return 'Requested resource was not found.';
      case 409:
        return 'Request conflict. Please refresh and try again.';
      case 422:
        return 'Validation failed. Please review your input.';
      case 429:
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void _showErrorToast(String message) {
    if (message.isEmpty) return;
    final now = DateTime.now();
    final isDuplicate =
        _lastToastMessage == message &&
        _lastToastAt != null &&
        now.difference(_lastToastAt!) < const Duration(milliseconds: 1200);
    if (isDuplicate) return;
    _lastToastMessage = message;
    _lastToastAt = now;

    AppToast.show(
      msg: message,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
