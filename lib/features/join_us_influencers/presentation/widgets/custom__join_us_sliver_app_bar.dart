import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomJoinUsSliverAppBar extends StatelessWidget {
  const CustomJoinUsSliverAppBar({super.key, required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    return CustomSliverAppBar(
      appBarHeight: 50.h,
      actions: const [],
      centerTitle: false,
      title: Text(
        title,
        style: AppStyle.styleAppBarTitle20Medium(context),
      ),
      isShoppingCartShown: false,
      isShownActions: false,
    );
  }
}
