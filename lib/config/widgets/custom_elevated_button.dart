import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButtonTokens {
  static double get height => 50.h;
  static double get radius => 5.r;
  static const double borderWidth = 1.5;
  static double get verticalPadding => 4.h;
  static const double elevation = 4;
}

class CustomElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? verticalPadding;
  final double? horizontalPadding;
  final Widget? widget;
  final double? elevation;
  final double? height;
  final bool keepBackgroundWhenDisabled;
  const CustomElevatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.verticalPadding,
    this.horizontalPadding,
    this.widget,
    this.elevation,
    this.height,
    this.keepBackgroundWhenDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBordered = borderColor != null;
    final isDisabled = !isEnabled || onPressed == null;
    final resolvedOnPressed = isDisabled ? null : onPressed;
    final disabledBackground = keepBackgroundWhenDisabled
        ? (backgroundColor ?? const Color(0xFFB92123))
        : (isBordered ? (backgroundColor ?? Colors.white) : Colors.grey);
    final disabledForeground = keepBackgroundWhenDisabled
        ? (textColor ?? Colors.white)
        : Colors.white70;
    final resolvedBackgroundColor = isDisabled
        ? disabledBackground
        : (backgroundColor ?? const Color(0xFFB92123));
    final resolvedForegroundColor = isDisabled
        ? disabledForeground
        : (textColor ?? Colors.white);

    return SizedBox(
      width: double.infinity,
      height: height ?? AppButtonTokens.height,
      child: ElevatedButton(
        onPressed: resolvedOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedBackgroundColor,
          foregroundColor: resolvedForegroundColor,
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
          splashFactory: InkSparkle.splashFactory,
          overlayColor: resolvedForegroundColor.withAlpha(28),
          animationDuration: const Duration(milliseconds: 170),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding ?? AppButtonTokens.verticalPadding,
            horizontal: horizontalPadding ?? 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppButtonTokens.radius),
          ),
          side: borderColor == null
              ? null
              : BorderSide(
                  color: borderColor ?? Colors.transparent,
                  width: AppButtonTokens.borderWidth,
                ),
          elevation: elevation ?? AppButtonTokens.elevation,
        ),
        child: DefaultTextStyle.merge(
          style: AppStyle.styleButtonLabel14Regular(
            context,
          ).copyWith(color: resolvedForegroundColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget ?? Container(),

              widget != null ? SizedBox(width: 8.w) : Container(),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
