import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileDesignSystem {
  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFD9DEE5);
  static const Color cardText = Color(0xFF20242C);
  static const Color accent = Color(0xFFD61F29);
  static const double maxCardWidth = 343;
  static const double cardHeight = 40;
  static const double cardRadius = 5;
  static const double cardBorderWidth = 1;
  static const double horizontalPadding = 24;
  static const double verticalPadding = 8;
  static const double cardGap = 8;
  static const double sectionSpacing = 12;
  static const double bottomSafeSpacing = 120;

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius.r),
    border: Border.all(color: cardBorder, width: cardBorderWidth),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF101828).withAlpha(10),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class ProfileCardFrame extends StatelessWidget {
  const ProfileCardFrame({
    super.key,
    required this.child,
    this.height = ProfileDesignSystem.cardHeight,
    this.padding,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ProfileDesignSystem.maxCardWidth.w,
        ),
        child: Container(
          height: height.h,
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: ProfileDesignSystem.horizontalPadding.w,
                vertical: ProfileDesignSystem.verticalPadding.h,
              ),
          decoration: ProfileDesignSystem.cardDecoration,
          child: child,
        ),
      ),
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.start,
        style: AppStyle.styleProfileSectionTitle16SemiBold(context),
      ),
    );
  }
}
