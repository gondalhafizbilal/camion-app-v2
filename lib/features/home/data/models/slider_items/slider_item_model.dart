class SliderItemModel {
  final int id;
  final String imageUrl;
  final String imageUrlAr;
  final String imageUrlEn;
  final String title;
  final String description;
  final String discount;
  final String bannerColor;

  SliderItemModel({
    required this.id,
    required this.imageUrl,
    this.imageUrlAr = '',
    this.imageUrlEn = '',
    required this.title,
    required this.description,
    required this.discount,
    this.bannerColor = '',
  });

  factory SliderItemModel.fromJson(Map<String, dynamic> json) {
    return SliderItemModel(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl']?.toString().trim() ?? '',
      imageUrlAr: json['imageUrlAr']?.toString().trim() ?? '',
      imageUrlEn: json['imageUrlEn']?.toString().trim() ?? '',
      title: json['title']?.trim() ?? '',
      description: json['description']?.trim() ?? '',
      discount: json['discount']?.toString().trim() ?? '',
      bannerColor:
          json['bannerColor']?.toString().trim() ??
          json['color']?.toString().trim() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imageUrlAr': imageUrlAr,
      'imageUrlEn': imageUrlEn,
      'title': title,
      'description': description,
      'discount': discount,
      'bannerColor': bannerColor,
    };
  }
}
