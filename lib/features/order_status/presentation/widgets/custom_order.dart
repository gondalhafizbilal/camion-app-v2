import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/features/order_status/utils/order_status_utils.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CustomOrder extends StatelessWidget {
  const CustomOrder({
    super.key,
    required this.totalPrice,
    required this.numberOfProducts,
    required this.date,
    required this.orderStatus,
    required this.numberOfRequest,
    required this.onTapOnOrderDetails,
    required this.orderId,
    required this.currencyCode,
    required this.orderTitle,
    required this.orderImage,
    required this.productId,
    this.variantTitle,
    this.canCancelOrder = false,
    this.isCanceling = false,
    this.onCancelOrder,
    this.paymentMethod = '',
    this.deliveryEta = '',
  });

  final String numberOfRequest;
  final String totalPrice;
  final int numberOfProducts;
  final DateTime date;
  final String orderStatus;
  final VoidCallback onTapOnOrderDetails;
  final String orderId;
  final String currencyCode;
  final String orderTitle;
  final String orderImage;
  final String productId;
  final String? variantTitle;
  final bool canCancelOrder;
  final bool isCanceling;
  final VoidCallback? onCancelOrder;
  final String paymentMethod;
  final String deliveryEta;

  String _formatDate(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final localDate = date.toLocal();
    return DateFormat(
      'MMMM dd, yyyy hh:mm a',
      locale,
    ).format(localDate).replaceAll('ص', 'صباحاً').replaceAll('م', 'مساءً');
  }

  String _formatDeliveryEta(BuildContext context) {
    final raw = deliveryEta.trim();
    if (raw.isEmpty) return _formatDate(context);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final locale = Localizations.localeOf(context).languageCode;
    final localDate = parsed.toLocal();
    return DateFormat(
      'MMMM dd, yyyy hh:mm a',
      locale,
    ).format(localDate).replaceAll('ص', 'صباحاً').replaceAll('م', 'مساءً');
  }

  String _statusLabel(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return orderStatusLabelByLocale(orderStatus, isArabic: isArabic);
  }

  Color get _statusBackgroundColor {
    switch (orderStatusFromRaw(orderStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.returned:
        return const Color(0xFFE3FFD5);
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFFEAF1FF);
      case OrderStatus.returnRequested:
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return const Color(0xFFFFF2D9);
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return const Color(0xFFFFE8E8);
    }
  }

  Color get _statusTextColor {
    switch (orderStatusFromRaw(orderStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.returned:
        return const Color(0xFF3D743A);
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFF24419B);
      case OrderStatus.returnRequested:
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return const Color(0xFF9A6700);
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return const Color(0xFFB42318);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final displayCurrencyCode = resolveCurrencyCode([currencyCode]);
    final localizedProductCount = formatLocalizedNumber(
      context,
      numberOfProducts.toString().padLeft(3, '0'),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${isArabic ? 'طلب' : 'Order'} #$numberOfRequest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.styleSectionTitle16Medium(context).copyWith(
                    color: AppColors.deepDark,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                constraints: BoxConstraints(minWidth: 100.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  _statusLabel(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppStyle.styleFilterChip12Medium(context).copyWith(
                    color: _statusTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.19,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          RichText(
            text: TextSpan(
              text: isArabic ? 'تاريخ الطلب: ' : 'Order Date: ',
              style: AppStyle.styleRegular12(context).copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
              ),
              children: [
                TextSpan(
                  text: _formatDate(context),
                  style: AppStyle.styleRegular12(context).copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          RichText(
            text: TextSpan(
              text: isArabic ? 'التوصيل المتوقع: ' : 'Estimated Delivery: ',
              style: AppStyle.styleRegular12(context).copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
              ),
              children: [
                TextSpan(
                  text: _formatDeliveryEta(context),
                  style: AppStyle.styleRegular12(context).copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          if (paymentMethod.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            RichText(
              text: TextSpan(
                text: isArabic ? 'طريقة الدفع: ' : 'Payment Method: ',
                style: AppStyle.styleRegular12(context).copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                  height: 18 / 12,
                ),
                children: [
                  TextSpan(
                    text: paymentMethod.trim(),
                    style: AppStyle.styleRegular12(context).copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _OrderMetric(
                  label: isArabic ? 'عدد المنتجات' : 'Number Of Products',
                  value: localizedProductCount,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _OrderMetric(
                  label: S.of(context).total,
                  value: formatMoneyForDisplay(
                    context,
                    totalPrice,
                    displayCurrencyCode,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  backgroundColor: canCancelOrder
                      ? AppColors.red
                      : AppColors.primaryColor,
                  elevation: 0,
                  height: 44.h,
                  onPressed: canCancelOrder
                      ? onCancelOrder
                      : () {
                          GoRouter.of(context).push(
                            AppRouter.orderTrackingWebPage,
                            extra: {
                              'orderId': orderId,
                              'orderNumber': numberOfRequest,
                              'productTitle': orderTitle,
                              'variantTitle': variantTitle,
                              'productImage': orderImage,
                              'productId': productId,
                            },
                          );
                        },
                  isEnabled: !isCanceling,
                  child: Text(
                    canCancelOrder
                        ? (isArabic ? 'إلغاء الطلب' : 'Cancel Order')
                        : (isArabic ? 'تتبع' : 'Track'),
                    style: AppStyle.styleSectionTitle16Medium(context).copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomElevatedButton(
                  backgroundColor: AppColors.primaryColor,
                  elevation: 0,
                  height: 44.h,
                  onPressed: onTapOnOrderDetails,
                  child: Text(
                    isArabic ? 'التفاصيل' : 'Details',
                    style: AppStyle.styleSectionTitle16Medium(context).copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyle.styleFilterChip12Medium(context).copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w500,
            height: 18 / 12,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyle.styleSectionTitle16Medium(context).copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}
