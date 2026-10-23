import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/utils/image_url_transformer.dart';

class ReviewModel {
  final String id;
  final String customerId;
  final DateTime dateCreated;
  final String reviewer;
  final String review;
  final int rating;
  final bool verified;
  final bool isEdited;
  final List<ReviewImageModel> images;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.dateCreated,
    required this.reviewer,
    required this.review,
    required this.rating,
    required this.verified,
    required this.isEdited,
    required this.images,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final customerRaw = json['customer'];
    final customer = customerRaw is Map<String, dynamic>
        ? customerRaw
        : const <String, dynamic>{};
    final rawRating = json['rating'];
    final parsedRating = rawRating is num
        ? rawRating.toInt()
        : int.tryParse((rawRating ?? '').toString()) ?? 0;
    final createdAtRaw =
        json['createdAt'] ?? json['date_created'] ?? json['dateCreated'];

    final imagesRaw = json['images'];
    final images = imagesRaw is List
        ? imagesRaw
              .map(
                (e) => ReviewImageModel.fromJson(
                  (e ?? const <String, dynamic>{}) as Map<String, dynamic>,
                ),
              )
              .toList()
        : const <ReviewImageModel>[];

    return ReviewModel(
      id: (json['uuid'] ?? json['id'] ?? '').toString(),
      customerId: (customer['uuid'] ?? json['customerId'] ?? '').toString(),
      dateCreated:
          DateTime.tryParse((createdAtRaw ?? '').toString()) ?? DateTime.now(),
      reviewer:
          (customer['fullName'] ??
                  json['reviewer'] ??
                  json['reviewerName'] ??
                  'Anonymous')
              .toString(),
      review: (json['comment'] ?? json['review'] ?? '').toString(),
      rating: parsedRating,
      verified: (json['verified'] as bool?) ?? false,
      isEdited: (json['isEdited'] as bool?) ?? false,
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'dateCreated': dateCreated.toIso8601String(),
      'reviewer': reviewer,
      'review': review,
      'rating': rating,
      'verified': verified,
      'isEdited': isEdited,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}

class ReviewImageModel {
  final String id;
  final String thumbnailUrl;
  final String imageUrl;

  const ReviewImageModel({
    required this.id,
    required this.thumbnailUrl,
    required this.imageUrl,
  });

  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    String normalizeImageUrl(String rawValue) {
      final trimmed = rawValue.trim();
      if (trimmed.isEmpty) return '';
      final transformed = ImageUrlTransformer.getTransformedImageUrl(
        trimmed,
        AppConfig.instance.assetsHost,
      );
      return transformed.isNotEmpty ? transformed : trimmed;
    }

    return ReviewImageModel(
      id: (json['uuid'] ?? json['id'] ?? '').toString(),
      thumbnailUrl: normalizeImageUrl((json['thumbnailUrl'] ?? '').toString()),
      imageUrl: normalizeImageUrl((json['imageUrl'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'thumbnailUrl': thumbnailUrl, 'imageUrl': imageUrl};
  }
}
