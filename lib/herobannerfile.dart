// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:skeletonizer/skeletonizer.dart';
//
//  import 'banner.dart';
//  import 'core/api/end_points.dart';
// import 'core/cache/secure_cache_storage.dart';
// import 'core/services/service_locator.dart';
//
// class InlineHeroBanners extends StatefulWidget {
//   const InlineHeroBanners({super.key, required this.type});
//
//   /// type = hero | sidebar | hot_deals
//   final String type;
//
//   @override
//   State<InlineHeroBanners> createState() => _InlineHeroBannersState();
// }
//
// class _InlineHeroBannersState extends State<InlineHeroBanners> {
//   late final Dio _dio;
//   late Future<List<BannerModel>> _future;
//   final PageController _pageController = PageController();
//   int currentIndex = 0;
//
//   @override
//   Future<void> initState() async {
//     super.initState();
//
//     _future = _fetchBanners();
//   }
//   Future<List<BannerModel>> _fetchBanners() async {
//     final token = await sl<SecureCacheHelper>().getData(key: 'token');
//
//     _dio = Dio(
//       BaseOptions(
//         baseUrl: EndPoints.baseUrl, // ✅ base url from your endpoints
//         connectTimeout: const Duration(seconds: 20),
//         receiveTimeout: const Duration(seconds: 20),
//         headers: {
//           'Accept': 'application/json',
//           'Authorization':  'Bearer $token',
//         },
//       ),
//     );
//     // ✅ GET {{base_url}}/banners/:type
//     final res = await _dio.get('/banners/${widget.type}');
//
//     final data = res.data;
//
//     final List list =
//     (data is List) ? data : (data?['data'] as List? ?? []);
//
//     final banners = list
//         .map((e) =>
//         BannerModel.fromJson((e as Map).cast<String, dynamic>()))
//         .where((b) => b.isActive && b.imageUrl.isNotEmpty)
//         .toList();
//
//     return banners;
//   }
//
//   // Future<List<BannerModel>> _fetchBanners() async {
//   //   // ✅ GET {{base_url}}/banners/:type
//   //   final res = await _dio.get('/banners/${widget.type}');
//   //
//   //   final data = res.data;
//   //
//   //   // supports both: List response OR {data:[...]} response
//   //   final List list = (data is List) ? data : (data?['data'] as List? ?? []);
//   //
//   //   final banners = list
//   //       .map((e) => BannerModel.fromJson((e as Map).cast<String, dynamic>()))
//   //       .where((b) => b.isActive && b.imageUrl.isNotEmpty)
//   //       .toList();
//   //
//   //   return banners;
//   // }
//
//   void _retry() {
//     setState(() {
//       _future = _fetchBanners();
//     });
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<BannerModel>>(
//       future: _future,
//       builder: (context, snapshot) {
//         // ✅ Loading
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Skeletonizer(
//             enabled: true,
//             child: Container(
//               height: 150.h,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(16.r),
//               ),
//             ),
//           );
//         }
//
//         // ✅ Error
//         if (snapshot.hasError) {
//           return Container(
//             height: 150.h,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(16.r),
//               border: Border.all(color: Colors.black12),
//             ),
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.wifi_off, color: Colors.red, size: 28.sp),
//                   SizedBox(height: 8.h),
//                   Text(
//                     'Failed to load banners',
//                     style: TextStyle(fontSize: 13.sp),
//                   ),
//                   SizedBox(height: 10.h),
//                   ElevatedButton(
//                     onPressed: _retry,
//                     child: const Text('Try Again'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         final banners = snapshot.data ?? [];
//
//         // ✅ Empty
//         if (banners.isEmpty) {
//           return const SizedBox.shrink();
//         }
//
//         // ✅ Success UI
//         return Column(
//           children: [
//             SizedBox(
//               height: 150.h,
//               width: double.infinity,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16.r),
//                 child: PageView.builder(
//                   controller: _pageController,
//                   itemCount: banners.length,
//                   onPageChanged: (i) => setState(() => currentIndex = i),
//                   itemBuilder: (context, index) {
//                     final b = banners[index];
//                     return CachedNetworkImage(
//                       imageUrl: b.imageUrl,
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => Skeletonizer(
//                         enabled: true,
//                         child: Container(color: Colors.grey[300]),
//                       ),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[200],
//                         alignment: Alignment.center,
//                         child: Icon(Icons.broken_image, size: 28.sp, color: Colors.grey[600]),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             SizedBox(height: 8.h),
//
//             // ✅ Dots
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(banners.length, (i) {
//                 final isActive = i == currentIndex;
//                 return AnimatedContainer(
//                   duration: const Duration(milliseconds: 250),
//                   margin: EdgeInsets.symmetric(horizontal: 3.w),
//                   height: 6.h,
//                   width: isActive ? 18.w : 6.w,
//                   decoration: BoxDecoration(
//                     color: isActive ? Colors.black87 : Colors.black26,
//                     borderRadius: BorderRadius.circular(50.r),
//                   ),
//                 );
//               }),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'banner.dart';
import 'core/api/end_points.dart';
import 'core/cache/secure_cache_storage.dart';
import 'core/services/service_locator.dart';

class InlineHeroBanners extends StatefulWidget {
  const InlineHeroBanners({super.key, required this.type});

  /// type = hero | sidebar | hot_deals
  final String type;

  @override
  State<InlineHeroBanners> createState() => _InlineHeroBannersState();
}

class _InlineHeroBannersState extends State<InlineHeroBanners> {
  late Future<List<BannerModel>> _future;
  final PageController _pageController = PageController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = _fetchBanners(); // ✅ initialize once
  }

  Future<List<BannerModel>> _fetchBanners() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');

    final dio = Dio(
      BaseOptions(
        baseUrl: EndPoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ),
    );

    try {
      // ✅ GET {{base_url}}/banners/:type
      final res = await dio.get('/banners/${widget.type}');
      final data = res.data;

      // supports both: List response OR {data:[...]} response
      final List list = (data is List) ? data : (data?['data'] as List? ?? []);

      final banners = list
          .map((e) => BannerModel.fromJson((e as Map).cast<String, dynamic>()))
          .where((b) => b.isActive && b.imageUrl.isNotEmpty)
          .toList();

      return banners;
    } on DioException catch (error) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: _future,
      builder: (context, snapshot) {
        // ✅ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Skeletonizer(
            enabled: true,
            child: Container(
              height: 150.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          );
        }

        // ✅ Error
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];

        // ✅ Empty
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        // Keep currentIndex in range if banners length changes after retry/hot reload
        if (currentIndex >= banners.length) {
          currentIndex = 0;
        }

        // ✅ Success UI
        return Column(
          children: [
            SizedBox(
              height: 150.h,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (i) {
                    if (!mounted) return;
                    setState(() => currentIndex = i);
                  },
                  itemBuilder: (context, index) {
                    final b = banners[index];
                    return CachedNetworkImage(
                      imageUrl: b.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Skeletonizer(
                        enabled: true,
                        child: Container(color: Colors.grey[300]),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image,
                          size: 28.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // ✅ Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                final isActive = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  height: 6.h,
                  width: isActive ? 18.w : 6.w,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black87 : Colors.black26,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
