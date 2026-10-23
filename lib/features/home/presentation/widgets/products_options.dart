import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/product_variations.dart';
import 'package:camion/features/home/presentation/widgets/color_helper.dart';
import 'package:camion/features/home/presentation/widgets/variant_selection_rules.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductsSelectionOptions extends StatefulWidget {
  const ProductsSelectionOptions({
    super.key,
    required this.variations,
    this.onSelectionChanged,
    this.initialSelectedAttributes = const <String, String>{},
    this.initialQuantity = 1,
  });

  final List<ProductVariations> variations;
  final Function(
    Map<String, String> selectedVariation,
    int quantity,
    ProductVariations? matchedVariation,
  )?
  onSelectionChanged;
  final Map<String, String> initialSelectedAttributes;
  final int initialQuantity;

  @override
  State<ProductsSelectionOptions> createState() =>
      _ProductsSelectionOptionsState();
}

class _ProductsSelectionOptionsState extends State<ProductsSelectionOptions> {
  Map<String, String> selectedAttributes = {};
  ProductVariations? selectedVariation;
  int _quantity = 1;
  static const int _fallbackMaxQuantity = 99;

  @override
  void initState() {
    super.initState();
    _applyInitialSelection();
  }

  void _applyInitialSelection() {
    if (widget.initialSelectedAttributes.isNotEmpty) {
      selectedAttributes = Map<String, String>.from(
        widget.initialSelectedAttributes,
      );
      selectedVariation = _findMatchingVariation();
    }
    _quantity = widget.initialQuantity.clamp(1, _maxAllowedQuantity());
  }

  void _updateSelection(String attrName, String option) {
    setState(() {
      selectedAttributes[attrName] = option;
      final colorAttributeName = _findColorAttributeName();
      final isColorSelection = _isColorAttributeName(attrName);

      selectedVariation = _findMatchingVariation();

      // When a non-color option (like size) changes, always preselect
      // one available color for that new selection context.
      if (!isColorSelection && colorAttributeName != null) {
        final availableColors = _availableColorOptionsForCurrentSelection(
          changedAttributeName: attrName,
        );
        if (availableColors.isNotEmpty) {
          final currentColor =
              selectedAttributes[colorAttributeName]?.trim() ?? '';
          final normalizedCurrentColor = _normalizeOptionValue(currentColor);
          final hasCurrentColor = availableColors.any(
            (color) => _normalizeOptionValue(color) == normalizedCurrentColor,
          );
          final colorToSelect = hasCurrentColor
              ? currentColor
              : availableColors.first;
          selectedAttributes[colorAttributeName] = colorToSelect.trim();
          selectedVariation = _findMatchingVariation();
        } else if (selectedVariation == null) {
          final fallback = _findFallbackVariationForNonColorSelection(
            changedAttributeName: attrName,
          );
          if (fallback != null) {
            final fallbackColor = _extractVariationAttributeValue(
              variation: fallback,
              normalizedAttributeName: _normalizeAttributeName(
                colorAttributeName,
              ),
            );
            if (fallbackColor != null && fallbackColor.trim().isNotEmpty) {
              selectedAttributes[colorAttributeName] = fallbackColor.trim();
            }
            selectedVariation = _findMatchingVariation();
          }
        }
      }

      _quantity = _quantity.clamp(1, _maxAllowedQuantity());
    });

    _notifyParent();
  }

  int _maxAllowedQuantity() {
    final matchedStock = selectedVariation?.stockQuantity ?? 0;
    if (matchedStock > 0) {
      return matchedStock;
    }
    return _fallbackMaxQuantity;
  }

  bool get _hasKnownStockFromApi => (selectedVariation?.stockQuantity ?? 0) > 0;

  void _changeQuantity(int delta) {
    final current = _quantity;
    final maxAllowed = _maxAllowedQuantity();
    final next = (current + delta).clamp(1, maxAllowed);
    if (next == current) return;
    setState(() {
      _quantity = next;
    });
    _notifyParent();
  }

