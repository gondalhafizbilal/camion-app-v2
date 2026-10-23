import 'package:camion/features/join_us/presentation/widgets/coupon_form.dart';
import 'package:camion/features/join_us/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateCodeScreen extends StatelessWidget {
  const CreateCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          CustomJoinUsSliverAppBar(title: S.of(context).create_coupon),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                28.h,
                16.w,
                24.h + keyboardBottomInset + 12.h,
              ),
              child: const CouponForm(),
            ),
          ),
        ],
      ),
    );
  }
}
