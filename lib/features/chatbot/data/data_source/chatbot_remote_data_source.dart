import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/features/chatbot/data/models/chatbot_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ChatbotRemoteDataSource {
  ChatbotRemoteDataSource({required this.apiConsumer});

  final ApiConsumer apiConsumer;

  String get _baseUrl => EndPoints.chatbotBaseUrl;

  Future<String> createSession({required String token}) async {
    final payload = <String, dynamic>{'token': token.trim()};

    final Response response = await apiConsumer.post(
      '$_baseUrl/v1/chatbot/sessions',
      data: payload,
    );

    return (response.data['sessionUUID'] ?? response.data['sessionId'] ?? '')
        .toString();
  }

  Future<ChatHistoryResponse> getSessionHistory(String sessionId) async {
    final Response response = await apiConsumer.get(
      '$_baseUrl/v1/chatbot/sessions/$sessionId/history',
    );

    return ChatHistoryResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AskSessionResponse> askInSession({
    required String sessionId,
    required String token,
    required String question,
  }) async {
    final payload = <String, dynamic>{
      'token': token.trim(),
      'question': question,
    };

    if (AppConfig.instance.enableNetworkLogs) {
      debugPrint(
        '[CHATBOT][REQUEST] POST $_baseUrl/v1/chatbot/sessions/$sessionId/ask',
      );
      debugPrint('[CHATBOT][REQUEST][BODY] $payload');
    }

    final Response response = await apiConsumer.post(
      '$_baseUrl/v1/chatbot/sessions/$sessionId/ask',
      data: payload,
    );

    if (AppConfig.instance.enableNetworkLogs) {
      debugPrint('[CHATBOT][RESPONSE][STATUS] ${response.statusCode}');
      debugPrint('[CHATBOT][RESPONSE][BODY] ${response.data}');
    }

    return AskSessionResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AskSessionResponse> askStateless({required String question}) async {
    final payload = <String, dynamic>{'question': question};
    final Response response = await apiConsumer.post(
      '$_baseUrl/v1/chatbot/ask',
      data: payload,
    );
    return AskSessionResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String title,
    required String content,
    String? source,
  }) async {
    final payload = <String, dynamic>{'title': title, 'content': content};
    if (source != null && source.trim().isNotEmpty) {
      payload['source'] = source.trim();
    }
    final Response response = await apiConsumer.post(
      '$_baseUrl/v1/chatbot/upload',
      data: payload,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    String? title,
    String? category,
    String? source,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
    });

    final Response response = await apiConsumer.post(
      '$_baseUrl/v1/chatbot/upload-file',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteAllDocuments() async {
    await apiConsumer.delete('$_baseUrl/v1/chatbot/documents');
  }

  Future<List<ChatSessionItem>> getSessions({
    required String customerUUID,
  }) async {
    final Response response = await apiConsumer.get(
      '$_baseUrl/v1/chatbot/sessions?customerUUID=$customerUUID',
    );
    final raw = response.data;
    if (raw is! List) return const <ChatSessionItem>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => ChatSessionItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> deleteSession(String sessionId) async {
    await apiConsumer.delete('$_baseUrl/v1/chatbot/sessions/$sessionId');
  }
}
