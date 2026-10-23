import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/services/cart_fly_to_badge_anchor.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.wishlistCount = 0,
    this.cartCount = 0,
    this.enableCartBadgeAnchor = true,
  });

  final ValueChanged<int> onTap;
  final int currentIndex;
  final int wishlistCount;
  final int cartCount;
  final bool enableCartBadgeAnchor;

  static const Color _inactiveItemColor = Color(0x99000000);
  static const Color _activeItemColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);
    final items = <_NavItemData>[
      _NavItemData(
        label: localized.home,
        inactiveIconPath: 'assets/images/home.png',
        activeIconPath: 'assets/images/icons/bottom_nav_home.svg',
      ),
      _NavItemData(
        label: localized.category_label,
        inactiveIconPath: 'assets/images/category.png',
        activeIconPath: 'assets/images/icons/bottom_nav_category.svg',
      ),
      _NavItemData(
        label: localized.favorites,
        inactiveIconPath: 'assets/images/heart.png',
        activeIconPath: 'assets/images/icons/bottom_nav_heart.svg',
      ),
      _NavItemData(
        label: localized.cart,
        inactiveIconPath: 'assets/images/cart.png',
        activeIconPath: 'assets/images/icons/bottom_nav_bag.svg',
      ),
      _NavItemData(
        label: localized.profile,
        inactiveIconPath: 'assets/images/profile.png',
        activeIconPath: 'assets/images/icons/bottom_nav_profile.svg',
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 92.h,
        padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 6.h),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return Expanded(
              child: AppTapFeedback(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(18.r),
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        KeyedSubtree(
                          key: enableCartBadgeAnchor && index == 3
                              ? CartFlyToBadgeAnchor.cartBadgeKey
                              : null,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              isSelected
                                  ? SvgPicture.asset(
                                      item.activeIconPath,
                                      width: 25.w,
                                      height: 25.w,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.asset(
                                      item.inactiveIconPath,
                                      width: 25.w,
                                      height: 25.w,
                                      fit: BoxFit.contain,
                                      color: _inactiveItemColor,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                              if (_countForIndex(index) > 0)
                                Positioned(
                                  right: -8.w,
                                  top: -6.h,
                                  child: _CountBadge(
                                    count: _countForIndex(index),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 9.h),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.styleFilterChip12Medium(context).copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: isSelected
                            ? _activeItemColor
                            : _inactiveItemColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  int _countForIndex(int index) {
    if (index == 2) return wishlistCount;
    if (index == 3) return cartCount;
    return 0;
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.inactiveIconPath,
    required this.activeIconPath,
  });

  final String label;
  final String inactiveIconPath;
  final String activeIconPath;
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final display = count > 99
        ? '${formatLocalizedNumber(context, 99)}+'
        : formatLocalizedNumber(context, count);
    final horizontal = count > 9 ? 5.0 : 6.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE60000),
        borderRadius: BorderRadius.circular(10.r),
      ),
      constraints: BoxConstraints(minWidth: 14.w, minHeight: 14.h),
      child: Text(
        display,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
