import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/api/api_error_toast_interceptor.dart';
import 'package:camion/core/api/network_logging_interceptor.dart';
import 'package:camion/core/api/request_context_interceptor.dart';
import 'package:camion/core/api/unauthorized_recovery_interceptor.dart';
import 'package:dio/dio.dart';
import 'api_consumer.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    dio.options
      ..connectTimeout = const Duration(seconds: 60)
      ..receiveTimeout = const Duration(seconds: 60)
      ..sendTimeout = const Duration(seconds: 60);
    dio.interceptors.add(RequestContextInterceptor());
    dio.interceptors.add(ApiErrorToastInterceptor());
    dio.interceptors.add(UnauthorizedRecoveryInterceptor(dio));

    if (AppConfig.instance.enableNetworkLogs) {
      dio.interceptors.add(NetworkLoggingInterceptor());
    }
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final options = Options(headers: headers);
    final response = await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final options = Options(headers: headers);
    final response = await dio.get(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final options = Options(headers: headers);
    final response = await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final options = Options(headers: headers);
    final response = await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final options = Options(headers: headers);
    final response = await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }
}
