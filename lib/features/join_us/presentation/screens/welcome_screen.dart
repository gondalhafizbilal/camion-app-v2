import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/features/join_us/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          CustomJoinUsSliverAppBar(title: S.of(context).join_us_as_affiliate),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).affiliate_welcome_message,
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w400,
                      height: 24 / 20,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    S.of(context).affiliate_welcome_subtitle,
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: Colors.black.withValues(alpha: 0.88),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  CustomElevatedButton(
                    onPressed: () => GoRouter.of(context).push(AppRouter.joinUs),
                    elevation: 0,
                    child: Text(S.of(context).start_now),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
