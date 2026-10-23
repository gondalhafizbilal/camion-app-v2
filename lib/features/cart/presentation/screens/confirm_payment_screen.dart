// import 'dart:developer';
//
// import 'package:camion/config/widgets/custom_elevated_button.dart';
// import 'package:camion/config/widgets/custom_text_form_field.dart';
// import 'package:camion/core/utils/app_colors.dart';
// import 'package:camion/core/utils/app_style.dart';
// import 'package:camion/features/cart/data/models/get_cart_model.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/apply_coupon_cubit/apply_coupon_cubit.dart';
// import 'package:camion/features/cart/presentation/widgets/cart_sliver_app_bar.dart';
// import 'package:camion/features/cart/presentation/widgets/confirmation_products.dart';
// import 'package:camion/features/order_status/presentation/logic/cubit/create_order_cubit/create_order_cubit.dart';
// import 'package:camion/generated/l10n.dart';
// import 'package:camion/routing/app_router.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:camion/core/utils/app_toast.dart';
// import 'package:go_router/go_router.dart';
//
// class ConfirmPaymentScreen extends StatefulWidget {
//   const ConfirmPaymentScreen({super.key, required this.cartList});
//
//   final List<GetCartModel> cartList;
//
//   @override
//   State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
// }
//
// class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
//   final TextEditingController _couponController = TextEditingController();
//
//   @override
//   void dispose() {
//     _couponController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         slivers: [
//             CartSliverAppBar(title:  S.of(context).checkout),
//
//           SliverToBoxAdapter(child: SizedBox(height: 10.h)),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                      S.of(context).products,
//                     style: AppStyle.styleBold16(
//                       context,
//                     ).copyWith(color: AppColors.black),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       GoRouter.of(
//                         context,
//                       ).pushReplacementNamed(AppRouter.myCart);
//                     },
//                     child: Text(
//                        S.of(context).view_cart,
//                       style: AppStyle.styleRegular12(context).copyWith(
//                         color: AppColors.primaryColor,
//                         decoration: TextDecoration.underline,
//                         decorationColor: AppColors.primaryColor,
//                         decorationThickness: 1.5,
//                         height: 1.5,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           SliverToBoxAdapter(child: SizedBox(height: 20.h)),
//
//           // 🔹 عرض المنتجات
//           SliverToBoxAdapter(
//             child: SizedBox(
//               height: screenWidth > 800 ? 150.h : 100.h,
//               child: ListView.builder(
//                 clipBehavior: Clip.none,
//                 scrollDirection: Axis.horizontal,
//                 padding: EdgeInsets.symmetric(horizontal: 8.w),
//                 shrinkWrap: true,
//                 itemCount: widget.cartList.length,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8.w),
//                     child: ConfirmationsProductsItem(
//                       imageUrl: widget.cartList[index].image!,
//                       productName: widget.cartList[index].title!,
//                       price: widget.cartList[index].price!,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           SliverToBoxAdapter(child: SizedBox(height: 30.h)),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               child: GestureDetector(
//                 onTap: () {
//                   GoRouter.of(context).push(AppRouter.confirmShippingAddressScreen);
//                 },
//                 child: Text(
//
//                      S.of(context).Review_Your_Shipping_Address_Data,
//                   style: AppStyle.styleBold16(
//                     context,
//                   ).copyWith(
//                     decoration: TextDecoration.underline,
//                     decorationColor: AppColors.primaryColor,
//                     color: AppColors.primaryColor),
//                 ),
//               ),
//             ),
//           ),
//
//           SliverToBoxAdapter(child: SizedBox(height: 30.h)),
//
//           SliverPadding(
//             padding: EdgeInsets.symmetric(horizontal: 16.w),
//             sliver: SliverToBoxAdapter(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                      S.of(context).coupon_code,
//                     style: AppStyle.styleBold16(
//                       context,
//                     ).copyWith(color: AppColors.black),
//                   ),
//                   SizedBox(height: 30.h),
//                   Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: CustomTextFormField(
//                           controller: _couponController,
//                           hintText:  S.of(context).enter_your_coupon_code,
//                         ),
//                       ),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: SizedBox(
//                           height: 52.h,
//                           child:
//                               BlocConsumer<ApplyCouponCubit, ApplyCouponState>(
//                                 listener: (context, state) {
//                                   if (state is ApplyCouponSuccess) {
//                                     AppToast.show(
//                                       msg: S.of(context).Coupon_applied_successfully,
//                                       gravity: ToastGravity.TOP,
//                                       backgroundColor: Colors.green,
//                                       textColor: Colors.white,
//                                     );
//                                   }
//
//                                   if (state is ApplyCouponError) {
//                                     AppToast.show(
//                                       msg: state.error.message,
//                                       gravity: ToastGravity.TOP,
//                                       backgroundColor: Colors.red,
//                                       textColor: Colors.white,
//                                     );
//                                   }
//                                 },
//                                 builder: (context, state) {
//                                   return ElevatedButton(
//                                     onPressed: state is ApplyCouponLoading
//                                         ? () {}
//                                         : () {
//                                             if (_couponController
//                                                 .text
//                                                 .isNotEmpty) {
//                                               context
//                                                   .read<ApplyCouponCubit>()
//                                                   .applyCoupon(
//                                                     code:
//                                                         _couponController.text,
//                                                   );
//                                             }
//                                           },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: AppColors.white,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(
//                                           16.r,
//                                         ),
//                                         side: const BorderSide(
//                                           color: AppColors.primaryColor,
//                                           width: 1.5,
//                                         ),
//                                       ),
//                                     ),
//                                     child: state is ApplyCouponLoading
//                                         ? const CircularProgressIndicator(
//                                             color: AppColors.primaryColor,
//                                           )
//                                         : FittedBox(
//                                             child: Text(
//                                                S.of(context).confirm,
//                                               style:
//                                                   AppStyle.styleBold16(
//                                                     context,
//                                                   ).copyWith(
//                                                     color:
//                                                         AppColors.primaryColor,
//                                                   ),
//                                             ),
//                                           ),
//                                   );
//                                 },
//                               ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           SliverToBoxAdapter(child: SizedBox(height: 30.h)),
//
//           SliverToBoxAdapter(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
//                 child: BlocConsumer<CreateOrderCubit, CreateOrderState>(
//                   listener: (context, state) {
//                     if (state is CreateOrderSuccess) {
//                       AppToast.show(
//                         msg: state.order.message,
//                         gravity: ToastGravity.TOP,
//                         backgroundColor: Colors.green,
//                         textColor: Colors.white,
//                         fontSize: 16.sp,
//                       );
//
//                       log(state.order.data.order.skipCashPaymentUrl);
//
//                       GoRouter.of(context).push(
//                         AppRouter.paymentWebPage,
//                         extra: {
//                           "checkoutUrl":
//                               state.order.data.order.skipCashPaymentUrl,
//                         },
//                       );
//                     }
//                     if (state is CreateOrderError) {
//                       AppToast.show(
//                         msg: state.error.message,
//                         gravity: ToastGravity.TOP,
//                         backgroundColor: Colors.red,
//                         textColor: Colors.white,
//                         fontSize: 16.sp,
//                       );
//                     }
//                   },
//                   builder: (context, state) {
//                     // double total = widget.cartList.fold(
//                     //   0,
//                     //   (sum, item) => sum + (item.totalPrice ?? 0),
//                     // );
//                     return CustomElevatedButton(
//                       verticalPadding: 4.h,
//                       height: 60.h,
//                       onPressed: state is CreateOrderLoading
//                           ? () {}
//                           : () {
//                               context.read<CreateOrderCubit>().createOrder();
//                             },
//                       child: (state is CreateOrderLoading)
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Row(
//                               children: [
//                                 Text(
//                                    S.of(context).checkout,
//                                   style: AppStyle.styleRegular15(
//                                     context,
//                                   ).copyWith(color: Colors.white),
//                                 ),
//                                 // SizedBox(width: 10.w),
//                                 // Text(
//                                 //   "${total.toStringAsFixed(2)} ",
//                                 //   style: AppStyle.styleRegular15(
//                                 //     context,
//                                 //   ).copyWith(color: Colors.white),
//                                 // ),
//                               ],
//                             ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//
//           SliverToBoxAdapter(
//             child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:camion/config/widgets/custom_cached_network_image.dart';
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'dart:async';

import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
// import 'package:camion/features/cart/data/models/get_cart_model.dart';
import 'package:camion/features/cart/presentation/widgets/checkout_flow_widgets.dart';
import 'package:camion/features/cart/presentation/widgets/checkout_method_logo.dart';
import 'package:camion/features/order_status/data/models/order_preview_model/order_preview_model.dart';
import 'package:camion/features/order_status/data/models/order_response_model/order_response_model.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/create_order_cubit/create_order_cubit.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:camion/features/cart/presentation/screens/my_cart_screen.dart';

import '../../../../core/services/service_locator.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  const ConfirmPaymentScreen({
    super.key,
    required this.cartList,
    required this.subTotal,
    required this.shipping,
    required this.itemsDiscount,
    required this.couponDiscount,
    required this.discountTotal,
    required this.total,
    this.checkoutPayload,
  });

  final List<GetCartModel> cartList;

  // received from cart screen
  final double subTotal;
  final double shipping;
  final double itemsDiscount;
  final double couponDiscount;
  final double discountTotal;
  final double total;
  final Map<String, dynamic>? checkoutPayload;

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ReviewProductCard extends StatelessWidget {
  const _ReviewProductCard({required this.item, required this.priceLabel});

  final GetCartModel item;
  final String priceLabel;

  bool _isDisplayableVariation(String attribute, String value) {
    final normalized = attribute.trim().toLowerCase();
    if (normalized.isEmpty || value.trim().isEmpty) return false;
    return normalized != 'variantuuid' &&
        normalized != 'sku' &&
        normalized != 'barcode';
  }

  List<(String, String)> _dynamicVariationPairs() {
    final rawVariations = item.variation ?? const <Variation>[];
    final pairs = <(String, String)>[];
    final seen = <String>{};

    for (final variation in rawVariations) {
      final attribute = (variation.attribute ?? '').trim();
      final value = (variation.value ?? '').trim();
      if (!_isDisplayableVariation(attribute, value)) continue;

      final key = '${attribute.toLowerCase()}|${value.toLowerCase()}';
      if (!seen.add(key)) continue;
      pairs.add((attribute, value));
    }

    return pairs;
  }

  String _localizedVariationLabel(BuildContext context, String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'color' || normalized == 'colour') {
      return S.of(context).color_label;
    }
    if (normalized == 'size') {
      return S.of(context).size_label;
    }
    if (normalized == 'variant') {
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'الخيار'
          : label;
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final variationPairs = _dynamicVariationPairs();
    final splitPrice = _splitPrice(priceLabel);

    return Container(
      constraints: BoxConstraints(minHeight: 120.h),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: AppColors.paleGray,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90.w,
            height: 104.h,
            decoration: BoxDecoration(
              color: AppColors.cloudWhite,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5.r),
              child: CustomCachedNetworkImage(
                imageUrl: item.image ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.product,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                    fontSize: 8.sp,
                    height: 12 / 8,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.title ?? 'Product Name',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    height: 18 / 12,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                if (variationPairs.isEmpty)
                  Text(
                    '-',
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      fontSize: 8.sp,
                      height: 12 / 8,
                      color: Colors.black87,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: variationPairs
                        .map(
                          (pair) => Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${_localizedVariationLabel(context, pair.$1)}: ',
                                    style: TextStyle(
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 8.sp,
                                      height: 12 / 8,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextSpan(
                                    text: pair.$2,
                                    style: TextStyle(
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 8.sp,
                                      height: 12 / 8,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: splitPrice.$1,
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                height: 24 / 14,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: splitPrice.$2,
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w600,
                                fontSize: 10.sp,
                                height: 24 / 10,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'X${item.quantity ?? 1}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                        height: 18 / 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _splitPrice(String value) {
    final cleaned = value.trim();
    final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)(.*)$').firstMatch(cleaned);
    if (match == null) return (cleaned, '');
    return ((match.group(1) ?? '').trim(), (match.group(2) ?? '').trim());
  }
}

class _EditTextButton extends StatelessWidget {
  const _EditTextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        S.of(context).edit,
        style: AppStyle.styleRegular15(
          context,
        ).copyWith(color: Colors.black, decoration: TextDecoration.underline),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child, this.padding, this.height});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: child,
    );
  }
}

class _BadgeBox extends StatelessWidget {
  const _BadgeBox({required this.id, required this.title, required this.type});

  final String id;
  final String title;
  final CheckoutMethodLogoType type;

  @override
  Widget build(BuildContext context) {
    return CheckoutMethodLogoBox(
      id: id,
      title: title,
      type: type,
      width: 58.w,
      height: 28.h,
    );
  }
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final TextEditingController _couponController = TextEditingController();

  // coupon percent that comes from API after apply
  double _couponPercent = 0.0; // 0.90 = 90%
  String? _appliedCouponCode;

  // inline apply state
  bool _isApplyingCoupon = false;
  bool _isPreviewLoading = false;
  OrderPreviewModel? _orderPreview;
  List<GetCartModel> _previewCartItems = const <GetCartModel>[];
  String? _orderPreviewError;

  String _selectedCurrencyCode() {
    return resolveCurrencyCode([
      _orderPreview?.summary.currencyCode,
      if (_previewCartItems.isNotEmpty) _previewCartItems.first.currencyCode,
      if (widget.cartList.isNotEmpty) widget.cartList.first.currencyCode,
    ]);
  }

  bool get _hasAppliedCoupon =>
      (_appliedCouponCode ?? '').trim().isNotEmpty && _couponPercent > 0;

  Map<String, dynamic> get _payload => widget.checkoutPayload ?? const {};

  Map<String, dynamic> get _selectedShippingAddress {
    final raw = _payload['selectedShippingAddress'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Map<String, dynamic> get _selectedShippingMethod {
    final raw = _payload['selectedShippingMethod'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Map<String, dynamic> get _selectedPaymentMethod {
    final raw = _payload['selectedPaymentMethod'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  List<String> _payloadCartItemUuids() {
    final raw = _payload['cartItemUuids'];
    if (raw is List) {
      return raw
          .map((uuid) => uuid.toString().trim())
          .where((uuid) => uuid.isNotEmpty)
          .toList();
    }
    final single = _payload['cartItemUuid']?.toString().trim();
    if (single != null && single.isNotEmpty) return <String>[single];
    return const <String>[];
  }

  String _shippingAddressLine() {
    final previewAddress = _orderPreview?.shippingAddress;
    if (previewAddress != null) {
      final parts = [
        previewAddress.fullName,
        previewAddress.streetAddress,
        previewAddress.apartment,
      ].where((value) => value.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    final address1 = (_selectedShippingAddress['address_1'] ?? '').toString();
    final address2 = (_selectedShippingAddress['address_2'] ?? '').toString();
    final parts = [
      address1,
      address2,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? S.of(context).shipping_address : parts.join(', ');
  }

  bool _hasValidShippingAddress() {
    final address = _selectedShippingAddress;
    final address1 = (address['address_1'] ?? '').toString().trim();
    final city = (address['city'] ?? '').toString().trim();
    final country = (address['country'] ?? '').toString().trim();
    return address1.isNotEmpty && city.isNotEmpty && country.isNotEmpty;
  }

  String _shippingAddressDetail() {
    final previewAddress = _orderPreview?.shippingAddress;
    if (previewAddress != null) {
      final parts = [
        previewAddress.city,
        previewAddress.state,
        previewAddress.zipCode,
        previewAddress.country,
        previewAddress.phoneNumber,
      ].where((value) => value.trim().isNotEmpty).toList();
      return parts.join(', ');
    }
    final parts =
        [
              _selectedShippingAddress['city'],
              _selectedShippingAddress['state'],
              _selectedShippingAddress['postcode'],
              _selectedShippingAddress['country'],
            ]
            .map((value) => (value ?? '').toString())
            .where((value) => value.trim().isNotEmpty)
            .toList();
    return parts.join(', ');
  }

  String _shippingMethodTitle() {
    final title =
        (_selectedShippingMethod['title'] ??
                _selectedShippingMethod['method_title'] ??
                '')
            .toString()
            .trim();
    return title.isEmpty ? S.of(context).shipping : title;
  }

  String _paymentMethodLabel() {
    final title = (_selectedPaymentMethod['title'] ?? '').toString().trim();
    return title.isEmpty ? 'Select payment method' : title;
  }

  String _paymentMethodMask() {
    final id = (_selectedPaymentMethod['id'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    switch (id) {
      case 'default':
        return isArabic ? 'الدفع بالبطاقة' : 'Pay by card';
      case 'cod':
      case 'cash':
      case 'nakdy':
        return 'Cash on Delivery';
      case 'mastercard':
        return 'Master Card';
      case 'amex':
        return 'American Express Card';
      case 'visa':
        return 'Visa Card';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'card':
        return _paymentMethodLabel();
      default:
        return id.isEmpty ? 'Select payment method' : _paymentMethodLabel();
    }
  }

  String _shippingMethodId() {
    return (_selectedShippingMethod['method_id'] ??
            _selectedShippingMethod['id'] ??
            '4x-delivery-service')
        .toString()
        .trim();
  }

  String _paymentMethodId() {
    return (_selectedPaymentMethod['id'] ?? '').toString().trim();
  }

  String _apiPaymentMethod() {
    return 'default';
  }

  String _resolvedOrderPlacementError(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return 'Unable to place order. Please try again.';
    }
    return normalized;
  }

  String _resolvePaymentCheckoutUrl(OrderResponse orderResponse) {
    final fromV1 = orderResponse.data.paymentPayUrl.trim();
    if (fromV1.isNotEmpty) {
      return fromV1;
    }
    final legacy = orderResponse.data.order.skipCashPaymentUrl.trim();
    if (legacy.isNotEmpty) {
      return legacy;
    }
    return '';
  }

  String _resolvedCouponCodeForOrder() {
    final appliedCouponCode = (_appliedCouponCode ?? '').trim();
    if (appliedCouponCode.isNotEmpty) {
      return appliedCouponCode;
    }
    final payloadAppliedCouponCode =
        (_payload['appliedCouponCode']?.toString() ?? '').trim();
    if (payloadAppliedCouponCode.isNotEmpty) {
      return payloadAppliedCouponCode;
    }
    return '';
  }

  bool _ensureAuthenticatedCheckout() {
    final loginMethod = (sl<CacheHelper>().getData(key: 'loginMethod') ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final isGuest = loginMethod == 'guest';
    if (!isGuest) return true;

    AppToast.show(
      msg: 'Please login first.',
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    final next = Uri.encodeComponent(
      AppRouter.selectingFromBottomNavBarCartTab,
    );
    if (mounted) {
      GoRouter.of(context).push('${AppRouter.login}?next=$next');
    }
    return false;
  }

  List<String> _cartItemIdsForOrder() {
    final payloadIds = _payloadCartItemUuids();
    if (payloadIds.isNotEmpty) return payloadIds;
    return _effectiveCartList()
        .map((item) => (item.id ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    // If previous screen already applied coupon and passed couponDiscount etc.
    final prevSub = widget.subTotal;
    final prevItemsD = widget.itemsDiscount;
    final prevCouponD = widget.couponDiscount;

    final base = prevSub - prevItemsD;
    if (base > 0 && prevCouponD > 0) {
      _couponPercent = prevCouponD / base;
      _appliedCouponCode = _payload['appliedCouponCode']?.toString();
      if ((_appliedCouponCode ?? '').trim().isNotEmpty) {
        _couponController.text = _appliedCouponCode!;
      }
    }
    _loadOrderPreview();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _money(double v) => v.toStringAsFixed(2);

  String _resolvedOrderPreviewError(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return 'Unable to load order preview. Please review your shipping address.';
    }
    return normalized;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  List<Map<String, dynamic>> _extractAddressList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }

    final root = payload is Map
        ? Map<String, dynamic>.from(payload)
        : const <String, dynamic>{};
    const keys = ['data', 'results', 'addresses', 'items', 'nodes'];
    dynamic cursor = root;
    for (final key in keys) {
      if (cursor is Map && cursor[key] != null) {
        cursor = cursor[key];
      }
    }
    final rawList = cursor is List
        ? cursor
        : (root['customerAddresses'] is List
              ? root['customerAddresses'] as List
              : (root['addresses'] is List ? root['addresses'] as List : null));
    if (rawList == null) return const <Map<String, dynamic>>[];
    return rawList
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<bool> _hasDefaultAddress() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
      if (guestId != null && guestId.trim().isNotEmpty) 'x-guest-id': guestId,
    };
    final response = await sl<Dio>().get(
      EndPoints.customerAddresses,
      options: Options(headers: headers, responseType: ResponseType.json),
    );
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;

    final addresses = _extractAddressList(response.data);
    if (addresses.isEmpty) return false;

    return addresses.any((address) {
      final shippingAddress = address['shipping_address'] is Map
          ? Map<String, dynamic>.from(address['shipping_address'] as Map)
          : const <String, dynamic>{};
      return _toBool(
        address['isDefault'] ??
            address['is_default'] ??
            address['default'] ??
            shippingAddress['isDefault'] ??
            shippingAddress['is_default'] ??
            shippingAddress['default'],
      );
    });
  }

  int _resolvedPreviewItemQuantity(OrderPreviewItem item) {
    final fallback = item.quantity > 0 ? item.quantity : 1;
    if (widget.cartList.isEmpty) return fallback;

    String variationValue(List<dynamic> list, String key) {
      for (final variation in list) {
        dynamic rawAttribute;
        dynamic rawValue;
        if (variation is Map) {
          rawAttribute = variation['attribute'];
          rawValue = variation['value'];
        } else {
          try {
            rawAttribute = (variation as dynamic).attribute;
            rawValue = (variation as dynamic).value;
          } catch (_) {
            continue;
          }
        }
        final attribute = (rawAttribute ?? '').toString().trim().toLowerCase();
        final value = (rawValue ?? '').toString().trim();
        if (value.isEmpty) continue;
        if (attribute == key) return value;
      }
      return '';
    }

    final previewId = item.id.trim();
    final previewVariantUuid = variationValue(item.variations, 'variantuuid');

    for (final cartItem in widget.cartList) {
      final cartQty = cartItem.quantity ?? 0;
      if (cartQty <= 0) continue;

      final cartId = (cartItem.id ?? '').trim();
      if (previewId.isNotEmpty && cartId.isNotEmpty && previewId == cartId) {
        return cartQty;
      }

      final cartVariantUuid = variationValue(
        cartItem.variation ?? const <dynamic>[],
        'variantuuid',
      );
      if (previewVariantUuid.isNotEmpty &&
          cartVariantUuid.isNotEmpty &&
          previewVariantUuid == cartVariantUuid) {
        return cartQty;
      }
    }

    return fallback;
  }

  int? _previewItemCartOrderIndex(OrderPreviewItem item) {
    if (widget.cartList.isEmpty) return null;

    String variationValue(List<dynamic> list, String key) {
      for (final variation in list) {
        dynamic rawAttribute;
        dynamic rawValue;
        if (variation is Map) {
          rawAttribute = variation['attribute'];
          rawValue = variation['value'];
        } else {
          try {
            rawAttribute = (variation as dynamic).attribute;
            rawValue = (variation as dynamic).value;
          } catch (_) {
            continue;
          }
        }
        final attribute = (rawAttribute ?? '').toString().trim().toLowerCase();
        final value = (rawValue ?? '').toString().trim();
        if (value.isEmpty) continue;
        if (attribute == key) return value;
      }
      return '';
    }

    final previewId = item.id.trim();
    final previewVariantUuid = variationValue(item.variations, 'variantuuid');

    for (var index = 0; index < widget.cartList.length; index++) {
      final cartItem = widget.cartList[index];
      final cartId = (cartItem.id ?? '').trim();
      if (previewId.isNotEmpty && cartId.isNotEmpty && previewId == cartId) {
        return index;
      }

      final cartVariantUuid = variationValue(
        cartItem.variation ?? const <dynamic>[],
        'variantuuid',
      );
      if (previewVariantUuid.isNotEmpty &&
          cartVariantUuid.isNotEmpty &&
          previewVariantUuid == cartVariantUuid) {
        return index;
      }
    }

    return null;
  }

  Future<void> _loadOrderPreview() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.trim().isEmpty) return;

    bool hasDefaultAddress = false;
    try {
      hasDefaultAddress = await _hasDefaultAddress();
    } catch (_) {
      hasDefaultAddress = false;
    }
    if (!hasDefaultAddress) {
      if (!mounted) return;
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final message = isArabic
          ? 'الرجاء إضافة عنوان وتعيين عنوان افتراضي قبل المتابعة إلى الدفع.'
          : 'Please add an address and mark one as default before checkout.';
      AppToast.show(
        msg: message,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        _orderPreview = null;
        _previewCartItems = const <GetCartModel>[];
        _orderPreviewError = message;
        _isPreviewLoading = false;
      });
      return;
    }

    final couponCode = _resolvedCouponCodeForOrder();

    if (!mounted) return;
    setState(() {
      _isPreviewLoading = true;
    });

    final result = await sl<OrderStatusRepository>().getOrderPreview(
      token: token,
      couponCode: couponCode.isEmpty ? null : couponCode,
      cartItemUuids: _payloadCartItemUuids(),
    );
    if (!mounted) return;

    result.fold(
      (error) {
        final message = _resolvedOrderPreviewError(error.message);
        AppToast.show(
          msg: message,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          _isPreviewLoading = false;
          _orderPreview = null;
          _previewCartItems = const <GetCartModel>[];
          _orderPreviewError = message;
        });
      },
      (preview) {
        final mappedEntries = preview.items.asMap().entries.map((entry) {
          return (
            previewIndex: entry.key,
            cartIndex: _previewItemCartOrderIndex(entry.value),
            item: GetCartModel(
              id: entry.value.id,
              quantity: _resolvedPreviewItemQuantity(entry.value),
              title: entry.value.title,
              image: entry.value.image,
              price: entry.value.price.toString(),
              currencyCode: preview.summary.currencyCode,
              variation: entry.value.variations
                  .map(
                    (variation) => Variation(
                      attribute: variation.attribute,
                      value: variation.value,
                    ),
                  )
                  .toList(),
              discountPercentage: 0,
            ),
          );
        }).toList();

        mappedEntries.sort((a, b) {
          final aIndex = a.cartIndex ?? 1 << 30;
          final bIndex = b.cartIndex ?? 1 << 30;
          if (aIndex != bIndex) return aIndex.compareTo(bIndex);
          return a.previewIndex.compareTo(b.previewIndex);
        });

        final mappedItems = mappedEntries.map((entry) => entry.item).toList();

        setState(() {
          _orderPreview = preview;
          _previewCartItems = mappedItems;
          _isPreviewLoading = false;
          _orderPreviewError = null;
        });
      },
    );
  }

  List<GetCartModel> _effectiveCartList() {
    if (_previewCartItems.isNotEmpty) {
      return _previewCartItems;
    }
    return widget.cartList;
  }

  double _resolvedSubTotal() {
    if (_orderPreview != null) {
      return _orderPreview!.summary.subTotal;
    }
    return _subTotal();
  }

  double _resolvedShipping() {
    if (_orderPreview != null) {
      return _orderPreview!.summary.shippingCost;
    }
    return widget.shipping;
  }

  double _resolvedDiscountTotal() {
    if (_orderPreview != null) {
      return _orderPreview!.summary.discount;
    }
    final itemsDiscount = _itemsDiscount();
    final couponDiscount = _couponDiscount(_subTotal(), itemsDiscount);
    return itemsDiscount + couponDiscount;
  }

  double _resolvedTotal() {
    if (_orderPreview != null) {
      return _orderPreview!.summary.grandTotal;
    }
    return _total(_subTotal(), widget.shipping);
  }

  double _itemLineTotal(GetCartModel item) {
    final price = _parseNum(item.price);
    final qty = (item.quantity ?? 1);
    return price * qty;
  }

  double _itemDiscount(GetCartModel item) {
    final percent = _parseNum(item.discountPercentage);
    if (percent <= 0) return 0;
    return _itemLineTotal(item) * (percent / 100.0);
  }

  double _subTotal() {
    double total = 0;
    for (final item in _effectiveCartList()) {
      total += _itemLineTotal(item);
    }
    return total;
  }

  double _itemsDiscount() {
    double d = 0;
    for (final item in _effectiveCartList()) {
      d += _itemDiscount(item);
    }
    return d;
  }

  double _couponDiscount(double subTotal, double itemsDiscount) {
    if (_couponPercent <= 0) return 0;
    final base = subTotal - itemsDiscount;
    if (base <= 0) return 0;
    return base * _couponPercent;
  }

  double _total(double subTotal, double shipping) {
    final itemsD = _itemsDiscount();
    final couponD = _couponDiscount(subTotal, itemsD);
    final d = itemsD + couponD;
    final t = subTotal + shipping - d;
    return t < 0 ? 0 : t;
  }

  Future<void> _applyCouponInline() async {
    if (_isApplyingCoupon) return;

    final code = _couponController.text.trim();
    if (code.isEmpty) {
      AppToast.show(
        msg: S.of(context).please_enter_your_coupon_code,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isApplyingCoupon = true;
      _appliedCouponCode = code;
    });

    await _loadOrderPreview();
    if (!mounted) return;

    final hadPreviewError = (_orderPreviewError ?? '').trim().isNotEmpty;
    final confirmedCouponPercent =
        (_orderPreview?.coupon?.discountPercentage ?? 0).toDouble();
    final confirmedDiscountValue = (_orderPreview?.summary.discount ?? 0)
        .toDouble();
    final baseBeforeCoupon =
        (_orderPreview?.summary.subTotal ?? _subTotal()) - _itemsDiscount();
    final derivedCouponPercent =
        (confirmedCouponPercent <= 0 &&
            confirmedDiscountValue > 0 &&
            baseBeforeCoupon > 0)
        ? (confirmedDiscountValue / baseBeforeCoupon) * 100.0
        : confirmedCouponPercent;

    setState(() {
      _isApplyingCoupon = false;
      _couponPercent = derivedCouponPercent > 0
          ? (derivedCouponPercent / 100.0)
          : 0.0;
    });

    if (hadPreviewError) {
      return;
    }

    final couponApplied =
        confirmedDiscountValue > 0 || confirmedCouponPercent > 0;
    if (couponApplied) {
      setState(() {
        _appliedCouponCode = code;
        _couponController.text = code;
      });
      AppToast.show(
        msg: S.of(context).Coupon_applied_successfully,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      setState(() {
        _appliedCouponCode = null;
      });
      AppToast.show(
        msg: S.of(context).invalid_coupon_code,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _removeAppliedCoupon() {
    setState(() {
      _couponPercent = 0.0;
      _appliedCouponCode = null;
      _couponController.clear();
    });

    AppToast.show(
      msg: S.of(context).coupon_removed,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
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

  Map<String, dynamic> _nextPayload({
    double? shipping,
    double? discountTotal,
    double? total,
  }) {
    return {
      ..._payload,
      'cartList': _effectiveCartList(),
      'cartItemUuids': _cartItemIdsForOrder(),
      'subTotal': _resolvedSubTotal(),
      'shipping': shipping ?? _resolvedShipping(),
      'itemsDiscount': _itemsDiscount(),
      'couponDiscount': _couponDiscount(_subTotal(), _itemsDiscount()),
      'appliedCouponCode': _appliedCouponCode,
      'discountTotal': discountTotal ?? _resolvedDiscountTotal(),
      'total': total ?? _resolvedTotal(),
    };
  }

  void _goToStep(int step) {
    final shipping = _resolvedShipping();
    final discountTotal = _resolvedDiscountTotal();
    final total = _resolvedTotal();

    final payload = _nextPayload(
      shipping: shipping,
      discountTotal: discountTotal,
      total: total,
    );

    if (step == 0) {
      GoRouter.of(
        context,
      ).push(AppRouter.confirmShippingAddressScreen, extra: payload);
      return;
    }
    if (step == 1) {
      GoRouter.of(
        context,
      ).push(AppRouter.confirmShippingAddressScreen, extra: payload);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final subTotal = _resolvedSubTotal();
    final shipping = _resolvedShipping();
    final discountTotal = _resolvedDiscountTotal();
    final total = _resolvedTotal();
    final effectiveCartList = _effectiveCartList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 45.h)),
                const CheckoutHeader(showNotification: true),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 12.h),
                    child: CheckoutStepper(
                      currentStep: 2,
                      onStepTap: _goToStep,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        Text(s.order_review, style: _sectionHeadingStyle()),
                        SizedBox(height: 12.h),
                        Text(
                          s.review_before_payment,
                          style: AppStyle.styleRegular15(context).copyWith(
                            color: Colors.black87,
                            fontSize: 16.sp,
                            height: 1.45,
                          ),
                        ),
                        if (_isPreviewLoading) ...[
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Refreshing order preview...',
                                style: AppStyle.styleRegular12(
                                  context,
                                ).copyWith(color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                        if ((_orderPreviewError ?? '').trim().isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2F2),
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color: const Color(0xFFFFD6D6),
                              ),
                            ),
                            child: Text(
                              _orderPreviewError!,
                              style: AppStyle.styleRegular12(
                                context,
                              ).copyWith(color: const Color(0xFFB42318)),
                            ),
                          ),
                        ],
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Column(
                        children: List.generate(effectiveCartList.length, (
                          index,
                        ) {
                          final item = effectiveCartList[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == effectiveCartList.length - 1
                                  ? 0
                                  : 18.h,
                            ),
                            child: _ReviewProductCard(
                              item: item,
                              priceLabel: formatMoneyForDisplay(
                                context,
                                _parseNum(item.price),
                                _selectedCurrencyCode(),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.shipping_to, style: _sectionHeadingStyle()),
                        _EditTextButton(onTap: () => _goToStep(0)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.shipping_address,
                            style: TextStyle(
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                              height: 18 / 14,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _shippingAddressLine(),
                            style: TextStyle(
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              height: 18 / 14,
                              color: Colors.black,
                            ),
                          ),
                          if (_shippingAddressDetail().isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              _shippingAddressDetail(),
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w500,
                                fontSize: 14.sp,
                                height: 18 / 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _InfoCard(
                      height: 50.h,
                      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                      child: Row(
                        children: [
                          _BadgeBox(
                            id: _shippingMethodId(),
                            title: _shippingMethodTitle(),
                            type: CheckoutMethodLogoType.shipping,
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              _shippingMethodTitle(),
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w400,
                                fontSize: 14.sp,
                                height: 18 / 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            formatMoneyForDisplay(
                              context,
                              shipping,
                              _selectedCurrencyCode(),
                            ),
                            style: TextStyle(
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                              height: 18 / 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.payment_method, style: _sectionHeadingStyle()),
                        _EditTextButton(onTap: () => _goToStep(1)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _InfoCard(
                      height: 50.h,
                      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                      child: Row(
                        children: [
                          _BadgeBox(
                            id: _paymentMethodId(),
                            title: _paymentMethodLabel(),
                            type: CheckoutMethodLogoType.payment,
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              _paymentMethodMask(),
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w400,
                                fontSize: 14.sp,
                                height: 18 / 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(s.coupon_code, style: _sectionHeadingStyle()),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      width: double.infinity,
                      height: 56.h,
                      padding: EdgeInsets.fromLTRB(16.w, 7.h, 14.w, 7.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              readOnly: _hasAppliedCoupon,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              decoration: InputDecoration(
                                hintText: s.enter_your_coupon_code,
                                hintStyle: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Montes',
                                  height: 24 / 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Montes',
                                height: 24 / 16,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          SizedBox(
                            width: 70.w,
                            height: 42.h,
                            child: ElevatedButton(
                              onPressed: _isApplyingCoupon
                                  ? null
                                  : _hasAppliedCoupon
                                  ? _removeAppliedCoupon
                                  : _applyCouponInline,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD72631),
                                disabledBackgroundColor: const Color(
                                  0xFFD72631,
                                ),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                              ),
                              child: _isApplyingCoupon
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _hasAppliedCoupon
                                          ? s.delete_label
                                          : s.apply,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Montes',
                                        height: 24 / 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 26.h)),
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    color: AppColors.borderGray,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.order_summary, style: _sectionHeadingStyle()),
                        SizedBox(height: 24.h),
                        _row(s.subtotal, _money(subTotal)),
                        _row(
                          s.discount,
                          discountTotal > 0 ? _money(discountTotal) : '-',
                          appendCurrency: discountTotal > 0,
                          valuePrefix: discountTotal > 0 ? '-' : '',
                        ),
                        _row(s.shipping_fee, _money(shipping)),
                        SizedBox(height: 20.h),
                        _row(
                          s.total,
                          _money(total),
                          valueColor: Colors.black,
                          labelWeight: FontWeight.w600,
                          valueWeight: FontWeight.w700,
                          fontSize: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
            child: BlocConsumer<CreateOrderCubit, CreateOrderState>(
              listener: (context, state) {
                if (state is CreateOrderError) {
                  AppToast.show(
                    msg: _resolvedOrderPlacementError(state.error.message),
                    gravity: ToastGravity.TOP,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
                if (state is CreateOrderSuccess) {
                  final successSubTotal = _resolvedSubTotal();
                  final successShipping = _resolvedShipping();
                  final successDiscountTotal = _resolvedDiscountTotal();
                  final successTotal = _resolvedTotal();
                  final checkoutUrl = _resolvePaymentCheckoutUrl(state.order);
                  unawaited(
                    TikTokBusinessService.addPaymentInfo(
                      eventId: state.order.data.order.id.trim().isNotEmpty
                          ? state.order.data.order.id.trim()
                          : state.order.data.orderId.trim(),
                    ),
                  );

                  if (checkoutUrl.isNotEmpty) {
                    GoRouter.of(context).pushReplacement(
                      AppRouter.paymentWebPage,
                      extra: {
                        'checkoutUrl': checkoutUrl,
                        'orderResponse': state.order,
                        'subTotal': successSubTotal,
                        'shipping': successShipping,
                        'discountTotal': successDiscountTotal,
                        'total': successTotal,
                      },
                    );
                    return;
                  }

                  CartRefreshNotifier.requestRefresh();
                  GoRouter.of(context).pushReplacement(
                    AppRouter.orderOverview,
                    extra: {
                      'orderResponse': state.order,
                      'subTotal': successSubTotal,
                      'shipping': successShipping,
                      'discountTotal': successDiscountTotal,
                      'total': successTotal,
                    },
                  );
                }
              },
              builder: (context, state) {
                return CustomElevatedButton(
                  onPressed: state is CreateOrderLoading
                      ? null
                      : () {
                          if (!_ensureAuthenticatedCheckout()) {
                            return;
                          }

                          if (!_hasValidShippingAddress()) {
                            AppToast.show(
                              msg: s.please_select_or_add_shipping_address,
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                            GoRouter.of(context).push(
                              AppRouter.confirmShippingAddressScreen,
                              extra: _nextPayload(),
                            );
                            return;
                          }

                          final paymentMethodId =
                              (_selectedPaymentMethod['id'] ?? '')
                                  .toString()
                                  .trim();
                          if (paymentMethodId.isEmpty) {
                            AppToast.show(
                              msg: 'Please select a payment method.',
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                            GoRouter.of(context).push(
                              AppRouter.confirmShippingAddressScreen,
                              extra: _nextPayload(),
                            );
                            return;
                          }

                          final cartItemIds = _cartItemIdsForOrder();
                          if (cartItemIds.isEmpty) {
                            AppToast.show(
                              msg: 'Your cart is empty.',
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                            return;
                          }
                          final candidateCouponCode =
                              _resolvedCouponCodeForOrder();

                          context
                              .read<CreateOrderCubit>()
                              .createOrderWithPayload(
                                cartItemUuids: cartItemIds,
                                paymentMethod: _apiPaymentMethod(),
                                currency: _selectedCurrencyCode().toLowerCase(),
                                couponCode: candidateCouponCode.isEmpty
                                    ? null
                                    : candidateCouponCode,
                              );
                        },
                  backgroundColor: AppColors.primaryColor,
                  keepBackgroundWhenDisabled: true,
                  elevation: 0,
                  child: state is CreateOrderLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          s.make_payment,
                          style: AppStyle.styleRegular15(context).copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
    bool appendCurrency = true,
    String valuePrefix = '',
    FontWeight labelWeight = FontWeight.w400,
    FontWeight valueWeight = FontWeight.w700,
    double? fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppStyle.styleRegular15(context).copyWith(
                color: Colors.black87,
                fontWeight: labelWeight,
                fontSize: fontSize ?? 16.sp,
              ),
            ),
          ),
          Text(
            appendCurrency
                ? '$valuePrefix${formatMoneyForDisplay(context, value, _selectedCurrencyCode())}'
                : '$valuePrefix$value',
            style: AppStyle.styleRegular15(context).copyWith(
              fontWeight: valueWeight,
              color: valueColor ?? Colors.black,
              fontSize: fontSize ?? 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
