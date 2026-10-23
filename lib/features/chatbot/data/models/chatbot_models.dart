class ChatSource {
  final String title;
  final String content;
  final String? category;
  final double? relevanceScore;

  const ChatSource({
    required this.title,
    required this.content,
    this.category,
    this.relevanceScore,
  });

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    final rawScore = json['relevanceScore'];
    return ChatSource(
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      category: json['category']?.toString(),
      relevanceScore: rawScore is num ? rawScore.toDouble() : null,
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime? timestamp;
  final List<ChatSource> sources;

  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.sources = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    return ChatMessage(
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? '').toString(),
      timestamp: DateTime.tryParse(
        (json['timestamp'] ?? json['createdAt'] ?? '').toString(),
      ),
      sources: rawSources is List
          ? rawSources
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatSource.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

class ChatHistoryResponse {
  final String sessionUUID;
  final List<ChatMessage> messages;

  const ChatHistoryResponse({
    required this.sessionUUID,
    required this.messages,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return ChatHistoryResponse(
      sessionUUID: (json['sessionUUID'] ?? json['sessionId'] ?? '').toString(),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatMessage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

class AskSessionResponse {
  final String sessionUUID;
  final String answer;
  final List<ChatSource> sources;

  const AskSessionResponse({
    required this.sessionUUID,
    required this.answer,
    required this.sources,
  });

  factory AskSessionResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    return AskSessionResponse(
      sessionUUID: (json['sessionUUID'] ?? json['sessionId'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      sources: rawSources is List
          ? rawSources
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatSource.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

class ChatSessionItem {
  final String sessionUUID;
  final String customerUUID;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ChatMessage> messages;

  const ChatSessionItem({
    required this.sessionUUID,
    required this.customerUUID,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory ChatSessionItem.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return ChatSessionItem(
      sessionUUID: (json['sessionUUID'] ?? json['sessionId'] ?? '').toString(),
      customerUUID: (json['customerUUID'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatMessage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}
