class StoryFrameModel {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String thumbnailUrl;
  final int duration;
  final int order;

  const StoryFrameModel({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.duration,
    required this.order,
  });

  factory StoryFrameModel.fromJson(Map<String, dynamic> json) =>
      StoryFrameModel(
        id: (json['uuid'] ?? json['id'] ?? '').toString(),
        mediaUrl: (json['mediaUrl'] ?? '').toString(),
        mediaType: (json['mediaType'] ?? 'image').toString(),
        thumbnailUrl: (json['thumbnailUrl'] ?? '').toString(),
        duration: json['duration'] is int
            ? json['duration'] as int
            : int.tryParse(json['duration']?.toString() ?? '') ?? 5,
        order: json['order'] is int
            ? json['order'] as int
            : int.tryParse(json['order']?.toString() ?? '') ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'thumbnailUrl': thumbnailUrl,
    'duration': duration,
    'order': order,
  };
}

class StoriesModel {
  String id;
  String title;
  String description;
  String mediaUrl;
  String mediaType;
  String thumbnailUrl;
  int duration;
  DateTime expiresAt;
  DateTime createdAt;
  bool isActive;
  List<StoryFrameModel> frames;

  StoriesModel({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.duration,
    required this.expiresAt,
    required this.createdAt,
    required this.isActive,
    this.frames = const [],
  });

  StoryFrameModel get primaryFrame {
    if (frames.isNotEmpty) {
      return frames.first;
    }
    return StoryFrameModel(
      id: id,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      order: 0,
    );
  }

  factory StoriesModel.fromJson(Map<String, dynamic> json) => StoriesModel(
    id: (json['id'] ?? json['uuid'] ?? '').toString(),
    title: (json['title'] ?? json['caption'] ?? '').toString(),
    description: (json['description'] ?? json['caption'] ?? json['title'] ?? '')
        .toString(),
    mediaUrl: (json['mediaUrl'] ?? '').toString(),
    mediaType: (json['mediaType'] ?? 'image').toString(),
    thumbnailUrl: (json['thumbnailUrl'] ?? '').toString(),
    duration: json['duration'] is int
        ? json['duration'] as int
        : int.tryParse(json['duration']?.toString() ?? '') ?? 5,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    isActive: json['isActive'] == true,
    frames: (json['frames'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StoryFrameModel.fromJson)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'thumbnailUrl': thumbnailUrl,
    'duration': duration,
    'expiresAt': expiresAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'frames': frames.map((frame) => frame.toJson()).toList(),
  };
}
