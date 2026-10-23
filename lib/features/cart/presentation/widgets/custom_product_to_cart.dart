// import 'package:camion/config/widgets/custom_cached_network_image.dart';
// import 'package:camion/core/utils/app_colors.dart';
// import 'package:camion/core/utils/app_images.dart';
// import 'package:camion/core/utils/app_style.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/update_cubit/update_cart_cubit.dart';
// import 'package:camion/config/localization/cubit/localizations_cubit.dart';
// import 'package:camion/features/currency/presentation/logic/cubit/currency_cubit.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
//
// class ProductCartItem extends StatefulWidget {
//   final String productId;
//   final String imageUrl;
//   final String title;
//   final String price;
//   final int initialQuantity;
//   final VoidCallback? onDelete;
//
//   const ProductCartItem({
//     super.key,
//     required this.imageUrl,
//     required this.title,
//     required this.price,
//     required this.productId,
//     this.initialQuantity = 1,
//     this.onDelete,
//   });
//
//   @override
//   State<ProductCartItem> createState() => _ProductCartItemState();
// }
//
// class _ProductCartItemState extends State<ProductCartItem> {
//   late int quantity;
//   late double unitPrice;
//   bool isUpdating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     quantity = widget.initialQuantity;
//     unitPrice = double.tryParse(widget.price) ?? 0.0;
//   }
//
//   Future<void> _updateQuantity(int newQuantity) async {
//     final oldQuantity = quantity;
//     setState(() {
//       quantity = newQuantity;
//       isUpdating = true;
//     });
//
//     try {
//       await context.read<UpdateCartCubit>().updateCart(
//         productId: widget.productId,
//         quantity: quantity,
//       );
//     } catch (_) {
//       setState(() {
//         quantity = oldQuantity;
//       });
//     } finally {
//       setState(() {
//         isUpdating = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Container(
//       margin: EdgeInsets.only(bottom: 14.h, left: 16.w, right: 16.w),
//       padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withAlpha(15),
//             spreadRadius: 2,
//             blurRadius: 4,
//             offset: Offset(0, 2.h),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: screenWidth > 600 ? 120.w : 86.w,
//                 height: screenWidth > 600 ? 120.h : 86.h,
//                 decoration: ShapeDecoration(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16.r),
//                   ),
//                   color: AppColors.paleGray,
//                 ),
//                 child: CustomCachedNetworkImage(
//                   fit: BoxFit.cover,
//                   imageUrl: widget.imageUrl,
//                 ),
//               ),
//               SizedBox(width: 10.w),
//
//               Expanded(
//                 child: Text(
//                   widget.title,
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 2,
//                   style: AppStyle.styleRegular15(context).copyWith(
//                     color: AppColors.black,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ),
//
//               SizedBox(width: 25.w),
//
//               InkWell(
//                 onTap: widget.onDelete,
//                 child: SvgPicture.asset(
//                   Assets.imagesIconsTrashNewIcon,
//                   width: 20.w,
//                   height: 20.h,
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: 6.h),
//           Divider(thickness: 1, color: Colors.grey.shade300),
//
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     'Total:',
//                     style: AppStyle.styleRegular15(context).copyWith(
//                       color: Colors.black,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   SizedBox(width: 5.w),
//                   Builder(builder: (context) {
//                     final cubit = context.watch<CurrencyCubit>();
//                     final totalQAR = unitPrice * quantity;
//                     final converted = cubit.convertFromQARToString(totalQAR);
//                     return Text(
//                       converted,
//                       style: AppStyle.styleBold18(
//                         context,
//                       ).copyWith(color: AppColors.primaryColor),
//                     );
//                   }),
//                   SizedBox(width: 4.w),
//                   Builder(builder: (context) {
//                     final isArabic = context.watch<LocalizationsCubit>().state.languageCode == 'ar';
//                     final selected = context.watch<CurrencyCubit>().selectedCurrency;
//                     final String display = isArabic
//                         ? (selected?.symbol ?? '')
//                         : (selected?.code ?? 'QAR');
//                     return Text(
//                       display,
//                       style: AppStyle.styleRegular15(context).copyWith(
//                         color: AppColors.primaryColor,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     );
//                   }),
//                 ],
//               ),
//
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
//                 decoration: ShapeDecoration(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10.r),
//                     side: BorderSide(
//                       color: AppColors.primaryColor.withAlpha(40),
//                       width: 1.5.w,
//                     ),
//                   ),
//                   color: AppColors.primaryColor.withAlpha(15),
//                 ),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         if (quantity > 1) {
//                           _updateQuantity(quantity - 1);
//                         }
//                       },
//                       child: _buildQuantityButton(Icons.remove),
//                     ),
//
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 25.w),
//                       child: isUpdating
//                           ? SizedBox(
//                               height: 18.sp,
//                               width: 18.sp,
//                               child: const CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.black,
//                               ),
//                             )
//                           : Text(
//                               quantity.toString(),
//                               style: AppStyle.styleBold18(
//                                 context,
//                               ).copyWith(color: Colors.black),
//                             ),
//                     ),
//
//                     GestureDetector(
//                       onTap: () => _updateQuantity(quantity + 1),
//                       child: _buildQuantityButton(Icons.add),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuantityButton(IconData icon) {
//     return Container(
//       width: 25.w,
//       height: 25.h,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8E9E9),
//         borderRadius: BorderRadius.circular(50.r),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Icon(icon, size: 20.sp),
//     );
//   }
// }