  // إضافة هذه الدالة في أعلى الـ class
  List<String> _sortSizes(List<String> sizes) {
    // قائمة الأحجام المرتبة حسب الأولوية
    final sizeOrder = [
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      'XXXL',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
      '30',
      '31',
      '32',
      '33',
      '34',
      '35',
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '46',
      '47',
      '48',
      '49',
      '50',
      '51',
      '52',
      '53',
      '54',
      '55',
      '56',
      '57',
      '58',
      '59',
      '60',
      '61',
      '62',
      '63',
      '64',
      '65',
      '66',
      '67',
      '68',
      '69',
      '70',
      '71',
      '72',
      '73',
      '74',
      '75',
      '76',
      '77',
      '78',
      '79',
      '80',
      '81',
      '82',
      '83',
      '84',
      '85',
      '86',
      '87',
      '88',
      '89',
      '90',
      '91',
      '92',
      '93',
      '94',
      '95',
      '96',
      '97',
      '98',
      '99',
      '100',
    ];

    // فصل الأحجام الرقمية والحرفية
    List<String> numericSizes = [];
    List<String> textSizes = [];
    List<String> otherSizes = [];

    for (String size in sizes) {
      String cleanSize = size.trim();

      // التحقق إذا كان الحجم رقمي
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(cleanSize)) {
        numericSizes.add(cleanSize);
      }
      // التحقق إذا كان من الأحجام النصية المعروفة
      else if (sizeOrder.contains(cleanSize.toUpperCase())) {
        textSizes.add(cleanSize);
      }
      // أي أحجام أخرى
      else {
        otherSizes.add(cleanSize);
      }
    }

    // ترتيب الأحجام الرقمية حسب القيمة الرقمية
    numericSizes.sort((a, b) => double.parse(a).compareTo(double.parse(b)));

    // ترتيب الأحجام النصية حسب الترتيب المحدد مسبقاً
    textSizes.sort((a, b) {
      int indexA = sizeOrder.indexOf(a.toUpperCase());
      int indexB = sizeOrder.indexOf(b.toUpperCase());
      return indexA.compareTo(indexB);
    });

