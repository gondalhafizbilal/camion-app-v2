import 'package:dio/dio.dart';

class BackendUnavailableDetector {
  BackendUnavailableDetector._();

  static bool isBackendUnavailableStatusCode(int? statusCode) {
    return statusCode == 500 || statusCode == 502 || statusCode == 503;
  }

  static bool isBackendUnavailableMessage(String? message) {
    // Backend unavailable should be tied to explicit server crash codes only.
    return false;
  }

  static bool isBackendUnavailablePayload(dynamic payload) {
    if (payload == null) return false;

    if (payload is String) {
      return isBackendUnavailableMessage(payload);
    }

    if (payload is List) {
      return payload.any(isBackendUnavailablePayload);
    }

    if (payload is Map) {
      final map = payload.map((key, value) => MapEntry(key.toString(), value));

      final statusCode = int.tryParse((map['statusCode'] ?? '').toString());
      if (isBackendUnavailableStatusCode(statusCode)) return true;

      if (isBackendUnavailablePayload(map['response'])) return true;
      if (isBackendUnavailablePayload(map['details'])) return true;
      if (isBackendUnavailablePayload(map['data'])) return true;
    }

    return false;
  }

  static bool isBackendUnavailableDioException(DioException error) {
    if (isBackendUnavailableStatusCode(error.response?.statusCode)) {
      return true;
    }

    final requested = error.requestOptions.extra['backendUnavailable'] == true;
    if (requested) return true;

    return isBackendUnavailablePayload(error.response?.data);
  }
}
