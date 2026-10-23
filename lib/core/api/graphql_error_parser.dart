import 'package:camion/core/utils/app_toast.dart';
import 'package:dio/dio.dart';

class GraphqlErrorParser {
  GraphqlErrorParser._();

  static void throwIfAny(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map) return;
    final map = Map<String, dynamic>.from(body);
    final rawErrors = map['errors'];
    if (rawErrors is! List || rawErrors.isEmpty) return;

    final errors = rawErrors.whereType<Map>().map((entry) {
      return Map<String, dynamic>.from(entry);
    }).toList();
    if (errors.isEmpty) return;

    final message = _extractMessage(errors) ?? 'GraphQL request failed';
    final statusCode = _extractStatusCode(errors) ?? 400;
    if (_isUnauthorized(errors, message)) {
      AppToast.show(msg: message);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: Response<dynamic>(
        requestOptions: response.requestOptions,
        statusCode: statusCode,
        data: map,
      ),
      type: DioExceptionType.badResponse,
      message: message,
    );
  }

  static String? _extractMessage(List<Map<String, dynamic>> errors) {
    for (final error in errors) {
      final message = error['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return null;
  }

  static int? _extractStatusCode(List<Map<String, dynamic>> errors) {
    for (final error in errors) {
      final extensions = error['extensions'];
      if (extensions is! Map) continue;
      final extMap = Map<String, dynamic>.from(extensions);

      final direct = int.tryParse((extMap['statusCode'] ?? '').toString());
      if (direct != null) return direct;

      final original = extMap['originalError'];
      if (original is Map) {
        final originalMap = Map<String, dynamic>.from(original);
        final nested = int.tryParse(
          (originalMap['statusCode'] ?? '').toString(),
        );
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static bool _isUnauthorized(
    List<Map<String, dynamic>> errors,
    String message,
  ) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('unauthenticated') ||
        lowerMessage.contains('forbidden')) {
      return true;
    }

    for (final error in errors) {
      final extensions = error['extensions'];
      if (extensions is! Map) continue;
      final extMap = Map<String, dynamic>.from(extensions);
      final code = (extMap['code'] ?? '').toString().toUpperCase();
      if (code == 'UNAUTHENTICATED' || code == 'FORBIDDEN') {
        return true;
      }
      final original = extMap['originalError'];
      if (original is Map) {
        final originalMap = Map<String, dynamic>.from(original);
        final status = int.tryParse(
          (originalMap['statusCode'] ?? '').toString(),
        );
        if (status == 401 || status == 403) {
          return true;
        }
      }
    }

    return false;
  }
}
