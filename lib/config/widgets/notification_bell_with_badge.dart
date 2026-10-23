import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationBellWithBadge extends StatelessWidget {
  const NotificationBellWithBadge({
    super.key,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
    this.childPadding,
    this.iconColor,
  });

  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? childPadding;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? 40.w;
    final resolvedHeight = height ?? 40.h;
    return SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: AnimatedBuilder(
        animation: sl<DashboardBadgeCountsNotifier>(),
        builder: (context, _) {
          final count = sl<DashboardBadgeCountsNotifier>().notificationCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AppTapFeedback(
                  onTap:
                      onTap ??
                      () => AppNavigator.openNotificationsOrLogin(context),
                  borderRadius: borderRadius,
                  customBorder: borderRadius == null
                      ? const CircleBorder()
                      : null,
                  child: Padding(
                    padding: childPadding ?? EdgeInsets.zero,
                    child: Image.asset(
                      Assets.imagesNotificationNew,
                      width: resolvedWidth,
                      height: resolvedHeight,
                      fit: BoxFit.contain,
                      color: iconColor,
                      colorBlendMode: iconColor == null
                          ? null
                          : BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -4.h,
                  right: -4.w,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.h,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99
                          ? '${formatLocalizedNumber(context, 99)}+'
                          : formatLocalizedNumber(context, count),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montes',
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
