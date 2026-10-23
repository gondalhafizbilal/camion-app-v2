import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/utils/image_url_transformer.dart';
import 'package:camion/core/utils/server_date_time_parser.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final dynamic data;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? brief;
  final String? priority;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.brief,
    this.priority,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final customerMap = customer is Map<String, dynamic>
        ? customer
        : const <String, dynamic>{};

    final rawData = json['data'] ?? json['payload'];

    return NotificationModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      userId: (json['userId'] ?? customerMap['uuid'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? json['brief'] ?? '').toString(),
      data: _normalizeS3Urls(rawData),
      isRead: json['isRead'] == true,
      createdAt:
          ServerDateTimeParser.parseToLocal(json['createdAt']) ??
          DateTime.now(),
      type: json['type']?.toString(),
      brief: json['brief']?.toString(),
      priority: json['priority']?.toString(),
    );
  }

  static dynamic _normalizeS3Urls(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('s3://') || trimmed.startsWith('s3:/')) {
        final transformed = ImageUrlTransformer.getTransformedImageUrl(
          trimmed,
          AppConfig.instance.assetsHost,
        );
        return transformed.isNotEmpty ? transformed : value;
      }
      return value;
    }

    if (value is List) {
      return value.map(_normalizeS3Urls).toList();
    }

    if (value is Map) {
      return value.map(
        (key, dynamic nestedValue) =>
            MapEntry(key, _normalizeS3Urls(nestedValue)),
      );
    }

    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'brief': brief,
      'priority': priority,
    };
  }
}
