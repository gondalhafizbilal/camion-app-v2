import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomRadio extends StatelessWidget {
  final bool isSelected;

  const CustomRadio({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFFD7262E) : Colors.transparent,
        border: Border.all(
          color: isSelected ? const Color(0xFFD7262E) : const Color(0xFFD9D9D9),
          width: 1.5.w,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check_rounded, color: Colors.white, size: 16.r)
          : null,
    );
  }
}
