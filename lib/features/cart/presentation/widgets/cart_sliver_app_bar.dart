import 'package:camion/config/widgets/section_top_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartSliverAppBar extends StatelessWidget {
  const CartSliverAppBar({super.key, required this.title, this.onBackPressed});

  final String title;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: SectionTopHeader(title: title, onBackPressed: onBackPressed),
      ),
    );
  }
}
