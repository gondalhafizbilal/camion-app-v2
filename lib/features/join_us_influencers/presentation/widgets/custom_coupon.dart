import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCoupon extends StatelessWidget {
  const CustomCoupon({
    super.key,
    required this.couponCode,
    required this.discountPercentage,
    required this.commissionText,
    this.createdAtText,
    this.expiresAtText,
    required this.isActive,
    this.onTap,
  });

  final String couponCode;
  final String discountPercentage;
  final String commissionText;
  final String? createdAtText;
  final String? expiresAtText;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            couponCode,
            style: AppStyle.styleSectionTitle16Medium(
              context,
            ).copyWith(color: AppColors.black, height: 24 / 16),
          ),
          if ((createdAtText != null && createdAtText!.trim().isNotEmpty) ||
              (expiresAtText != null && expiresAtText!.trim().isNotEmpty)) ...[
            SizedBox(height: 10.h),
            if (createdAtText != null && createdAtText!.trim().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isArabic ? 'تاريخ الإنشاء: ' : 'Created: ',
                      style: AppStyle.styleBold12(
                        context,
                      ).copyWith(color: AppColors.black, height: 18 / 12),
                    ),
                    TextSpan(
                      text: createdAtText!,
                      style: AppStyle.styleRegular12(
                        context,
                      ).copyWith(color: AppColors.black, height: 18 / 12),
                    ),
                  ],
                ),
              ),
            if (createdAtText != null &&
                createdAtText!.trim().isNotEmpty &&
                expiresAtText != null &&
                expiresAtText!.trim().isNotEmpty)
              SizedBox(height: 4.h),
            if (expiresAtText != null && expiresAtText!.trim().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isArabic ? 'تاريخ الانتهاء: ' : 'Expires: ',
                      style: AppStyle.styleBold12(
                        context,
                      ).copyWith(color: AppColors.black, height: 18 / 12),
                    ),
                    TextSpan(
                      text: expiresAtText!,
                      style: AppStyle.styleRegular12(
                        context,
                      ).copyWith(color: AppColors.black, height: 18 / 12),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 14.h),
          ] else
            SizedBox(height: 8.h),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: _CouponTag(
                  label: isActive
                      ? (isArabic ? 'نشط' : 'Active')
                      : (isArabic ? 'منتهي' : 'Expired'),
                  backgroundColor: isActive
                      ? const Color(0xFFE3FFD5)
                      : const Color(0xFFFFE1E1),
                  textColor: isActive
                      ? const Color(0xFF467E2E)
                      : const Color(0xFFB92123),
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                flex: 3,
                child: _CouponTag(
                  label:
                      '${isArabic ? 'الخصم' : 'Discount'} ${formatLocalizedPercent(context, discountPercentage, fractionDigits: 2)}',
                  backgroundColor: const Color(0xFFE3FFD5),
                  textColor: const Color(0xFF467E2E),
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                flex: 4,
                child: _CouponTag(
                  label:
                      '${isArabic ? 'العمولة' : 'Commission'} $commissionText',
                  backgroundColor: const Color(0xFFE3FFD5),
                  textColor: const Color(0xFF467E2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          CustomElevatedButton(
            onPressed: onTap,
            backgroundColor: AppColors.primaryColor,
            child: Text(
              isArabic ? 'عرض إحصائيات الكوبون' : 'View Coupon Statistics',
              style: AppStyle.styleSectionTitle16Medium(
                context,
              ).copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponTag extends StatelessWidget {
  const _CouponTag({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppStyle.styleFilterChip12Medium(
          context,
        ).copyWith(color: textColor, height: 1, letterSpacing: -0.19),
      ),
    );
  }
}
