import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CheckoutHeader extends StatelessWidget {
  const CheckoutHeader({
    super.key,
    this.showNotification = false,
    this.onBackPressed,
    this.onNotificationTap,
  });

  final bool showNotification;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            IconButton(
              onPressed:
                  onBackPressed ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    AppNavigator.rememberCartBackTarget(context);
                    GoRouter.of(
                      context,
                    ).go(AppRouter.selectingFromBottomNavBarCartTab);
                  },
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: 28.w, height: 28.h),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                S.of(context).checkout,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montes',
                  height: 40 / 20,
                ),
              ),
            ),
            if (showNotification)
              NotificationBellWithBadge(
                onTap:
                    onNotificationTap ??
                    () => AppNavigator.openNotificationsOrLogin(context),
                borderRadius: BorderRadius.circular(20.r),
              ),
          ],
        ),
      ),
    );
  }
}

class CheckoutStepper extends StatelessWidget {
  const CheckoutStepper({super.key, required this.currentStep, this.onStepTap});

  final int currentStep;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final activeStep = currentStep.clamp(0, 1);
    return Row(
      children: List.generate(2, (index) {
        final isActive = index == activeStep;
        return Expanded(
          child: AppTapFeedback(
            onTap: onStepTap == null ? null : () => onStepTap!(index),
            borderRadius: BorderRadius.circular(999.r),
            child: Container(
              margin: EdgeInsets.only(right: index == 1 ? 0 : 8.w),
              height: 5.h,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD72631)
                    : const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
        );
      }),
    );
  }
}
