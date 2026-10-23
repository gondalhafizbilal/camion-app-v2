import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

class NetworkLoggingInterceptor extends Interceptor {
  static const _tag = 'API';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['requestStartMs'] = DateTime.now().millisecondsSinceEpoch;

    log(
      [
        '-> ${options.method.toUpperCase()} ${options.uri}',
        'Headers: ${_safePretty(options.headers)}',
        if (options.queryParameters.isNotEmpty)
          'Query: ${_safePretty(options.queryParameters)}',
        if (options.data != null) 'Payload: ${_safePretty(options.data)}',
      ].join('\n'),
      name: _tag,
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final started = response.requestOptions.extra['requestStartMs'] as int?;
    final tookMs = started == null
        ? null
        : DateTime.now().millisecondsSinceEpoch - started;

    log(
      [
        '<- ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri}',
        'Status: ${response.statusCode}${tookMs == null ? '' : ' (${tookMs}ms)'}',
        'Response: ${_safePretty(response.data)}',
      ].join('\n'),
      name: _tag,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final started = err.requestOptions.extra['requestStartMs'] as int?;
    final tookMs = started == null
        ? null
        : DateTime.now().millisecondsSinceEpoch - started;

    log(
      [
        'xx ${err.requestOptions.method.toUpperCase()} ${err.requestOptions.uri}',
        "Status: ${err.response?.statusCode ?? 'N/A'}${tookMs == null ? '' : ' (${tookMs}ms)'}",
        'Message: ${err.message}',
        if (err.requestOptions.data != null)
          'Payload: ${_safePretty(err.requestOptions.data)}',
        if (err.response?.data != null)
          'Error Response: ${_safePretty(err.response?.data)}',
      ].join('\n'),
      name: _tag,
    );

    handler.next(err);
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
}
