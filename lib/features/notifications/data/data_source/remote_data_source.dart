import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:dio/dio.dart';

class NotificationRemoteDataSource {
  final ApiConsumer apiConsumer;
  NotificationRemoteDataSource({required this.apiConsumer});

  Future<Response> getNotifications({required String token}) async {
    final response = await apiConsumer.post(
      EndPoints.graphql,
      data: {
        'query': '''
query GetNotifications {
  getNotifications {
    uuid
    type
    title
    brief
    message
    priority
    isRead
    createdAt
    updatedAt
  }
}
''',
        'variables': const <String, dynamic>{},
      },
      headers: {"Authorization": "Bearer $token"},
    );

    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response(
          requestOptions: response.requestOptions,
          data: {'message': 'Invalid GraphQL response'},
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final errors = root['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      final message = first is Map<String, dynamic>
          ? (first['message']?.toString() ?? 'GraphQL request failed')
          : 'GraphQL request failed';
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response(
          requestOptions: response.requestOptions,
          data: {'message': message},
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final data = root['data'];
    final notifications = data is Map<String, dynamic>
        ? data['getNotifications']
        : const [];

    return Response(
      requestOptions: response.requestOptions,
      data: notifications is List ? notifications : const [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: response.extra,
    );
  }
}
