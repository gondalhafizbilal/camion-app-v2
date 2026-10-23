import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionTopHeader extends StatelessWidget {
  const SectionTopHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onSearchTap,
    this.onNotificationTap,
    this.searchActionIcon,
    this.titleTextAlign = TextAlign.start,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final Widget? searchActionIcon;
  final TextAlign titleTextAlign;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBackPressed != null) ...[
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: AppTapFeedback(
              onTap: onBackPressed,
              customBorder: const CircleBorder(),
              child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
            ),
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Text(
            title,
            textAlign: titleTextAlign,
            style: AppStyle.styleAppBarTitle20Medium(context),
          ),
        ),
        _HeaderAction(
          onTap: onSearchTap ?? () => openRecentSearchSheet(context),
          child:
              searchActionIcon ??
              Image.asset(
                'assets/images/searchicon.png',
                width: 40.w,
                height: 40.h,
                fit: BoxFit.contain,
              ),
        ),
        SizedBox(width: 18.w),
        _HeaderAction(
          onTap:
              onNotificationTap ??
              () => AppNavigator.openNotificationsOrLogin(context),
          child: NotificationBellWithBadge(onTap: onNotificationTap),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: SizedBox(
        width: 40.w,
        height: 40.h,
        child: AppTapFeedback(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: child,
        ),
      ),
    );
  }
}
