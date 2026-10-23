import 'package:camion/config/widgets/custom_cached_network_image.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/variation.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomOrderDetails extends StatelessWidget {
  const CustomOrderDetails({
    super.key,
    required this.image,
    required this.title,
    required this.variations,
    required this.total,
    required this.quantity,
    required this.currency,
    required this.indexLabel,
    this.alignedOptionOrder = const <String>[],
  });

  final String image;
  final String title;
  final List<Variation> variations;
  final String total;
  final String quantity;
  final String currency;
  final String indexLabel;
  final List<String> alignedOptionOrder;

  bool _isDisplayableVariation(String attribute, String value) {
    final normalized = attribute.trim().toLowerCase();
    if (normalized.isEmpty || value.trim().isEmpty) return false;
    return normalized != 'variantuuid' &&
        normalized != 'sku' &&
        normalized != 'barcode';
  }

  List<(String, String)> _displayPairs() {
    final pairs = <(String, String)>[];
    final seen = <String>{};

    for (final variation in variations) {
      final attribute = variation.attribute.trim();
      final value = variation.value.trim();
      if (!_isDisplayableVariation(attribute, value)) continue;

      final key = '${attribute.toLowerCase()}|${value.toLowerCase()}';
      if (!seen.add(key)) continue;
      pairs.add((attribute, value));
    }

    int priorityFor(String raw) {
      final key = raw.trim().toLowerCase();
      if (key == 'size' || key == 'applicable model' || key == 'model') {
        return 0;
      }
      if (key == 'color' || key == 'colour') {
        return 1;
      }
      if (key == 'variant') {
        return 99;
      }
      return 50;
    }

    pairs.sort((a, b) {
      final aPriority = priorityFor(a.$1);
      final bPriority = priorityFor(b.$1);
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return a.$1.toLowerCase().compareTo(b.$1.toLowerCase());
    });

    if (alignedOptionOrder.isNotEmpty) {
      final byKey = <String, (String, String)>{
        for (final pair in pairs) pair.$1.trim().toLowerCase(): pair,
      };
      final aligned = <(String, String)>[];
      for (final label in alignedOptionOrder) {
        final normalized = label.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        final found = byKey.remove(normalized);
        if (found != null) {
          aligned.add(found);
        }
      }
      if (byKey.isNotEmpty) {
        final rest = byKey.values.toList()
          ..sort((a, b) {
            final pA = priorityFor(a.$1);
            final pB = priorityFor(b.$1);
            if (pA != pB) return pA.compareTo(pB);
            return a.$1.toLowerCase().compareTo(b.$1.toLowerCase());
          });
        aligned.addAll(rest);
      }
      return aligned;
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
    final variationPairs = _displayPairs();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F8),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 86.w,
            height: 106.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.all(8.r),
            child: CustomCachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indexLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 12.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6.h),
                if (variationPairs.isEmpty)
                  Text(
                    '-',
                    style: TextStyle(
                      color: AppColors.deepDark,
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${_localizedVariationLabel(context, pair.$1)}: ',
                                    style: TextStyle(
                                      color: AppColors.deepDark,
                                      fontSize: 12.sp,
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: pair.$2,
                                    style: TextStyle(
                                      color: AppColors.deepDark,
                                      fontSize: 12.sp,
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                SizedBox(height: 18.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoneyForDisplay(context, total, currency),
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 17.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'X${formatLocalizedNumber(context, quantity)}',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 16.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1,
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
}
