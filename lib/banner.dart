class BannerModel {
  final String id;
  final String type;
  final String imageUrl;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.type,
    required this.imageUrl,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      isActive: json['isActive'] == true,
    );
  }
}
