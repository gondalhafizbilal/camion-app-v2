import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DiscountPercentageBadge extends StatelessWidget {
  const DiscountPercentageBadge({
    super.key,
    required this.percentage,
    this.compact = false,
  });

  final int percentage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7.w : 9.w,
        vertical: compact ? 3.h : 4.h,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A1016), Color(0xFFD72631), Color(0xFFEF5350)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 7.r : 9.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A7A1016),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '-${formatLocalizedPercent(context, percentage)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9.sp : 10.sp,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
