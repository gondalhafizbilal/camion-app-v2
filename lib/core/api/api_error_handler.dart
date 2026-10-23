import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/api_error_factory.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:camion/core/utils/app_toast.dart';

class ApiErrorHandler {
  static DateTime? _lastNoDataPopupAt;
  static const Duration _noDataPopupCooldown = Duration(seconds: 3);
  static const String _suppressBackendUnavailableHeader =
      'x-suppress-backend-unavailable';

  static void _showNoDataAvailablePopup() {
    final now = DateTime.now();
    if (_lastNoDataPopupAt != null &&
        now.difference(_lastNoDataPopupAt!) < _noDataPopupCooldown) {
      return;
    }
    _lastNoDataPopupAt = now;
    AppToast.show(
      msg: ApiErrorFactory.noDataAvailableMessage,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static ApiErrorModel handle(dynamic e, {bool showNoDataPopup = true}) {
    if (e is DioException) {
      final suppressBackendUnavailable = _shouldSuppressBackendUnavailable(e);
      if (!suppressBackendUnavailable &&
          BackendUnavailableDetector.isBackendUnavailableDioException(e)) {
        BackendUnavailableNotifier.show();
      }
      switch (e.type) {
        case DioExceptionType.connectionError:
          return _noData(
            icon: Icons.wifi_off,
            statusCode: LocalStatusCodes.connectionError,
            showNoDataPopup: showNoDataPopup,
          );
        case DioExceptionType.connectionTimeout:
          return _noData(
            icon: Icons.timer_off,
            statusCode: LocalStatusCodes.connectionTimeout,
            showNoDataPopup: showNoDataPopup,
          );
        case DioExceptionType.sendTimeout:
          return _noData(
            icon: Icons.send,
            statusCode: LocalStatusCodes.sendTimeout,
            showNoDataPopup: showNoDataPopup,
          );
        case DioExceptionType.receiveTimeout:
          return _noData(
            icon: Icons.downloading,
            statusCode: LocalStatusCodes.receiveTimeout,
            showNoDataPopup: showNoDataPopup,
          );
        case DioExceptionType.badCertificate:
          return ApiErrorModel(
            message:
                'Security issue detected with the server. Connection not secure.',
            icon: Icons.security,
            statusCode: LocalStatusCodes.badCertificate,
          );
        case DioExceptionType.badResponse:
          return _badResponse(e, showNoDataPopup: showNoDataPopup);
        case DioExceptionType.cancel:
          return ApiErrorModel(
            message: 'The request was cancelled. Please try again.',
            icon: Icons.cancel,
            statusCode: LocalStatusCodes.cancel,
          );
        case DioExceptionType.unknown:
          return _noData(
            icon: Icons.error_outline,
            statusCode: LocalStatusCodes.unknown,
            showNoDataPopup: showNoDataPopup,
          );
      }
    }

    if (e is Exception) {
      return ApiErrorFactory.defaultError;
    }

    if (showNoDataPopup) {
      _showNoDataAvailablePopup();
    }
    return ApiErrorFactory.defaultError;
  }

  static ApiErrorModel _noData({
    required IconData icon,
    required int statusCode,
    required bool showNoDataPopup,
  }) {
    if (showNoDataPopup) {
      _showNoDataAvailablePopup();
    }
    return ApiErrorModel(
      message: ApiErrorFactory.noDataAvailableMessage,
      icon: icon,
      statusCode: statusCode,
    );
  }

  static ApiErrorModel _badResponse(
    DioException e, {
    required bool showNoDataPopup,
  }) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final suppressBackendUnavailable = _shouldSuppressBackendUnavailable(e);
    final explicitlyFlagged =
        e.requestOptions.extra['backendUnavailable'] == true;
    final isBackendUnavailable =
        !suppressBackendUnavailable &&
        (BackendUnavailableDetector.isBackendUnavailableStatusCode(
              statusCode,
            ) ||
            explicitlyFlagged);
    if (isBackendUnavailable) {
      BackendUnavailableNotifier.show();
    }
    String errorMessage;
    if (responseData == null ||
        (responseData is String && responseData.trim().isEmpty)) {
      if (showNoDataPopup) {
        _showNoDataAvailablePopup();
      }
      if (isBackendUnavailable) {
        errorMessage = ApiErrorFactory.serviceUnavailable(
          statusCode: statusCode,
        ).message;
      } else {
        errorMessage = _fallbackByStatusCode(statusCode);
      }
    } else if (responseData is Map ||
        responseData is List ||
        responseData is String) {
      final parsed = ApiErrorModel.fromDynamic(
        responseData,
        fallbackMessage: isBackendUnavailable
            ? ApiErrorFactory.serviceUnavailable(statusCode: statusCode).message
            : _fallbackByStatusCode(statusCode),
      ).message;
      errorMessage = parsed.trim().isEmpty
          ? (isBackendUnavailable
                ? ApiErrorFactory.serviceUnavailable(
                    statusCode: statusCode,
                  ).message
                : _fallbackByStatusCode(statusCode))
          : parsed;
    } else {
      errorMessage = isBackendUnavailable
          ? ApiErrorFactory.serviceUnavailable(statusCode: statusCode).message
          : _fallbackByStatusCode(statusCode);
    }

    return ApiErrorModel(
      message: errorMessage,
      icon: Icons.warning,
      statusCode: isBackendUnavailable
          ? (statusCode ?? 503)
          : (statusCode ?? LocalStatusCodes.badResponse),
    );
  }

  static String _fallbackByStatusCode(int? statusCode) {
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
        return 'An error occurred while processing your request.';
    }
  }

  static bool _shouldSuppressBackendUnavailable(DioException error) {
    final rawHeader = error
        .requestOptions
        .headers[_suppressBackendUnavailableHeader]
        ?.toString()
        .toLowerCase()
        .trim();
    return rawHeader == 'true' || rawHeader == '1';
  }
}
