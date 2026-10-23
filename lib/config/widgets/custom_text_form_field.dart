import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppInputFieldSpec {
  static double get height => 40.h;
  static double get radius => 5.r;
  static double get horizontalPadding => 24.w;
  static double get verticalPadding => 8.h;
  static double get borderWidth => 1.w;

  static InputDecoration decoration(
    BuildContext context, {
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    bool filled = false,
    bool showBorder = true,
    OutlineInputBorder? focusedBorder,
    bool isSingleLine = true,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Colors.grey.shade300, width: borderWidth),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: AppStyle.styleInputField14Regular(
        context,
      ).copyWith(color: AppColors.gray),
      isDense: true,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: fillColor,
      constraints: isSingleLine ? BoxConstraints(minHeight: height) : null,
      contentPadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isSingleLine ? verticalPadding : 12.h,
        horizontalPadding,
        isSingleLine ? verticalPadding : 12.h,
      ),
      errorMaxLines: 3,
      errorStyle: AppStyle.styleInputField14Regular(
        context,
      ).copyWith(color: Colors.red, height: 1.4),
      border: showBorder ? baseBorder : InputBorder.none,
      enabledBorder: showBorder ? baseBorder : InputBorder.none,
      focusedBorder: showBorder
          ? (focusedBorder ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: borderWidth,
                  ),
                ))
          : InputBorder.none,
      errorBorder: showBorder
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: Colors.red, width: borderWidth),
            )
          : InputBorder.none,
      focusedErrorBorder: showBorder
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: Colors.red, width: borderWidth),
            )
          : InputBorder.none,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final Color? fieldColor;
  final TextEditingController? controller;
  final String? hintText;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final Widget? prefixIcon;
  final FormFieldValidator<String>? validator;
  final bool? readOnly;
  final int? maxLength;
  final int? maxLines;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool? autoFocus;
  final OutlineInputBorder? focusedBorder;
  final bool? enabled;
  final String? initialValue;
  final TextInputType? keyboardType;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final TextAlign? textAlign;
  final TextStyle? style;
  final bool showBorder;
  final List<TextInputFormatter>? inputFormatters;
  final double? height;
  const CustomTextFormField({
    super.key,
    this.fieldColor,
    this.hintText,
    this.focusNode,
    this.suffixIcon,
    this.validator,
    this.controller,
    this.readOnly,
    this.onChanged,
    this.prefixIcon,
    this.maxLength,
    this.maxLines,
    this.onTap,
    this.autoFocus,
    this.focusedBorder,
    this.enabled,
    this.initialValue,
    this.keyboardType,
    this.onFieldSubmitted,
    this.textInputAction,
    this.textAlign,
    this.style,
    this.showBorder = true,
    this.inputFormatters,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isSingleLine = (maxLines ?? 1) == 1;

    return TextFormField(
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      initialValue: initialValue,
      maxLength: maxLength,
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
      maxLines: maxLines,
      enabled: enabled,
      autofocus: autoFocus ?? false,
      onChanged: onChanged,
      style:
          style ??
          AppStyle.styleInputField14Regular(
            context,
          ).copyWith(color: AppColors.black),
      textAlign: textAlign ?? TextAlign.start,
      onTap: onTap,
      readOnly: readOnly ?? false,
      controller: controller,
      validator: validator,
      decoration: AppInputFieldSpec.decoration(
        context,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: fieldColor != null,
        fillColor: fieldColor,
        showBorder: showBorder,
        focusedBorder: focusedBorder,
        isSingleLine: isSingleLine,
      ),
    );
  }
}
