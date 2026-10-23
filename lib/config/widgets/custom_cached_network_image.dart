import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/image_url_transformer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomCachedNetworkImage extends StatelessWidget {
  const CustomCachedNetworkImage({super.key, required this.imageUrl, this.fit});

  final String imageUrl;
  final BoxFit? fit;

  String? _alternateProdAssetsUrl(String currentUrl) {
    final uri = Uri.tryParse(currentUrl);
    if (uri == null || uri.host.isEmpty) return null;

    const hostA = 'assets.camiontrading.com';
    const hostB = 'assets.camion-app.com';

    if (uri.host == hostA) {
      return uri.replace(host: hostB).toString();
    }
    if (uri.host == hostB) {
      return uri.replace(host: hostA).toString();
    }
    return null;
  }

  Widget _buildCachedImage({
    required String url,
    required BoxFit fit,
    required Widget fallback,
    required bool allowProdHostRetry,
  }) {
    return CachedNetworkImage(
      fit: fit,
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: const Color(0xFFF5F5F5),
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
      placeholder: (context, _) => Skeletonizer(
        enabled: true,
        child: SizedBox(
          height: 400.h,
          width: double.infinity,
          child: Image.asset(Assets.imagesShoes, fit: fit),
        ),
      ),
      errorWidget: (context, failedUrl, error) {
        if (allowProdHostRetry) {
          final altUrl = _alternateProdAssetsUrl(url);
          if (altUrl != null && altUrl != url) {
            return _buildCachedImage(
              url: altUrl,
              fit: fit,
              fallback: fallback,
              allowProdHostRetry: false,
            );
          }
        }
        return fallback;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawImageUrl = imageUrl.trim();
    final transformedImageUrl = ImageUrlTransformer.getTransformedImageUrl(
      rawImageUrl,
      AppConfig.instance.assetsHost,
    );
    final resolvedImageUrl = transformedImageUrl.isNotEmpty
        ? transformedImageUrl
        : rawImageUrl;
    final resolvedFit = fit ?? BoxFit.contain;
    final fallback = Image.asset(Assets.imagesShoes, fit: resolvedFit);

    if (resolvedImageUrl.isEmpty) {
      return fallback;
    }

    return _buildCachedImage(
      url: resolvedImageUrl,
      fit: resolvedFit,
      fallback: fallback,
      allowProdHostRetry: true,
    );
  }
}