    // دمج القوائم: الأحجام النصية أولاً ثم الرقمية ثم الأخرى
    return [...textSizes, ...numericSizes, ...otherSizes];
  }

  ProductVariations? _findMatchingVariation() {
    for (var variation in widget.variations) {
      if (!_isVariationInStock(variation)) continue;
      final variationAttributes = _normalizedVariationAttributes(variation);
      if (variationAttributes.isEmpty) continue;

      final selected = _normalizedSelectedAttributes();
      final allVariationAttributesSelected = variationAttributes.entries.every(
        (entry) => selected[entry.key] == entry.value,
      );
      final noExtraAttributes = selected.keys
          .toSet()
          .difference(variationAttributes.keys.toSet())
          .isEmpty;

      if (allVariationAttributesSelected && noExtraAttributes) {
        return variation;
      }
    }
    return null;
  }

  void _notifyParent() {
    widget.onSelectionChanged?.call(
      Map<String, String>.from(selectedAttributes),
      _quantity,
      selectedVariation,
    );
  }

  Map<String, Set<String>> _getAvailableAttributes() {
    return VariantSelectionRules.availableAttributesFromVariants(
      _variantSnapshots(),
    );
  }

  bool _isOptionAvailable(String attrName, String option) {
    return VariantSelectionRules.isOptionAvailable(
      variants: _variantSnapshots(),
      selectedAttributes: selectedAttributes,
      attrName: attrName,
      optionValue: option,
      colorAttributeName: _findColorAttributeName(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildAttributesSections(), _buildQuantitySection()],
    );
  }

  Widget _buildAttributesSections() {
    final availableAttributes = _getAvailableAttributes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableAttributes.entries.map((entry) {
        final String attrName = entry.key;
        final List<String> options = entry.value.toList();
        final normalizedAttrName = _normalizeAttributeName(attrName);

        return _buildAttributeSection(
          attrName,
          options,
          isColor:
              normalizedAttrName == 'color' ||
              normalizedAttrName.contains('color') ||
              normalizedAttrName.contains('spec'),
        );
      }).toList(),
    );
  }

  Color? getColorFromNameOrHex(String colorName) {
    Color? detectedColor = ColorDetectionService.getColorFromText(colorName);

    if (detectedColor != null) {
      return detectedColor;
    }

    final lower = colorName.toLowerCase().trim();
    if (lower.startsWith('#') && (lower.length == 7 || lower.length == 9)) {
      try {
        return Color(int.parse(lower.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
    }

    return ColorDetectionService.getDefaultColorByIndex(
      colorName.hashCode.abs(),
    );
  }

  Widget _buildAttributeSection(
    String attrName,
    List<String> options, {
    bool isColor = false,
  }) {
    // ترتيب الـ options إذا كانت sizes
    List<String> sortedOptions = options;
    if (_normalizeAttributeName(attrName) == 'size') {
      sortedOptions = _sortSizes(options);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatAttributeName(attrName),
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 14,
          ),
        ),
        SizedBox(height: 10.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sortedOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final bool isSelected = selectedAttributes[attrName] == option;
              final bool isAvailable = _isOptionAvailable(attrName, option);

              final color = isColor ? getColorFromNameOrHex(option) : null;

              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == sortedOptions.length - 1 ? 0 : 8.w,
                ),
                child: AppTapFeedback(
                  onTap: isAvailable
                      ? () => _updateSelection(attrName, option)
                      : null,
                  borderRadius: BorderRadius.circular(5.r),
                  child: Opacity(
                    opacity: isAvailable ? 1.0 : 0.5,
                    child: color != null
                        ? buildColorBox(color, isSelected, option)
                        : buildTextBox(option, isSelected, isAvailable),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget buildColorBox(Color color, bool isSelected, String colorName) {
    return Container(
      width: 34.6.w,
      height: 30.2.h,
      padding: EdgeInsets.symmetric(horizontal: 6.5.w, vertical: 4.3.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(2.7.r),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : const Color(0x42000000),
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
      child: Center(
        child: Container(
          width: 14.w,
          height: 14.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _getContrastColor(color).withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final red = (color.r * 255.0).round().clamp(0, 255);
    final green = (color.g * 255.0).round().clamp(0, 255);
    final blue = (color.b * 255.0).round().clamp(0, 255);
    final brightness = (red * 299 + green * 587 + blue * 114) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  Widget buildTextBox(String text, bool isSelected, bool isAvailable) {
    return Container(
      constraints: BoxConstraints(minWidth: 36.w, minHeight: 30.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : const Color(0x42000000),
          width: 1,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isAvailable ? AppColors.black : AppColors.midGray),
          fontSize: 14.sp,
          fontFamily: 'Montes',
          fontWeight: FontWeight.w500,
          height: 24 / 14,
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    final canDecrease = _quantity > 1;
    final canIncrease = _quantity < _maxAllowedQuantity();
    final maxLabel = _hasKnownStockFromApi
        ? '${selectedVariation!.stockQuantity} available'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).quantity,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 14,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE6EAF0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityButton(
                icon: Icons.remove_rounded,
                enabled: canDecrease,
                onTap: () => _changeQuantity(-1),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 52.w,
                height: 34.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFDDE3EA)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 170),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    '$_quantity',
                    key: ValueKey(_quantity),
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              _QuantityButton(
                icon: Icons.add_rounded,
                enabled: canIncrease,
                onTap: () => _changeQuantity(1),
              ),
            ],
          ),
        ),
        if (maxLabel != null) ...[
          SizedBox(height: 6.h),
          Text(
            maxLabel,
            style: TextStyle(
              color: AppColors.midGray,
              fontSize: 10.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
        SizedBox(height: 20.h),
      ],
    );
  }

  String _formatAttributeName(String attrName) {
    final normalized = _displayLabelFromAttribute(attrName);
    if (normalized.isEmpty) return attrName;
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _normalizeAttributeName(String raw) {
    return VariantSelectionRules.normalizeAttributeName(raw);
  }

  String _displayLabelFromAttribute(String raw) {
    return _normalizeAttributeName(raw).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isColorAttributeName(String raw) {
    return VariantSelectionRules.isColorAttributeName(raw);
  }

  String? _findColorAttributeName() {
    final availableAttributes = _getAvailableAttributes();
    for (final attrName in availableAttributes.keys) {
      if (_isColorAttributeName(attrName)) {
        return attrName;
      }
    }
    return null;
  }

  String? _extractVariationAttributeValue({
    required ProductVariations variation,
    required String normalizedAttributeName,
  }) {
    for (final attribute in variation.attributes) {
      if (_normalizeAttributeName(attribute.name) == normalizedAttributeName) {
        final value = attribute.option.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  ProductVariations? _findFallbackVariationForNonColorSelection({
    required String changedAttributeName,
  }) {
    final colorAttributeName = _findColorAttributeName();
    if (colorAttributeName == null) {
      return null;
    }

    final snapshot =
        VariantSelectionRules.findFallbackVariantForNonColorSelection(
          variants: _variantSnapshots(),
          selectedAttributes: selectedAttributes,
          changedAttributeName: changedAttributeName,
          colorAttributeName: colorAttributeName,
        );
    if (snapshot == null) return null;

    for (final variation in widget.variations) {
      if (!_isVariationInStock(variation)) continue;
      final variationAttributes = _normalizedVariationAttributes(variation);
      if (variationAttributes.isEmpty) continue;
      if (VariantSelectionRules.matchesExactAttributes(
        selectedAttributes: variationAttributes,
        variantAttributes: snapshot.attributes,
      )) {
        return variation;
      }
    }
    return null;
  }

  List<String> _availableColorOptionsForCurrentSelection({
    required String changedAttributeName,
  }) {
    final colorAttributeName = _findColorAttributeName();
    if (colorAttributeName == null) {
      return const <String>[];
    }

    final options = widget.variations
        .expand((variation) => variation.attributes)
        .where(
          (attribute) =>
              _normalizeAttributeName(attribute.name) ==
              _normalizeAttributeName(colorAttributeName),
        )
        .map((attribute) => attribute.option.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return VariantSelectionRules.availableColorOptionsForCurrentSelection(
      variants: _variantSnapshots(),
      selectedAttributes: selectedAttributes,
      changedAttributeName: changedAttributeName,
      colorAttributeName: colorAttributeName,
      candidateValues: options,
    );
  }

  String _normalizeOptionValue(String raw) {
    return VariantSelectionRules.normalizeOptionValue(raw);
  }

  Map<String, String> _normalizeAttributeMap(Map<String, String> attributes) {
    return VariantSelectionRules.normalizeAttributeMap(attributes);
  }

  Map<String, String> _normalizedSelectedAttributes() {
    return _normalizeAttributeMap(selectedAttributes);
  }

  Map<String, String> _normalizedVariationAttributes(
    ProductVariations variation,
  ) {
    final normalized = <String, String>{};
    for (final attr in variation.attributes) {
      final key = _normalizeAttributeName(attr.name);
      final value = _normalizeOptionValue(attr.option);
      if (key.isEmpty || value.isEmpty) continue;
      normalized[key] = value;
    }
    return normalized;
  }

  bool _isVariationInStock(ProductVariations variation) {
    final status = (variation.stockStatus ?? '').trim().toLowerCase();
    if (status.isEmpty) return true;
    return status == 'instock' ||
        status == 'in_stock' ||
        status == 'in stock' ||
        status == 'available';
  }

  List<VariantSelectionSnapshot> _variantSnapshots() {
    return widget.variations
        .map(
          (variation) => VariantSelectionSnapshot(
            attributes: _normalizedVariationAttributes(variation),
            isInStock: _isVariationInStock(variation),
          ),
        )
        .toList(growable: false);
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTapFeedback(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        width: 34.w,
        height: 34.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryColor : const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppColors.midGray,
          size: 18.sp,
        ),
      ),
    );
  }
}
