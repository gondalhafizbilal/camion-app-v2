import 'package:camion/config/widgets/custom_cached_network_image.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class ProductWishList extends StatefulWidget {
  const ProductWishList({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.removeFromWishList,
    required this.onSelectionChanged,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  static const double cardWidth = 165;
  static const double cardHeight = 324;
  static const double imageHeight = 230;

  final VoidCallback removeFromWishList;
  final String imageUrl;
  final String title;
  final String price;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool> onSelectionChanged;

  @override
  State<ProductWishList> createState() => _ProductWishListState();
}

class _ProductWishListState extends State<ProductWishList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant ProductWishList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _scaleAnimation.value : 1.0,
          child: Container(
            width: ProductWishList.cardWidth.w,
            height: ProductWishList.cardHeight.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5.r),
              border: widget.isSelected
                  ? Border.all(color: AppColors.primaryColor, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? AppColors.primaryColor.withAlpha(20)
                      : const Color(0x26000000),
                  blurRadius: widget.isSelected ? 18 : 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: ProductWishList.imageHeight.h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFE7E7E7),
                                width: 1.w,
                              ),
                              left: BorderSide(
                                color: const Color(0xFFE7E7E7),
                                width: 1.w,
                              ),
                              right: BorderSide(
                                color: const Color(0xFFE7E7E7),
                                width: 1.w,
                              ),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5.r),
                              topRight: Radius.circular(5.r),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5.r),
                              topRight: Radius.circular(5.r),
                            ),
                            child: widget.imageUrl.isEmpty
                                ? Image.asset(
                                    Assets.imagesShoes,
                                    fit: BoxFit.cover,
                                  )
                                : CustomCachedNetworkImage(
                                    imageUrl: widget.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: InkWell(
                            onTap: widget.removeFromWishList,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD9DCDD),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.imagesIconsNewwwActiveHeart,
                                  width: 14.w,
                                  height: 14.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.isSelectionMode)
                          Positioned(
                            top: 8.h,
                            left: 8.w,
                            child: GestureDetector(
                              onTap: () =>
                                  widget.onSelectionChanged(!widget.isSelected),
                              child: Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? AppColors.primaryColor
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.isSelected
                                        ? AppColors.primaryColor
                                        : const Color(0xFFD0D5DD),
                                  ),
                                ),
                                child: widget.isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14.sp,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        if (widget.isSelected)
                          Positioned.fill(
                            child: Container(
                              color: AppColors.primaryColor.withAlpha(30),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.isSelected
                                ? AppColors.primaryColor
                                : AppColors.black,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montes',
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isSelectionMode && widget.isSelected
                                ? AppColors.primaryColor.withAlpha(24)
                                : const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Text(
                            widget.isSelectionMode && widget.isSelected
                                ? (Localizations.localeOf(context).languageCode == 'ar' ? 'محدد' : 'Selected')
                                : (Localizations.localeOf(context).languageCode == 'ar' ? 'عنصر محفوظ' : 'Saved item'),
                            style: TextStyle(
                              color: widget.isSelectionMode && widget.isSelected
                                  ? AppColors.primaryColor
                                  : const Color(0xFF667085),
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montes',
                              height: 1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.styleBold16(context).copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
