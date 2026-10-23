import 'dart:convert';

import 'package:flutter/widgets.dart';

class ApiErrorModel {
  final String message;
  final IconData? icon;
  final int? statusCode;

  ApiErrorModel({required this.message, this.icon, this.statusCode});

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(message: _parseErrorMessage(json));
  }

  factory ApiErrorModel.fromDynamic(
    dynamic data, {
    String fallbackMessage = 'Something went wrong. Please try again.',
  }) {
    final parsed = _extractMessage(data);
    return ApiErrorModel(
      message:
          (parsed == null || parsed.trim().isEmpty)
          ? fallbackMessage
          : parsed.trim(),
    );
  }

  static String _parseErrorMessage(Map<String, dynamic> json) {
    try {
      final parsed =
          _extractMessage(json['message']) ??
          _extractMessage(json['errors']) ??
          _extractMessage(json['error']) ??
          _extractMessage(json['details']) ??
          _extractMessage(json['data']);

      if (parsed != null && parsed.isNotEmpty) {
        return parsed;
      }

      return 'Something went wrong. Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  static String? _extractMessage(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final normalized = value.trim();
      if (normalized.startsWith('{') || normalized.startsWith('[')) {
        try {
          final decoded = jsonDecode(normalized);
          final parsed = _extractMessage(decoded);
          if (parsed != null && parsed.trim().isNotEmpty) {
            return parsed.trim();
          }
        } catch (_) {
          // Ignore JSON parse errors and continue with raw string.
        }
      }
      return normalized.isEmpty ? null : normalized;
    }

    if (value is List) {
      final parts = value
          .map(_extractMessage)
          .whereType<String>()
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join('\n');
    }

    if (value is Map) {
      final map = value.map(
        (key, dynamic item) => MapEntry(key.toString(), item),
      );

      // Common backend contracts.
      final graphQLErrors = _extractGraphqlErrors(map['errors']);
      if (graphQLErrors != null && graphQLErrors.isNotEmpty) {
        return graphQLErrors;
      }

      // Prefer nested response details over generic wrapper exceptions.
      final response = map['response'];
      if (response is Map || response is List || response is String) {
        final responseMessage = _extractMessage(response);
        if (responseMessage != null && responseMessage.trim().isNotEmpty) {
          return responseMessage.trim();
        }
      }

      // Prefer deeply nested detail errors when present
      // (e.g. { error: "...", details: { response: { error: "specific" }}}).
      final details = map['details'];
      if (details is Map || details is List || details is String) {
        final detailedMessage = _extractMessage(details);
        if (detailedMessage != null && detailedMessage.trim().isNotEmpty) {
          return detailedMessage.trim();
        }
      }

      final nestedKnown =
          _extractMessage(map['error']) ??
          _extractMessage(map['errors']) ??
          _extractMessage(map['details']) ??
          _extractMessage(map['response']) ??
          _extractMessage(map['data']);
      if (nestedKnown != null && nestedKnown.isNotEmpty) {
        return nestedKnown;
      }

      final message = _extractMessage(map['message']);
      if (message != null && message.isNotEmpty) {
        return message;
      }

      // Validation errors shape: { emailAddress: "Customer not found..." }
      final fieldMessages = <String>[];
      map.forEach((field, dynamic item) {
        if (_isMetaKey(field)) {
          return;
        }
        final text = _extractMessage(item);
        if (text == null || text.isEmpty) return;
        if (map.length == 1) {
          fieldMessages.add(text);
        } else {
          fieldMessages.add('$field: $text');
        }
      });
      if (fieldMessages.isNotEmpty) {
        return fieldMessages.join('\n');
      }
    }

    return value.toString().trim().isEmpty ? null : value.toString().trim();
  }

  static String? _extractGraphqlErrors(dynamic value) {
    if (value is! List) return null;
    final messages = value
        .whereType<Map>()
        .map(
          (entry) => _extractMessage(
            entry.map((key, val) => MapEntry(key.toString(), val)),
          ),
        )
        .whereType<String>()
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (messages.isEmpty) return null;
    return messages.join('\n');
  }

  static bool _isMetaKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized == 'extensions' ||
        normalized == 'stack' ||
        normalized == 'stacktrace' ||
        normalized == 'timestamp' ||
        normalized == 'path' ||
        normalized == 'locations';
  }
}
