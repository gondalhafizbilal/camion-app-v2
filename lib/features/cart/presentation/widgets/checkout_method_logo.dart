import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum CheckoutMethodLogoType { payment, shipping }

class CheckoutMethodLogoBox extends StatelessWidget {
  const CheckoutMethodLogoBox({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    this.width,
    this.height,
  });

  final String id;
  final String title;
  final CheckoutMethodLogoType type;
  final double? width;
  final double? height;

  static const String mastercardAsset =
      'assets/images/icons/logos_mastercard.svg';
  static const String visaAsset = 'assets/images/visa.svg';
  static const String appleAsset = 'assets/images/apple_icon.svg';
  static const String googleAsset = 'assets/images/google_icon.svg';
  static const String fourPxAsset = 'assets/images/icons/logo_4px.png';
  static const String codAsset = 'assets/images/icons/cod.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 64.w,
      height: height ?? 34.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final normalizedId = id.trim().toLowerCase();
    if (type == CheckoutMethodLogoType.shipping ||
        normalizedId.contains('4px') ||
        normalizedId.contains('4x')) {
      return Image.asset(fourPxAsset, fit: BoxFit.contain);
    }

    switch (normalizedId) {
      case 'mastercard':
      case 'master_card':
      case 'mc':
        return SvgPicture.asset(mastercardAsset, fit: BoxFit.contain);
      case 'visa':
      case 'visa_card':
        return SvgPicture.asset(visaAsset, fit: BoxFit.contain);
      case 'amex':
      case 'american_express':
        return Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2E77BC),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: Text(
            'AMEX',
            style: AppStyle.styleBold12(
              context,
            ).copyWith(color: Colors.white, fontSize: 10.sp),
          ),
        );
      case 'apple_pay':
      case 'applepay':
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(appleAsset, width: 14.w, height: 14.w),
            SizedBox(width: 3.w),
            Text(
              'Pay',
              style: AppStyle.styleBold12(
                context,
              ).copyWith(color: Colors.black, fontSize: 12.sp),
            ),
          ],
        );
      case 'cod':
      case 'cash_on_delivery':
        return Image.asset(codAsset, fit: BoxFit.contain);
      case 'google_pay':
      case 'googlepay':
      case 'gpay':
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(googleAsset, width: 14.w, height: 14.w),
            SizedBox(width: 3.w),
            Text(
              'Pay',
              style: AppStyle.styleBold12(
                context,
              ).copyWith(color: Colors.black, fontSize: 12.sp),
            ),
          ],
        );
      default:
        return Text(
          _fallbackLabel,
          textAlign: TextAlign.center,
          style: AppStyle.styleBold12(
            context,
          ).copyWith(color: Colors.black, fontSize: 10.sp),
        );
    }
  }

  String get _fallbackLabel {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase());
    final label = words.join();
    return label.isEmpty ? 'CARD' : label;
  }
}