import 'dart:async';

import 'package:camion/config/widgets/custom_cached_network_image.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/features/cart/presentation/logic/cubit/update_cubit/update_cart_cubit.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProductCartItem extends StatefulWidget {
  final String productId;
  final String? cartItemUuid;
  final String? variantUuid;
  final String imageUrl;
  final String title;
  final String price;
  final String? currencyCode;
  final String campaignLabel;
  final DateTime? campaignEndsAt;
  final bool showCampaignTimerPreview;
  final String? categoryName;
  final String? variationText;
  final int initialQuantity;
  final VoidCallback? onDelete;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  // ✅ NEW: notify parent so subtotal/total updates
  final ValueChanged<int>? onQuantityChanged;
  final Future<bool> Function(int quantity)? onUpdateQuantity;

  const ProductCartItem({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.currencyCode,
    required this.productId,
    this.campaignLabel = '',
    this.campaignEndsAt,
    this.showCampaignTimerPreview = false,
    this.cartItemUuid,
    this.variantUuid,
    this.categoryName,
    this.variationText,
    this.initialQuantity = 1,
    this.onDelete,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onQuantityChanged,
    this.onUpdateQuantity,
  });

  @override
  State<ProductCartItem> createState() => _ProductCartItemState();
}

class _ProductCartItemState extends State<ProductCartItem> {
  late int quantity;
  late double unitPrice;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
    unitPrice = double.tryParse(widget.price) ?? 0.0;
  }

  Future<void> _updateQuantity(int newQuantity) async {
    if (isUpdating) return;
    if (newQuantity < 1) return;

    final oldQuantity = quantity;

    // ✅ optimistic UI
    setState(() {
      quantity = newQuantity;
      isUpdating = true;
    });

    // ✅ tell parent immediately (this updates subtotal/total)
    widget.onQuantityChanged?.call(newQuantity);

    try {
      if (widget.onUpdateQuantity != null) {
        final ok = await widget.onUpdateQuantity!(quantity);
        if (!ok) throw Exception("Quantity update failed");
      } else {
        final fallbackCartItemUuid = (widget.cartItemUuid ?? '').trim();
        final fallbackVariantUuid = (widget.variantUuid ?? '').trim();
        if (fallbackCartItemUuid.isEmpty || fallbackVariantUuid.isEmpty) {
          throw Exception("Missing cart identifiers");
        }
        await context.read<UpdateCartCubit>().updateCart(
          cartItemUuid: fallbackCartItemUuid,
          productUuid: widget.productId,
          variantUuid: fallbackVariantUuid,
          quantity: quantity,
        );
      }
    } catch (_) {
      // rollback local + parent
      if (mounted) {
        setState(() {
          quantity = oldQuantity;
        });
        widget.onQuantityChanged?.call(oldQuantity);
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = (widget.categoryName ?? '').trim();
    final variationText = (widget.variationText ?? '').trim();
    final hasCampaignBadge =
        widget.campaignEndsAt != null || widget.showCampaignTimerPreview;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 120.h),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 30.h, right: 10.w),
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child: Checkbox(
                value: widget.isSelected,
                activeColor: AppColors.primaryColor,
                side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                onChanged: widget.onSelectionChanged == null
                    ? null
                    : (value) => widget.onSelectionChanged!(value ?? false),
              ),
            ),
          ),
          Container(
            width: 92.w,
            height: 92.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: const Color(0xFFE7EAED),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomCachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: widget.imageUrl,
                  ),
                  if (hasCampaignBadge)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _CartCampaignCountdownBadge(
                        endsAt: widget.campaignEndsAt,
                        showPreviewTimer: widget.showCampaignTimerPreview,
                        campaignLabel: widget.campaignLabel,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (categoryName.isNotEmpty) ...[
                            Text(
                              categoryName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: const Color(0xFF707070),
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Montserrat',
                                height: 12 / 8,
                              ),
                            ),
                            SizedBox(height: 4.h),
                          ],
                          Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Montserrat',
                              height: 18 / 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    AppTapFeedback(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        width: 36.w,
                        height: 36.h,
                        alignment: Alignment.center,
                        padding: EdgeInsets.only(top: 1.h),
                        child: SvgPicture.asset(
                          Assets.imagesIconsTrashNewIcon,
                          width: 16.w,
                          height: 16.h,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: variationText.isNotEmpty
                          ? _buildVariationText(variationText)
                          : const SizedBox.shrink(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      S.of(context).edit,
                      style: TextStyle(
                        color: AppColors.black,
                        decoration: TextDecoration.underline,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Montes',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildQuantityAction(
                      label: '-',
                      onTap: (!isUpdating && quantity > 1)
                          ? () => _updateQuantity(quantity - 1)
                          : null,
                    ),
                    Container(
                      width: 32.w,
                      height: 30.h,
                      alignment: Alignment.center,
                      color: AppColors.primaryColor,
                      child: isUpdating
                          ? SizedBox(
                              height: 10.sp,
                              width: 10.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              formatLocalizedNumber(context, quantity),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                    _buildQuantityAction(
                      label: '+',
                      onTap: isUpdating
                          ? null
                          : () => _updateQuantity(quantity + 1),
                    ),
                    const Spacer(),
                    Text(
                      formatMoneyForDisplay(
                        context,
                        unitPrice * quantity,
                        resolveCurrencyCode([widget.currencyCode]),
                      ),
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Montserrat',
                        height: 24 / 16,
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

  Widget _buildQuantityAction({
    required String label,
    required VoidCallback? onTap,
  }) {
    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        width: 32.w,
        height: 30.h,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? const Color(0xFFBDBDBD) : Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            fontFamily: 'Montserrat',
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildVariationText(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    final formatted = lines.map((line) {
      final separatorIndex = line.indexOf(':');
      if (separatorIndex <= 0) return line;
      final label = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      final localizedLabel = _localizedVariationLabel(label);
      return '$localizedLabel: $value';
    }).toList();

    return Text(
      formatted.join('\n'),
      style: TextStyle(
        color: AppColors.black,
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        fontFamily: 'Montserrat',
        height: 12 / 10,
      ),
    );
  }

  String _localizedVariationLabel(String label) {
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
}

class _CartCampaignCountdownBadge extends StatefulWidget {
  const _CartCampaignCountdownBadge({
    required this.endsAt,
    required this.showPreviewTimer,
    required this.campaignLabel,
  });

  final DateTime? endsAt;
  final bool showPreviewTimer;
  final String campaignLabel;

  @override
  State<_CartCampaignCountdownBadge> createState() =>
      _CartCampaignCountdownBadgeState();
}

class _CartCampaignCountdownBadgeState
    extends State<_CartCampaignCountdownBadge> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  late DateTime _effectiveEndsAt;

  static const List<Color> _redGradient = [
    Color(0xFF7A1016),
    Color(0xFFD72631),
    Color(0xFFEF5350),
  ];

  static const List<Color> _deepRedGradient = [
    Color(0xFF4D0A0F),
    Color(0xFF8E111A),
    Color(0xFFCB262E),
  ];

  static const Duration _previewDuration = Duration(
    hours: 22,
    minutes: 41,
    seconds: 46,
  );

  @override
  void initState() {
    super.initState();
    _effectiveEndsAt = widget.endsAt ?? DateTime.now().add(_previewDuration);
    if (widget.showPreviewTimer && widget.endsAt == null) {
      _remaining = _previewDuration;
    } else {
      _refreshRemaining();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _refreshRemaining();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _CartCampaignCountdownBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt ||
        oldWidget.showPreviewTimer != widget.showPreviewTimer) {
      _effectiveEndsAt = widget.endsAt ?? DateTime.now().add(_previewDuration);
      if (widget.showPreviewTimer && widget.endsAt == null) {
        _timer?.cancel();
        _timer = null;
        setState(() {
          _remaining = _previewDuration;
        });
      } else {
        _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          _refreshRemaining();
        });
        _refreshRemaining();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshRemaining() {
    final remaining = _effectiveEndsAt.toLocal().difference(DateTime.now());
    if (mounted) {
      setState(() {
        _remaining = remaining.isNegative ? Duration.zero : remaining;
      });
    } else {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    }
  }

  String _format(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return [
      '${_twoDigits(hours)}h',
      '${_twoDigits(minutes)}m',
      '${_twoDigits(seconds)}s',
    ].join(' : ');
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _compactLabel() {
    final label = widget.campaignLabel.trim();
    if (label.isEmpty) return label;
    if (label.length <= 7) return label;
    return '${label.substring(0, 7)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const SizedBox.shrink();
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return IgnorePointer(
      child: Container(
        height: 18.h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _redGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipPath(
              clipper: _CartCampaignLabelClipper(
                textDirection: Directionality.of(context),
              ),
              child: SizedBox(
                width: 34.w,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: _deepRedGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Align(
                      alignment: isRtl
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        _compactLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: Directionality.of(context),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.2.sp,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: 8.sp,
                    ),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        _format(_remaining),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.4.sp,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartCampaignLabelClipper extends CustomClipper<Path> {
  const _CartCampaignLabelClipper({required this.textDirection});

  final TextDirection textDirection;

  @override
  Path getClip(Size size) {
    final path = Path();
    final isRtl = textDirection == TextDirection.rtl;
    final tail = size.width * 0.08;
    if (isRtl) {
      path.moveTo(size.width, 0);
      path.lineTo(tail, 0);
      path.lineTo(0, size.height * 0.5);
      path.lineTo(tail, size.height);
      path.lineTo(size.width, size.height);
      path.close();
      return path;
    }
    final ltrTail = size.width * 0.92;
    path.moveTo(0, 0);
    path.lineTo(ltrTail, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(ltrTail, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CartCampaignLabelClipper oldClipper) =>
      oldClipper.textDirection != textDirection;
}
