class ImageUrlTransformer {
  static const String _legacyDevAssetsHost =
      'https://dev-assets-167781471441-eu-north-1.s3.eu-north-1.amazonaws.com';

  static String getTransformedImageUrl(String imageUrl, String assetsHost) {
    final rawImageUrl = imageUrl.trim();
    final rawAssetsHost = assetsHost.trim();
    if (rawImageUrl.isEmpty || rawAssetsHost.isEmpty) {
      return '';
    }

    final normalizedAssetsHost = rawAssetsHost.endsWith('/')
        ? rawAssetsHost.substring(0, rawAssetsHost.length - 1)
        : rawAssetsHost;

    if (rawImageUrl.startsWith('https:') || rawImageUrl.startsWith('http:')) {
      return rawImageUrl.replaceFirst(
        _legacyDevAssetsHost,
        normalizedAssetsHost,
      );
    }

    if (rawImageUrl.startsWith('//')) {
      return 'https:$rawImageUrl';
    }

    if (rawImageUrl.startsWith('s3://')) {
      final path = rawImageUrl
          .substring('s3://'.length)
          .replaceFirst(RegExp(r'^/+'), '');
      return '$normalizedAssetsHost/$path';
    }

    if (rawImageUrl.startsWith('s3:/')) {
      final path = rawImageUrl
          .substring('s3:/'.length)
          .replaceFirst(RegExp(r'^/+'), '');
      return '$normalizedAssetsHost/$path';
    }

    if (rawImageUrl.startsWith('/')) {
      final path = rawImageUrl.replaceFirst(RegExp(r'^/+'), '');
      return '$normalizedAssetsHost/$path';
    }

    if (!rawImageUrl.contains('://') && !rawImageUrl.startsWith('data:')) {
      final path = rawImageUrl.replaceFirst(RegExp(r'^/+'), '');
      return '$normalizedAssetsHost/$path';
    }

    return rawImageUrl;
  }
}
