import 'dart:async';

import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/features/cart/presentation/widgets/checkout_flow_widgets.dart';
import 'package:camion/features/cart/presentation/widgets/checkout_method_logo.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CheckoutPaymentMethodScreen extends StatefulWidget {
  const CheckoutPaymentMethodScreen({super.key, this.checkoutPayload});

  final Map<String, dynamic>? checkoutPayload;

  @override
  State<CheckoutPaymentMethodScreen> createState() =>
      _CheckoutPaymentMethodScreenState();
}

class _CheckoutPaymentMethodScreenState
    extends State<CheckoutPaymentMethodScreen> {
  late final List<_CheckoutPaymentMethodOption> _methods;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _methods = const [
      _CheckoutPaymentMethodOption(id: 'mastercard', title: 'Master Card'),
      _CheckoutPaymentMethodOption(id: 'visa', title: 'Visa Card'),
      _CheckoutPaymentMethodOption(id: 'amex', title: 'American Express Card'),
      _CheckoutPaymentMethodOption(id: 'apple_pay', title: 'Apple Pay'),
      _CheckoutPaymentMethodOption(id: 'google_pay', title: 'Google Pay'),
      _CheckoutPaymentMethodOption(
        id: 'cod',
        title: 'Cash On Delivery',
        isDisabled: true,
      ),
    ];

    final selectedId = _normalizedPaymentId(
      widget.checkoutPayload?['selectedPaymentMethod']?['id']?.toString(),
    );
    final matchedIndex = _methods.indexWhere(
      (method) => method.id == selectedId && !method.isDisabled,
    );
    if (matchedIndex >= 0) {
      _selectedIndex = matchedIndex;
    }
  }

  String _normalizedPaymentId(String? rawId) {
    final id = (rawId ?? '').trim().toLowerCase();
    if (id.isEmpty) return '';
    switch (id) {
      case 'master_card':
      case 'mc':
        return 'mastercard';
      case 'visa_card':
        return 'visa';
      case 'american_express':
        return 'amex';
      case 'applepay':
        return 'apple_pay';
      case 'googlepay':
      case 'gpay':
        return 'google_pay';
      default:
        return id;
    }
  }

  TextStyle _sectionHeadingStyle() {
    return TextStyle(
      fontFamily: 'Montes',
      fontWeight: FontWeight.w400,
      fontSize: 20.sp,
      height: 24 / 20,
      color: Colors.black,
    );
  }

  void _continue() {
    final selectedIndex = _selectedIndex;
    if (selectedIndex == null) {
      AppToast.show(
        msg: 'Please select a payment method.',
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    final selectedMethod = _methods[selectedIndex];
    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        'add_payment_info',
        eventParams: {
          'payment_method': selectedMethod.id,
          'cart_value': widget.checkoutPayload?['total'] ?? 0,
          if ((widget.checkoutPayload?['couponCode'] ?? '')
              .toString()
              .trim()
              .isNotEmpty)
            'coupon': widget.checkoutPayload!['couponCode'].toString().trim(),
        },
      ),
    );
    final payload = <String, dynamic>{
      ...?widget.checkoutPayload,
      'selectedPaymentMethod': selectedMethod.toJson(),
    };

    GoRouter.of(context).push(AppRouter.confirmPayment, extra: payload);
  }

  void _handleStepTap(int step) {
    if (step == 0) {
      GoRouter.of(context).push(
        AppRouter.confirmShippingAddressScreen,
        extra: {
          ...?widget.checkoutPayload,
          if (_selectedIndex case final selectedIndex?)
            'selectedPaymentMethod': _methods[selectedIndex].toJson(),
        },
      );
      return;
    }
    if (step == 1) return;
    _continue();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 45.h)),
                const CheckoutHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 12.h),
                    child: CheckoutStepper(
                      currentStep: 1,
                      onStepTap: _handleStepTap,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        Text(s.payment_method, style: _sectionHeadingStyle()),
                        SizedBox(height: 16.h),
                        Text(
                          s.payment_method_checkout_description,
                          style: AppStyle.styleRegular15(context).copyWith(
                            color: Colors.black87,
                            fontSize: 16.sp,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        ...List.generate(_methods.length, (index) {
                          final method = _methods[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _PaymentMethodCard(
                              method: method,
                              isSelected: _selectedIndex == index,
                              onTap: () {
                                if (method.isDisabled) return;
                                setState(() {
                                  _selectedIndex = index;
                                });
                                unawaited(
                                  sl<AppsFlyerService>().logConversionEvent(
                                    'payment_method_selected',
                                    eventParams: {
                                      'payment_method': method.id,
                                      'cart_value':
                                          widget.checkoutPayload?['total'] ?? 0,
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
            child: CustomElevatedButton(
              onPressed: _continue,
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              child: Text(
                s.continuee,
                style: AppStyle.styleRegular15(context).copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final _CheckoutPaymentMethodOption method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = method.isDisabled;
    final titleColor = disabled ? Colors.black54 : Colors.black;
    final borderColor = disabled
        ? Colors.grey.shade300
        : isSelected
        ? AppColors.primaryColor
        : Colors.grey.shade300;
    final backgroundColor = disabled
        ? Colors.grey.shade50
        : isSelected
        ? AppColors.primaryColor.withAlpha(15)
        : Colors.white;

    return InkWell(
      onTap: disabled
          ? () {
              unawaited(
                sl<AppsFlyerService>().logConversionEvent(
                  'cod_interest_click',
                  eventParams: {
                    'source': 'checkout_payment_method',
                  },
                ),
              );
            }
          : onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        height: 40.h,
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: borderColor,
            width: isSelected && !disabled ? 1.2 : 1,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.7 : 1,
          child: Row(
            children: [
              _PaymentMethodBadge(method: method),
              SizedBox(width: 8.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: method.title,
                    style: AppStyle.styleRegular15(
                      context,
                    ).copyWith(color: titleColor, fontSize: 16.sp),
                    children: [
                      if (disabled)
                        TextSpan(
                          text: ' (${S.of(context).coming_soon})',
                          style: AppStyle.styleRegular15(context).copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: Directionality.of(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  const _PaymentMethodBadge({required this.method});

  final _CheckoutPaymentMethodOption method;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52.w,
      height: 24.h,
      child: CheckoutMethodLogoBox(
        id: method.id,
        title: method.title,
        type: CheckoutMethodLogoType.payment,
        width: 52.w,
        height: 24.h,
      ),
    );
  }
}

class _CheckoutPaymentMethodOption {
  const _CheckoutPaymentMethodOption({
    required this.id,
    required this.title,
    this.isDisabled = false,
  });

  final String id;
  final String title;
  final bool isDisabled;

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title};
  }
}
