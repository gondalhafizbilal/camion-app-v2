class CmsPostModel {
  const CmsPostModel({
    required this.uuid,
    required this.slug,
    required this.title,
    required this.brief,
    required this.content,
    required this.enabled,
    required this.images,
    required this.createdByUuid,
    required this.createdByFullName,
  });

  final String uuid;
  final String slug;
  final String title;
  final String brief;
  final String content;
  final bool enabled;
  final dynamic images;
  final String createdByUuid;
  final String createdByFullName;

  factory CmsPostModel.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'];
    return CmsPostModel(
      uuid: json['uuid']?.toString().trim() ?? '',
      slug: json['slug']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      brief: json['brief']?.toString().trim() ?? '',
      content: json['content']?.toString().trim() ?? '',
      enabled: json['enabled'] == true,
      images: json['images'],
      createdByUuid: createdBy is Map<String, dynamic>
          ? createdBy['uuid']?.toString().trim() ?? ''
          : '',
      createdByFullName: createdBy is Map<String, dynamic>
          ? createdBy['fullName']?.toString().trim() ?? ''
          : '',
    );
  }
}
