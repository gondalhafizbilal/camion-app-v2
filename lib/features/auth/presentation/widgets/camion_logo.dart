import 'package:camion/core/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CamionLogo extends StatelessWidget {
  const CamionLogo({
    super.key,
    this.imagePath = Assets.imagesCamionLogo,
    this.width,
    this.height,
  });

  final String imagePath;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width ?? 140.w,
      height: height ?? 105.h,
      fit: BoxFit.contain,
    );
  }
}
