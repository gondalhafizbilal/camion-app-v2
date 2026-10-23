import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/services/cart_fly_to_badge_anchor.dart';
import 'package:camion/core/services/cart_fly_to_badge_service.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/features/home/presentation/widgets/color_helper.dart';
import 'package:camion/features/home/presentation/widgets/variant_selection_rules.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListingBasketButton extends StatelessWidget {
  const ListingBasketButton({super.key, required this.onTap, this.size = 34});

  final FutureOr<void> Function(BuildContext context) onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size.r);
    return AppTapFeedback(
      onTap: () => onTap(context),
      borderRadius: radius,
      child: Container(
        width: size.w,
        height: size.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDA3B3B), width: 1.4.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDA3B3B).withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SvgPicture.asset(
          'assets/images/icons/bottom_nav_bag.svg',
          width: (size * 0.52).w,
          height: (size * 0.52).w,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Color(0xFFDA3B3B),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

final Set<String> _activeQuickAddSlugs = <String>{};

Future<void> handleListingQuickAddTap(
  BuildContext context, {
  required String productSlug,
  bool showAddedToCartPreview = true,
}) async {
  final normalizedSlug = productSlug.trim();
  if (normalizedSlug.isEmpty) return;
  if (!_activeQuickAddSlugs.add(normalizedSlug)) return;
  final sourceRect = _rectFromContext(context);

  try {
    final product = await _loadListingQuickAddProduct(
      context: context,
      productSlug: normalizedSlug,
    );
    if (!context.mounted || product == null) return;

    final needsSelection =
        _selectableOptions(product).isNotEmpty &&
        product.displayableVariants.length > 1;
    if (!needsSelection) {
      final variantUuid = _resolveDirectVariantUuid(product);
      if (variantUuid.isEmpty) {
        _showToastAboveBottomSheet(
          context,
          message: 'Please select a valid variant.',
        );
        return;
      }
      final variant = _resolveDirectVariant(product);

      final success = await _addToCart(
        context: context,
        productUuid: product.uuid,
        variantUuid: variantUuid,
        quantity: 1,
      );
      if (!success || !context.mounted) return;
      try {
        await TikTokBusinessService.addToCart(
          contentId: product.uuid,
          description: product.brief.trim().isNotEmpty
              ? product.brief.trim()
              : product.description.trim(),
          contentType: 'product',
          value: _resolveUnitPrice(variant, product).toStringAsFixed(2),
          currency: _resolveCurrency(variant, product),
          contents: [
            {
              'contentId': product.uuid,
              'contentName': product.title,
              'price': _resolveUnitPrice(variant, product),
              'quantity': 1,
            },
          ],
        );
      } catch (error, stackTrace) {
        debugPrint('[TIKTOK][ADD_TO_CART] tracking failed: $error');
        debugPrint(stackTrace.toString());
      }
      unawaited(
        sl<AppsFlyerService>().logAddToCart(
          contentId: product.uuid,
          contentType: 'product',
          price: _resolveUnitPrice(variant, product).toStringAsFixed(2),
          currency: _resolveCurrency(variant, product),
          quantity: 1,
        ),
      );
      await _animateFlyToCart(context: context, sourceRect: sourceRect);
      if (!context.mounted || !showAddedToCartPreview) return;
      await _showAddedToCartPreviewSheet(
        context: context,
        product: product,
        variant: _resolveDirectVariant(product),
        quantity: 1,
      );
      return;
    }

    final quickAddResult = await showModalBottomSheet<_QuickAddResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _QuickAddVariantSheet(product: product, sourceRect: sourceRect);
      },
    );

    if (!context.mounted || quickAddResult == null) return;
    try {
      await TikTokBusinessService.addToCart(
        contentId: quickAddResult.product.uuid,
        description: quickAddResult.product.brief.trim().isNotEmpty
            ? quickAddResult.product.brief.trim()
            : quickAddResult.product.description.trim(),
        contentType: 'product',
        value: _resolveUnitPrice(
          quickAddResult.variant,
          quickAddResult.product,
        ).toStringAsFixed(2),
        currency: _resolveCurrency(
          quickAddResult.variant,
          quickAddResult.product,
        ),
        contents: [
          {
            'contentId': quickAddResult.product.uuid,
            'contentName': quickAddResult.product.title,
            'price': _resolveUnitPrice(
              quickAddResult.variant,
              quickAddResult.product,
            ),
            'quantity': quickAddResult.quantity,
          },
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('[TIKTOK][ADD_TO_CART] tracking failed: $error');
      debugPrint(stackTrace.toString());
    }
    unawaited(
      sl<AppsFlyerService>().logAddToCart(
        contentId: quickAddResult.product.uuid,
        contentType: 'product',
        price: _resolveUnitPrice(
          quickAddResult.variant,
          quickAddResult.product,
        ).toStringAsFixed(2),
        currency: _resolveCurrency(
          quickAddResult.variant,
          quickAddResult.product,
        ),
        quantity: quickAddResult.quantity,
      ),
    );
    await _animateFlyToCart(context: context, sourceRect: sourceRect);
    if (!context.mounted || !showAddedToCartPreview) return;
    await _showAddedToCartPreviewSheet(
      context: context,
      product: quickAddResult.product,
      variant: quickAddResult.variant,
      quantity: quickAddResult.quantity,
    );
  } finally {
    _activeQuickAddSlugs.remove(normalizedSlug);
  }
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

Rect? _rectFromContext(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  final offset = renderObject.localToGlobal(Offset.zero);
  return offset & renderObject.size;
}

Future<HomeGraphqlProduct?> _loadListingQuickAddProduct({
  required BuildContext context,
  required String productSlug,
}) async {
  final lang = Localizations.localeOf(context).languageCode;
  final token = await sl<SecureCacheHelper>().getData(key: 'token');
  final result = await sl<HomeRepository>().getProductGraphql(
    token: token,
    slug: productSlug,
    language: lang,
  );

  if (!context.mounted) return null;

  return result.fold((error) {
    _showToastAboveBottomSheet(context, message: error.message);
    return null;
  }, (product) => product);
}

Future<void> _animateFlyToCart({
  required BuildContext context,
  required Rect? sourceRect,
}) async {
  final fromRect = sourceRect;
  if (fromRect == null) return;

  final targetContext = CartFlyToBadgeAnchor.cartBadgeKey.currentContext;
  final targetRenderObject = targetContext?.findRenderObject();
  if (targetRenderObject is! RenderBox || !targetRenderObject.hasSize) return;
  final targetOffset = targetRenderObject.localToGlobal(Offset.zero);
  final targetRect = targetOffset & targetRenderObject.size;
  if (!context.mounted) return;

  await CartFlyToBadgeService.animate(
    context: context,
    fromRect: fromRect,
    toRect: targetRect,
  );
}

String _resolveVariantImage(
  HomeGraphqlProduct product,
  HomeGraphqlProductVariant? variant,
) {
  final selected = variant?.bestImageUrl.trim() ?? '';
  if (selected.isNotEmpty) return selected;
  return product.primaryVariantImageUrl.trim();
}

double _resolveUnitPrice(
  HomeGraphqlProductVariant? variant,
  HomeGraphqlProduct product,
) {
  if (variant != null) {
    final discounted = variant.discountedAmount.toDouble();
    final regular = variant.regularAmount.toDouble();
    return discounted > 0 ? discounted : regular;
  }
  return product.priceAmount.toDouble();
}

double _resolveOldPrice(
  HomeGraphqlProductVariant? variant,
  HomeGraphqlProduct product,
) {
  if (variant != null) {
    return variant.regularAmount.toDouble();
  }
  return product.originalPriceAmount.toDouble();
}

String _resolveCurrency(
  HomeGraphqlProductVariant? variant,
  HomeGraphqlProduct product,
) {
  final fromVariant = variant?.discountedPrice?.currencyCode.trim();
  if (fromVariant != null && fromVariant.isNotEmpty) {
    return fromVariant.toUpperCase();
  }
  final fallback = product.formattedCurrencyCode.trim();
  return fallback.isNotEmpty ? fallback.toUpperCase() : 'QAR';
}

String _resolveDirectVariantUuid(HomeGraphqlProduct product) {
  if (product.variantUuid?.trim().isNotEmpty == true) {
    return product.variantUuid!.trim();
  }
  if (product.displayableVariants.length == 1) {
    return product.displayableVariants.first.uuid.trim();
  }
  if (product.variants.length == 1) {
    return product.variants.first.uuid.trim();
  }
  return '';
}

HomeGraphqlProductVariant? _resolveDirectVariant(HomeGraphqlProduct product) {
  final directUuid = _resolveDirectVariantUuid(product).trim();
  if (directUuid.isEmpty) return null;

  for (final variant in product.variants) {
    if (variant.uuid.trim() == directUuid) return variant;
  }
  for (final variant in product.displayableVariants) {
    if (variant.uuid.trim() == directUuid) return variant;
  }
  return null;
}

Future<bool> _addToCart({
  required BuildContext context,
  required String productUuid,
  required String variantUuid,
  required int quantity,
}) async {
  final token = await sl<SecureCacheHelper>().getData(key: 'token');
  final result = await sl<CartRepository>().addToCart(
    token: token,
    productUuid: productUuid,
    variantUuid: variantUuid,
    quantity: quantity,
  );

  if (!context.mounted) return false;

  var success = false;
  result.fold(
    (error) {
      _showToastAboveBottomSheet(context, message: error.message);
    },
    (_) {
      success = true;
      sl<DashboardBadgeCountsNotifier>().refresh();
      CartRefreshNotifier.requestRefresh();
    },
  );
  return success;
}

class _QuickAddVariantSheet extends StatefulWidget {
  const _QuickAddVariantSheet({
    required this.product,
    required this.sourceRect,
  });

  final HomeGraphqlProduct product;
  final Rect? sourceRect;

  @override
  State<_QuickAddVariantSheet> createState() => _QuickAddVariantSheetState();
}

class _QuickAddResult {
  const _QuickAddResult({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final HomeGraphqlProduct product;
  final HomeGraphqlProductVariant variant;
  final int quantity;
}

class _QuickAddVariantSheetState extends State<_QuickAddVariantSheet> {
  late Map<String, String> _selectedAttributes;
  HomeGraphqlProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _applyInitialSelection();
  }

  void _applyInitialSelection() {
    final initialVariant = _resolveInitialVariant();
    _selectedVariant = initialVariant;
    _selectedAttributes = initialVariant == null
        ? <String, String>{}
        : _attributesForVariant(initialVariant);
    _quantity = 1;
  }

  HomeGraphqlProductVariant? _resolveInitialVariant() {
    final product = widget.product;
    final preferredUuid = product.variantUuid?.trim() ?? '';
    if (preferredUuid.isNotEmpty) {
      for (final variant in _displayableVariants()) {
        if (variant.uuid.trim() == preferredUuid) {
          return variant;
        }
      }
    }

    final displayable = _displayableVariants();
    if (displayable.length == 1) return displayable.first;
    if (displayable.isNotEmpty) return displayable.first;
    return null;
  }

  List<HomeGraphqlProductVariant> _displayableVariants() {
    return widget.product.displayableVariants;
  }

  Map<String, String> _attributesForVariant(HomeGraphqlProductVariant variant) {
    final lookup = <String, ({String name, String value})>{};
    for (final option in widget.product.options) {
      final optionName = option.name.trim();
      if (optionName.isEmpty) continue;
      for (final value in option.values) {
        final valueUuid = value.uuid.trim();
        final optionValue = value.value.trim();
        if (valueUuid.isEmpty || optionValue.isEmpty) continue;
        lookup[valueUuid] = (name: optionName, value: optionValue);
      }
    }

    final resolved = <String, String>{};
    for (final ref in variant.optionValues) {
      final mapped = lookup[ref.optionValueUuid.trim()];
      if (mapped == null || mapped.name.trim().isEmpty) continue;
      resolved[mapped.name] = mapped.value;
    }
    return resolved;
  }

  List<HomeGraphqlProductOption> _selectableOptions() {
    return widget.product.options
        .where((option) => _availableValuesForOption(option).length > 1)
        .toList(growable: false);
  }

  List<HomeGraphqlProductOption> _orderedAvailableOptions() {
    final available = _getAvailableAttributes();
    final options = widget.product.options
        .where((option) {
          final name = option.name.trim();
          final availableValues = _availableValuesForOption(option);
          return name.isNotEmpty &&
              available.containsKey(_normalizeAttributeName(name)) &&
              availableValues.isNotEmpty;
        })
        .toList(growable: false);
    options.sort((a, b) => a.position.compareTo(b.position));
    return options;
  }

  List<HomeGraphqlProductOptionValue> _availableValuesForOption(
    HomeGraphqlProductOption option,
  ) {
    final candidateValues = option.values
        .map((value) => value.value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final availableValues = VariantSelectionRules.availableValuesForOption(
      variants: _variantSnapshots(),
      optionName: option.name,
      optionValues: candidateValues,
    );
    final normalizedAvailable = availableValues
        .map(VariantSelectionRules.normalizeOptionValue)
        .toSet();
    return option.values
        .where(
          (value) => normalizedAvailable.contains(
            VariantSelectionRules.normalizeOptionValue(value.value),
          ),
        )
        .toList(growable: false);
  }

  Map<String, Set<String>> _getAvailableAttributes() {
    return VariantSelectionRules.availableAttributesFromVariants(
      _variantSnapshots(),
    );
  }

  Map<String, String> _normalizedSelectedAttributes() {
    return VariantSelectionRules.normalizeAttributeMap(_selectedAttributes);
  }

  Map<String, String> _normalizedVariantAttributes(
    HomeGraphqlProductVariant variant,
  ) {
    final lookup = <String, ({String name, String value})>{};
    for (final option in widget.product.options) {
      final optionName = _normalize(option.name);
      if (optionName.isEmpty) continue;
      for (final value in option.values) {
        final valueUuid = value.uuid.trim();
        final optionValue = _normalize(value.value);
        if (valueUuid.isEmpty || optionValue.isEmpty) continue;
        lookup[valueUuid] = (name: optionName, value: optionValue);
      }
    }

    final resolved = <String, String>{};
    for (final ref in variant.optionValues) {
      final mapped = lookup[ref.optionValueUuid.trim()];
      if (mapped == null || mapped.name.isEmpty || mapped.value.isEmpty) {
        continue;
      }
      resolved[mapped.name] = mapped.value;
    }
    return resolved;
  }

  String _normalizeAttributeName(String raw) {
    return VariantSelectionRules.normalizeAttributeName(raw);
  }

  String _normalizeOptionValue(String raw) {
    return VariantSelectionRules.normalizeOptionValue(raw);
  }

  bool _isColorAttributeName(String raw) {
    return VariantSelectionRules.isColorAttributeName(raw);
  }

  String? _findColorAttributeName() {
    for (final option in _orderedAvailableOptions()) {
      if (_isColorAttributeName(option.name)) {
        return option.name.trim();
      }
    }
    return null;
  }

  int _maxAllowedQuantity() => 99;

  bool _isVariantInStock(HomeGraphqlProductVariant variant) => true;

  HomeGraphqlProductVariant? _findMatchingVariant() {
    final selected = _normalizedSelectedAttributes();
    if (selected.isEmpty) return null;

    for (final variant in _displayableVariants()) {
      if (!_isVariantInStock(variant)) continue;
      final variantAttributes = _normalizedVariantAttributes(variant);
      if (variantAttributes.isEmpty) continue;

      if (VariantSelectionRules.matchesExactAttributes(
        selectedAttributes: selected,
        variantAttributes: variantAttributes,
      )) {
        return variant;
      }
    }
    return null;
  }

  bool _isOptionAvailable(String attrName, String option) {
    return VariantSelectionRules.isOptionAvailable(
      variants: _variantSnapshots(),
      selectedAttributes: _selectedAttributes,
      attrName: attrName,
      optionValue: option,
      colorAttributeName: _findColorAttributeName(),
    );
  }

  List<String> _availableColorOptionsForCurrentSelection({
    required String changedAttributeName,
  }) {
    final colorAttributeName = _findColorAttributeName();
    if (colorAttributeName == null) return const <String>[];

    final colorOption = widget.product.options.firstWhere(
      (option) =>
          _normalizeAttributeName(option.name) ==
          _normalizeAttributeName(colorAttributeName),
      orElse: () => const HomeGraphqlProductOption(
        uuid: '',
        name: '',
        position: 0,
        values: <HomeGraphqlProductOptionValue>[],
      ),
    );
    return VariantSelectionRules.availableColorOptionsForCurrentSelection(
      variants: _variantSnapshots(),
      selectedAttributes: _selectedAttributes,
      changedAttributeName: changedAttributeName,
      colorAttributeName: colorAttributeName,
      candidateValues: colorOption.values
          .map((value) => value.value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }

  HomeGraphqlProductVariant? _findFallbackVariantForNonColorSelection({
    required String changedAttributeName,
  }) {
    final colorAttributeName = _findColorAttributeName();
    if (colorAttributeName == null) return null;
    final snapshot =
        VariantSelectionRules.findFallbackVariantForNonColorSelection(
          variants: _variantSnapshots(),
          selectedAttributes: _selectedAttributes,
          changedAttributeName: changedAttributeName,
          colorAttributeName: colorAttributeName,
        );
    if (snapshot == null) return null;

    for (final variant in _displayableVariants()) {
      if (!_isVariantInStock(variant)) continue;
      final variantAttributes = _normalizedVariantAttributes(variant);
      if (variantAttributes.isEmpty) continue;
      if (VariantSelectionRules.matchesExactAttributes(
        selectedAttributes: variantAttributes,
        variantAttributes: snapshot.attributes,
      )) {
        return variant;
      }
    }
    return null;
  }

  List<VariantSelectionSnapshot> _variantSnapshots() {
    return _displayableVariants()
        .map(
          (variant) => VariantSelectionSnapshot(
            attributes: _normalizedVariantAttributes(variant),
            isInStock: _isVariantInStock(variant),
          ),
        )
        .toList(growable: false);
  }

  void _updateSelection(String attrName, String option) {
    setState(() {
      _selectedAttributes[attrName] = option;
      final colorAttributeName = _findColorAttributeName();
      final isColorSelection = _isColorAttributeName(attrName);

      _selectedVariant = _findMatchingVariant();

      if (!isColorSelection && colorAttributeName != null) {
        final availableColors = _availableColorOptionsForCurrentSelection(
          changedAttributeName: attrName,
        );
        if (availableColors.isNotEmpty) {
          final currentColor =
              _selectedAttributes[colorAttributeName]?.trim() ?? '';
          final normalizedCurrentColor = _normalizeOptionValue(currentColor);
          final hasCurrentColor = availableColors.any(
            (color) => _normalizeOptionValue(color) == normalizedCurrentColor,
          );
          final colorToSelect = hasCurrentColor
              ? currentColor
              : availableColors.first;
          _selectedAttributes[colorAttributeName] = colorToSelect.trim();
          _selectedVariant = _findMatchingVariant();
        } else if (_selectedVariant == null) {
          final fallback = _findFallbackVariantForNonColorSelection(
            changedAttributeName: attrName,
          );
          if (fallback != null) {
            _selectedVariant = fallback;
            _selectedAttributes = _attributesForVariant(fallback);
          }
        }
      }

      _quantity = _quantity.clamp(1, _maxAllowedQuantity());
    });
  }

  Future<void> _submit() async {
    if (_isAdding) return;

    final product = widget.product;
    final requiredNames = _selectableOptions()
        .map((option) => option.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final missing = requiredNames
        .where((name) {
          final value = _selectedAttributes[name] ?? '';
          return value.isEmpty;
        })
        .toList(growable: false);
    if (missing.isNotEmpty) {
      _showToastAboveBottomSheet(
        context,
        message: 'Please select: ${missing.join(', ')}',
      );
      return;
    }

    final selectedVariant = _findMatchingVariant();
    if (selectedVariant == null) {
      _showToastAboveBottomSheet(
        context,
        message: 'Please select a valid variant.',
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });
    final success = await _addToCart(
      context: context,
      productUuid: product.uuid,
      variantUuid: selectedVariant.uuid,
      quantity: _quantity,
    );
    if (!mounted) return;
    setState(() {
      _isAdding = false;
    });
    if (success) {
      Navigator.of(context).pop(
        _QuickAddResult(
          product: product,
          variant: selectedVariant,
          quantity: _quantity,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVariant = _selectedVariant ?? _findMatchingVariant();
    final availableOptions = _orderedAvailableOptions();

    return Container(
      margin: EdgeInsets.only(top: 28.h),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickAddVariantHeader(
                product: widget.product,
                selectedVariant: selectedVariant,
                onClose: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: 16.h),
              ...availableOptions.map((option) {
                final optionName = option.name.trim();
                final availableValues = _availableValuesForOption(option);
                if (optionName.isEmpty || availableValues.isEmpty) {
                  return const SizedBox.shrink();
                }
                final sortedValues = _sortOptionValues(
                  optionName,
                  availableValues,
                );
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        optionName,
                        style: TextStyle(
                          color: const Color(0xFF111827),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montes',
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sortedValues
                              .asMap()
                              .entries
                              .map((entry) {
                                final index = entry.key;
                                final value = entry.value;
                                final selected =
                                    _selectedAttributes[optionName] ==
                                    value.value;
                                final available = _isOptionAvailable(
                                  optionName,
                                  value.value,
                                );
                                final isColor = _isColorAttributeName(
                                  optionName,
                                );
                                final color = isColor
                                    ? ColorDetectionService.getColorFromText(
                                        value.value,
                                      )
                                    : null;

                                return Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    end: index == sortedValues.length - 1
                                        ? 0
                                        : 8.w,
                                  ),
                                  child: AppTapFeedback(
                                    onTap: available
                                        ? () => _updateSelection(
                                            optionName,
                                            value.value,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Opacity(
                                      opacity: available ? 1.0 : 0.5,
                                      child: color != null
                                          ? _buildColorBox(
                                              color,
                                              selected,
                                              value.value,
                                            )
                                          : _buildTextBox(
                                              value.value,
                                              selected,
                                              available,
                                            ),
                                    ),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              _buildQuantitySection(),
              SizedBox(height: 18.h),
              SizedBox(
                height: 46.h,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    textStyle: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montes',
                    ),
                  ),
                  child: _isAdding
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(S.of(context).add_to_cart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<HomeGraphqlProductOptionValue> _sortOptionValues(
    String optionName,
    List<HomeGraphqlProductOptionValue> values,
  ) {
    final sorted = [...values];
    if (_normalizeAttributeName(optionName) != 'size') {
      return sorted;
    }
    sorted.sort((a, b) {
      final left = _sizeSortIndex(a.value);
      final right = _sizeSortIndex(b.value);
      if (left != right) return left.compareTo(right);
      return a.position.compareTo(b.position);
    });
    return sorted;
  }

  int _sizeSortIndex(String raw) {
    const order = ['xs', 's', 'm', 'l', 'xl', 'xxl', 'xxxl'];
    final normalized = raw.trim().toLowerCase();
    final idx = order.indexOf(normalized);
    if (idx >= 0) return idx;
    final numeric = double.tryParse(normalized);
    if (numeric != null) return 1000 + numeric.round();
    return 10000 + normalized.hashCode.abs();
  }

  Widget _buildColorBox(Color color, bool isSelected, String colorName) {
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

  Widget _buildTextBox(String text, bool isSelected, bool isAvailable) {
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

  Color _getContrastColor(Color color) {
    final red = (color.r * 255.0).round().clamp(0, 255);
    final green = (color.g * 255.0).round().clamp(0, 255);
    final blue = (color.b * 255.0).round().clamp(0, 255);
    final brightness = (red * 299 + green * 587 + blue * 114) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  Widget _buildQuantitySection() {
    final canDecrease = _quantity > 1;
    final canIncrease = _quantity < _maxAllowedQuantity();
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
                onTap: () => setState(() => _quantity--),
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
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class _QuickAddVariantHeader extends StatelessWidget {
  const _QuickAddVariantHeader({
    required this.product,
    required this.selectedVariant,
    required this.onClose,
  });

  final HomeGraphqlProduct product;
  final HomeGraphqlProductVariant? selectedVariant;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveVariantImage(product, selectedVariant);
    final unitPrice = _resolveUnitPrice(selectedVariant, product);
    final oldPrice = _resolveOldPrice(selectedVariant, product);
    final currency = _resolveCurrency(selectedVariant, product);
    final hasDiscount = oldPrice > 0 && unitPrice > 0 && oldPrice != unitPrice;
    final title = product.title.trim().isNotEmpty
        ? product.title.trim()
        : product.slug.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: 72.w,
            height: 72.w,
            color: const Color(0xFFF3F4F6),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFF3F4F6)),
                    errorWidget: (_, __, ___) =>
                        Image.asset(Assets.imagesShoes, fit: BoxFit.cover),
                  )
                : Image.asset(Assets.imagesShoes, fit: BoxFit.cover),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Montes',
                  height: 1.25,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Text(
                    formatMoneyForDisplay(context, unitPrice, currency),
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montes',
                    ),
                  ),
                  if (hasDiscount) ...[
                    SizedBox(width: 8.w),
                    Text(
                      formatMoneyForDisplay(context, oldPrice, currency),
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montes',
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        AppTapFeedback(
          onTap: onClose,
          borderRadius: BorderRadius.circular(999.r),
          child: Container(
            width: 34.w,
            height: 34.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Icon(
              Icons.close,
              size: 18.sp,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showAddedToCartPreviewSheet({
  required BuildContext context,
  required HomeGraphqlProduct product,
  required HomeGraphqlProductVariant? variant,
  required int quantity,
}) async {
  if (!context.mounted) return;
  final selectedVariant = variant;
  final previewImage = _resolveVariantImage(product, selectedVariant);
  final unitPrice = _resolveUnitPrice(selectedVariant, product);
  final currency = _resolveCurrency(selectedVariant, product);
  final title = product.title.trim().isNotEmpty
      ? product.title.trim()
      : product.slug.trim();
  final optionPairs = _resolveOptionPairs(product, selectedVariant);
  final totalPrice = unitPrice * quantity;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        margin: EdgeInsets.only(top: 24.h),
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      Assets.imagesIconsInCartSuccess,
                      width: 24.w,
                      height: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'تمت الإضافة إلى السلة' : 'Added to cart',
                          style: TextStyle(
                            color: const Color(0xFF111827),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montes',
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isArabic
                              ? 'يمكنك متابعة التسوق أو الانتقال إلى السلة.'
                              : 'You can continue shopping or go to your cart.',
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Montes',
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 34.w,
                      height: 34.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        width: 92.w,
                        height: 92.w,
                        color: const Color(0xFFE9EEF3),
                        child: previewImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: previewImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: const Color(0xFFE9EEF3)),
                                errorWidget: (_, __, ___) => Image.asset(
                                  Assets.imagesShoes,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                Assets.imagesShoes,
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
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF111827),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montes',
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (optionPairs.isNotEmpty)
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: optionPairs.map((pair) {
                                final label = pair.$1.isNotEmpty
                                    ? '${pair.$1}: '
                                    : '';
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999.r),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Text(
                                    '$label${pair.$2}',
                                    style: TextStyle(
                                      color: const Color(0xFF374151),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Montes',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              _PreviewStatPill(
                                label: isArabic ? 'الكمية' : 'Qty',
                                value: formatLocalizedNumber(context, quantity),
                              ),
                              SizedBox(width: 8.w),
                              _PreviewStatPill(
                                label: isArabic ? 'السعر' : 'Price',
                                value: formatMoneyForDisplay(
                                  context,
                                  unitPrice,
                                  currency,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '${isArabic ? 'الإجمالي' : 'Total'}: ${formatMoneyForDisplay(context, totalPrice, currency)}',
                            style: TextStyle(
                              color: const Color(0xFF111827),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montes',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(Icons.shopping_bag_outlined, size: 18.sp),
                      label: Text(
                        isArabic ? 'متابعة التسوق' : 'Continue shopping',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        foregroundColor: const Color(0xFF111827),
                        minimumSize: Size.fromHeight(48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        textStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montes',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        HomeScreen.homeKey.currentState
                            ?.refreshWishListAndCartList();
                        CartRefreshNotifier.requestRefresh();
                        GoRouter.of(
                          context,
                        ).go(AppRouter.selectingFromBottomNavBarCartTab);
                      },
                      icon: Icon(Icons.shopping_cart_outlined, size: 18.sp),
                      label: Text(isArabic ? 'اذهب إلى السلة' : 'Go to cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        textStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montes',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<(String, String)> _resolveOptionPairs(
  HomeGraphqlProduct product,
  HomeGraphqlProductVariant? variant,
) {
  final selectedValueUuids =
      variant?.optionValues
          .map((entry) => entry.optionValueUuid.trim())
          .where((value) => value.isNotEmpty)
          .toSet() ??
      <String>{};
  if (selectedValueUuids.isEmpty) return const <(String, String)>[];

  final pairs = <(String, String)>[];
  for (final option in product.options) {
    final optionName = option.name.trim();
    HomeGraphqlProductOptionValue? matchedValue;
    for (final value in option.values) {
      if (selectedValueUuids.contains(value.uuid.trim())) {
        matchedValue = value;
        break;
      }
    }
    if (matchedValue == null) continue;
    if (optionName.isEmpty && matchedValue.value.trim().isEmpty) continue;
    pairs.add((optionName, matchedValue.value.trim()));
  }
  return pairs;
}

List<HomeGraphqlProductOption> _selectableOptions(HomeGraphqlProduct product) {
  return product.options
      .where((option) => option.values.length > 1)
      .toList(growable: false);
}

void _showToastAboveBottomSheet(
  BuildContext context, {
  required String message,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      return Positioned(
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.paddingOf(overlayContext).bottom + 22.h,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E191B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE16B6D)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), () {
    entry.remove();
  });
}

class _PreviewStatPill extends StatelessWidget {
  const _PreviewStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montes',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montes',
            ),
          ),
        ],
      ),
    );
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
