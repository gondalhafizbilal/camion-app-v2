import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';

/// Prefetches images into the cache so widgets can display them instantly.
class ImagePrefetcher {
  static final BaseCacheManager _cacheManager = DefaultCacheManager();

  /// Prefetch the first (thumbnail) image for each product.
  /// Concurrency is limited to avoid network saturation.
  static Future<void> prefetchProductThumbnails(
    List<AllProductModel> products, {
    int maxConcurrent = 6,
  }) async {
    final urls = <String>{};

    for (final p in products) {
      if (p.images.isNotEmpty) {
        final url = p.images.first.thumbnail;
        if (url.isNotEmpty) urls.add(url);
      }
    }

    if (urls.isEmpty) return;

    final batch = <Future<void>>[];
    for (final url in urls) {
      batch.add(_prefetch(url));
      if (batch.length >= maxConcurrent) {
        try {
          await Future.wait(batch);
        } catch (_) {
          // Ignore individual prefetch errors.
        }
        batch.clear();
      }
    }

    if (batch.isNotEmpty) {
      try {
        await Future.wait(batch);
      } catch (_) {
        // Ignore.
      }
    }
  }

  static Future<void> _prefetch(String url) async {
    try {
      final cached = await _cacheManager.getFileFromCache(url);
      if (cached != null && await cached.file.exists()) {
        return; // Already cached.
      }
      await _cacheManager.downloadFile(url);
    } catch (_) {
      // Swallow errors to keep UX smooth.
    }
  }
}
