import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final sanitizedUrls = _sanitizedUrls;
    _currentIndex = sanitizedUrls.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, sanitizedUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _sanitizedUrls =>
      widget.imageUrls.map((url) => url.trim()).where((url) => url.isNotEmpty).toList(growable: false);

  Widget _thumbnail(String url, {required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 68.w,
      height: 68.w,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive ? const Color(0xFFCB262E) : const Color(0xFFE1E1E1),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9.r),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Image.asset(
            Assets.imagesShoes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _sanitizedUrls;
    if (urls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: IconButton(
            onPressed: () => GoRouter.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PhotoViewGallery.builder(
                    pageController: _pageController,
                    itemCount: urls.length,
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    builder: (context, index) {
                      final imageUrl = urls[index];
                      return PhotoViewGalleryPageOptions(
                        imageProvider: CachedNetworkImageProvider(imageUrl),
                        heroAttributes: PhotoViewHeroAttributes(
                          tag: 'full_screen_image_$index',
                        ),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 3,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.error, color: Colors.white, size: 50),
                        ),
                      );
                    },
                    loadingBuilder: (context, event) => Skeletonizer(
                      enabled: true,
                      child: SizedBox(
                        height: 400.h,
                        width: double.infinity,
                        child: Image.asset(
                          Assets.imagesShoes,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                  color: Colors.black,
                  child: SizedBox(
                    height: 72.w,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: urls.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        final url = urls[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          },
                          child: _thumbnail(url, isActive: index == _currentIndex),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12.h,
              left: 12.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: IconButton(
                  onPressed: () => GoRouter.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
