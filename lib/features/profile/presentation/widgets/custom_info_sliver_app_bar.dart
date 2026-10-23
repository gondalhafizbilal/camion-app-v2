import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class CustomInfoSliverAppBar extends StatelessWidget {
  const CustomInfoSliverAppBar({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
  });
  final String fullName;
  final String email;
  final String phone;
  @override
  Widget build(BuildContext context) {
    return CustomSliverAppBar(
      appBarHeight: 50.h,
      leading: GestureDetector(
        onTap: () {
          AppNavigator.safePop(
            context,
            fallbackRoute: '${AppRouter.selectingFromBottomNavBar}?tab=4',
          );
        },
        child: Icon(Icons.arrow_back, color: AppColors.black, size: 24.sp),
      ),
      title: Text(
        S.of(context).personal_information,
        style: AppStyle.styleAppBarTitle20Medium(context),
      ),
      isShownDivider: false,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 10.w),
          child: AppTapFeedback(
            onTap: () {
              GoRouter.of(context).push(
                AppRouter.editInfo,
                extra: {'fullName': fullName, 'email': email, 'phone': phone},
              );
            },
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(
              width: 26.w,
              height: 26.h,
              Assets.imagesIconsEditInfo,
            ),
          ),
        ),
      ],
    );
  }
}
