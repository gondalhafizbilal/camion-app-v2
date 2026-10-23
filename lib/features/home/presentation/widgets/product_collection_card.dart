import 'dart:async';

import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/discount_percentage_badge.dart';
import 'package:camion/config/widgets/formatted_price_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/presentation/widgets/listing_quick_add_flow.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

enum ProductCollectionCardType { compact, expanded }

class ProductCollectionCard extends StatelessWidget {
  static const double compactCardWidth = 170;
  static const double compactCardHeight = 336;
  static const double compactImageHeight = 230;
  static const double expandedCardWidth = 344;
  static const double expandedCardHeight = 573.51513671875;

  const ProductCollectionCard({
    super.key,
    required this.productId,
    required this.productSlug,
    this.selectedVariantUuid = '',
    required this.name,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.favoritesLabel,
    required this.reviewsLabel,
    required this.onTap,
    this.currencyCode = '',
    this.oldPriceCurrencyCode,
    this.showOldPriceWhenSame = false,
    this.imageUrl,
    this.imageAssetPath,
    this.campaignLabel = 'Special ...',
    this.campaignEndsAt,
    this.showCampaignTimerPreview = false,
    this.width,
    this.isInitiallyInWishList = false,
    this.wishlistEnabled = false,
    this.forceIsInWishList,
    this.onBasketTap,
    this.type = ProductCollectionCardType.compact,
  });

  final String productId;
  final String productSlug;
  final String selectedVariantUuid;
  final String name;
  final String subtitle;
  final String price;
  final String oldPrice;
  final String favoritesLabel;
  final String reviewsLabel;
  final String? imageUrl;
  final String? imageAssetPath;
  final String campaignLabel;
  final DateTime? campaignEndsAt;
  final bool showCampaignTimerPreview;
  final double? width;
  final VoidCallback onTap;
  final String currencyCode;
  final String? oldPriceCurrencyCode;
  final bool showOldPriceWhenSame;
  final bool isInitiallyInWishList;
  final bool wishlistEnabled;
  final bool? forceIsInWishList;
  final FutureOr<void> Function(BuildContext context)? onBasketTap;
  final ProductCollectionCardType type;

  bool get _isExpanded => type == ProductCollectionCardType.expanded;

  int get _discountPercentage {
    final parsedCurrent = double.tryParse(price.trim().replaceAll(',', ''));
    final parsedOld = double.tryParse(oldPrice.trim().replaceAll(',', ''));
    if (parsedCurrent == null || parsedOld == null) return 0;
    if (parsedCurrent <= 0 || parsedOld <= parsedCurrent) return 0;
    return (((parsedOld - parsedCurrent) / parsedOld) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(5.r);

    return AppTapFeedback(
      onTap: () {
        unawaited(
          sl<AppsFlyerService>().logConversionEvent(
            'select_item',
            eventParams: {
              'product_id': productId.trim(),
              'variant_id': selectedVariantUuid.trim(),
              'category': 'product',
              'item_value':
                  double.tryParse(price.trim().replaceAll(',', '')) ?? 0,
              if (currencyCode.trim().isNotEmpty)
                'currency': currencyCode.trim().toUpperCase(),
            },
          ),
        );
        onTap();
      },
      borderRadius: radius,
      child: Container(
        margin: EdgeInsets.fromLTRB(1.w, 1.h, 1.w, 6.h),
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              spreadRadius: 1,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: _isExpanded
            ? _buildExpandedLayout(context)
            : _buildCompactLayout(context),
      ),
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5.r),
                        topRight: Radius.circular(5.r),
                      ),
                      child: _buildImage(),
                    ),
                    if (campaignEndsAt != null || showCampaignTimerPreview)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _CampaignCountdownBadge(
                          endsAt: campaignEndsAt,
                          showPreviewTimer: showCampaignTimerPreview,
                          compact: false,
                          fullWidth: true,
                          campaignLabel: campaignLabel,
                        ),
                      ),
                    if (wishlistEnabled)
                      Positioned(
                        top: 12.h,
                        right: 12.w,
                        child: _WishlistButton(
                          productId: productId,
                          selectedVariantUuid: selectedVariantUuid,
                          productName: name,
                          price: price,
                          imageUrl: imageUrl,
                          initiallyInWishList: isInitiallyInWishList,
                          wishlistEnabled: wishlistEnabled,
                          forceIsInWishList: forceIsInWishList,
                          iconSize: 22.sp,
                          buttonSize: Size(24.w, 24.w),
                        ),
                      ),
                    PositionedDirectional(
                      end: 10.w,
                      bottom:
                          (campaignEndsAt != null || showCampaignTimerPreview)
                          ? 52.h
                          : 10.h,
                      child: ListingBasketButton(
                        onTap:
                            onBasketTap ??
                            (buttonContext) => handleListingQuickAddTap(
                              buttonContext,
                              productSlug: productSlug,
                              showAddedToCartPreview: false,
                            ),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
              child: _buildDetailsContent(isCompact: false, useSpacer: false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compactImageHeight.h,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE7E7E7), width: 1.w),
                    left: BorderSide(
                      color: const Color(0xFFE7E7E7),
                      width: 1.w,
                    ),
                    right: BorderSide(
                      color: const Color(0xFFE7E7E7),
                      width: 1.w,
                    ),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5.r),
                    topRight: Radius.circular(5.r),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5.r),
                    topRight: Radius.circular(5.r),
                  ),
                  child: _buildImage(),
                ),
              ),
              if (campaignEndsAt != null || showCampaignTimerPreview)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _CampaignCountdownBadge(
                    endsAt: campaignEndsAt,
                    showPreviewTimer: showCampaignTimerPreview,
                    compact: true,
                    fullWidth: true,
                    campaignLabel: campaignLabel,
                  ),
                ),
              if (wishlistEnabled)
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: _WishlistButton(
                    productId: productId,
                    selectedVariantUuid: selectedVariantUuid,
                    productName: name,
                    price: price,
                    imageUrl: imageUrl,
                    initiallyInWishList: isInitiallyInWishList,
                    wishlistEnabled: wishlistEnabled,
                    forceIsInWishList: forceIsInWishList,
                    iconSize: 22.sp,
                    buttonSize: Size(24.w, 24.w),
                  ),
                ),
              PositionedDirectional(
                end: 10.w,
                bottom: (campaignEndsAt != null || showCampaignTimerPreview)
                    ? 46.h
                    : 10.h,
                child: ListingBasketButton(
                  onTap:
                      onBasketTap ??
                      (buttonContext) => handleListingQuickAddTap(
                        buttonContext,
                        productSlug: productSlug,
                        showAddedToCartPreview: false,
                      ),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactTight = constraints.maxHeight < 80.h;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  10.w,
                  isCompactTight ? 5.h : 8.h,
                  10.w,
                  isCompactTight ? 5.h : 8.h,
                ),
                child: _buildDetailsContent(isCompact: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsContent({
    required bool isCompact,
    bool useSpacer = true,
  }) {
    final resolvedCurrencyCode = resolveCurrencyCode([currencyCode]);
    final favoriteParts = _splitBulletLabel(favoritesLabel.replaceAll('❤', ''));
    final reviewData = _buildReviewDisplayData(reviewsLabel);
    final parsedCurrentPrice = double.tryParse(price.trim());
    final parsedOldPrice = double.tryParse(oldPrice.trim());
    final hasCurrentPrice =
        parsedCurrentPrice != null && parsedCurrentPrice > 0;
    final hasOldPrice = oldPrice.trim().isNotEmpty
        ? parsedOldPrice != null && parsedCurrentPrice != null
              ? (showOldPriceWhenSame || parsedOldPrice != parsedCurrentPrice)
              : (showOldPriceWhenSame || oldPrice.trim() != price.trim())
        : false;
    final compactNameSize = 9.5.sp;
    final compactBodySize = 7.5.sp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black,
            fontSize: isCompact ? compactNameSize : 16.sp,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        SizedBox(height: isCompact ? 3.h : 10.h),
        Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: const Color(0xFFD72631),
              size: isCompact ? 9.sp : 15.sp,
            ),
            SizedBox(width: isCompact ? 2.w : 6.w),
            Text(
              favoriteParts.$1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: isCompact ? compactBodySize : 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: isCompact ? 3.w : 8.w),
            Text(
              '•',
              style: TextStyle(
                color: Colors.black,
                fontSize: isCompact ? compactBodySize : 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: isCompact ? 3.w : 8.w),
            Expanded(
              child: Text(
                favoriteParts.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isCompact ? compactBodySize : 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 3.h : 10.h),
        Row(
          children: [
            Text(
              reviewData.ratingText,
              style: TextStyle(
                color: Colors.black,
                fontSize: isCompact ? compactBodySize : 10.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: isCompact ? 3.w : 6.w),
            ...List.generate(
              5,
              (index) => Padding(
                padding: EdgeInsets.only(right: isCompact ? 0.5.w : 2.w),
                child: Icon(
                  index < reviewData.filledStars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: index < reviewData.filledStars
                      ? const Color(0xFFF5C451)
                      : const Color(0xFFBEBEBE),
                  size: isCompact ? 7.sp : 11.sp,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 3.w : 8.w),
            Text(
              '•',
              style: TextStyle(
                color: const Color(0xFF7A7A7A),
                fontSize: isCompact ? compactBodySize : 10.sp,
              ),
            ),
            SizedBox(width: isCompact ? 3.w : 8.w),
            Expanded(
              child: Text(
                reviewData.countText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF7A7A7A),
                  fontSize: isCompact ? compactBodySize : 10.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        if (useSpacer)
          const Spacer()
        else
          SizedBox(height: isCompact ? 3.h : 10.h),
        if (hasCurrentPrice)
          Row(
            children: [
              if (_discountPercentage > 0) ...[
                DiscountPercentageBadge(
                  percentage: _discountPercentage,
                  compact: isCompact,
                ),
                SizedBox(width: isCompact ? 3.w : 4.w),
              ],
              Flexible(
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: FormattedPriceText(
                    amountText: price,
                    currencyText: resolvedCurrencyCode,
                    mainStyle: TextStyle(
                      color: Colors.black,
                      fontSize: isCompact ? 10.sp : 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                    minorStyle: TextStyle(
                      color: Colors.black,
                      fontSize: isCompact ? 8.sp : 10.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ),
              if (hasOldPrice) ...[
                SizedBox(width: isCompact ? 3.w : 4.w),
                Flexible(
                  fit: FlexFit.loose,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: FormattedPriceText(
                      amountText: oldPrice,
                      currencyText: '',
                      mainStyle: TextStyle(
                        color: const Color(0x99000000),
                        fontSize: isCompact ? 10.sp : 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1,
                        decoration: TextDecoration.lineThrough,
                      ),
                      minorStyle: TextStyle(
                        color: const Color(0x99000000),
                        fontSize: isCompact ? 8.sp : 10.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w600,
                        height: 1,
                        decoration: TextDecoration.lineThrough,
                      ),
                      spaceBeforeCurrency: false,
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  (String, String) _splitBulletLabel(String label) {
    final cleaned = label.trim();
    final parts = cleaned.split('•');
    if (parts.length >= 2) {
      return (parts.first.trim(), parts.sublist(1).join('•').trim());
    }
    return (cleaned, '');
  }

  ({String ratingText, String countText, int filledStars})
  _buildReviewDisplayData(String label) {
    final cleaned = label.replaceAll('★★★★★', '').trim();
    if (cleaned.isEmpty) {
      return (ratingText: '0.0', countText: '0', filledStars: 0);
    }

    final parts = _splitBulletLabel(cleaned);
    final ratingText = parts.$1.trim().isEmpty ? '0.0' : parts.$1.trim();
    var countText = parts.$2.trim().isEmpty ? '0' : parts.$2.trim();
    final reviewCountText = parts.$2.trim();
    int reviewCount = 0;
    if (reviewCountText.isNotEmpty) {
      final countMatch = RegExp(r'\d+').firstMatch(reviewCountText);
      if (countMatch != null) {
        final count = int.tryParse(countMatch.group(0) ?? '');
        if (count != null) reviewCount = count;
      }
    }
    if (parts.$2.trim().isEmpty) {
      countText = reviewCount.toString();
    }

    final ratingValue = (double.tryParse(parts.$1.trim()) ?? 0).clamp(0, 5);
    final stars = ratingValue.round().clamp(0, 5);
    return (ratingText: ratingText, countText: countText, filledStars: stars);
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
        errorWidget: (_, __, ___) => Image.asset(
          imageAssetPath ?? Assets.imagesShoes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return Image.asset(
      imageAssetPath ?? Assets.imagesShoes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _CampaignCountdownBadge extends StatefulWidget {
  const _CampaignCountdownBadge({
    required this.endsAt,
    required this.showPreviewTimer,
    required this.compact,
    required this.fullWidth,
    required this.campaignLabel,
  });

  final DateTime? endsAt;
  final bool showPreviewTimer;
  final bool compact;
  final bool fullWidth;
  final String campaignLabel;

  @override
  State<_CampaignCountdownBadge> createState() =>
      _CampaignCountdownBadgeState();
}

class _CampaignCountdownBadgeState extends State<_CampaignCountdownBadge> {
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
  void didUpdateWidget(covariant _CampaignCountdownBadge oldWidget) {
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
    final padded = [
      '${_twoDigits(hours)}h',
      '${_twoDigits(minutes)}m',
      '${_twoDigits(seconds)}s',
    ];
    return padded.join(' : ');
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _compactLabel() {
    final label = widget.campaignLabel.trim();
    if (label.isEmpty) return label;
    if (label.length <= 9) return label;
    return '${label.substring(0, 9)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    final height = widget.compact ? 26.h : 30.h;
    final width = widget.fullWidth
        ? double.infinity
        : widget.compact
        ? 148.w
        : 178.w;
    final labelWidth = widget.compact ? 72.w : 84.w;
    final fontSize = widget.compact ? 7.8.sp : 9.sp;
    final borderRadius = widget.fullWidth
        ? BorderRadius.zero
        : BorderRadius.circular(8.r);

    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _redGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x307A1016),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: widget.fullWidth
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(horizontal: widget.compact ? 3.w : 5.w),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipPath(
              clipper: _CampaignLabelClipper(
                textDirection: Directionality.of(context),
              ),
              child: SizedBox(
                width: labelWidth,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: _deepRedGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _compactLabel(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: widget.compact ? 4.w : 6.w),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: widget.compact ? 10.sp : 11.sp,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        _format(_remaining),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.compact ? 7.9.sp : 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                          height: 1,
                          shadows: const [
                            Shadow(
                              color: Color(0x33000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 6.w),
          ],
        ),
      ),
    );
  }
}

class _CampaignLabelClipper extends CustomClipper<Path> {
  const _CampaignLabelClipper({required this.textDirection});

  final TextDirection textDirection;

  @override
  Path getClip(Size size) {
    final path = Path();
    final isRtl = textDirection == TextDirection.rtl;
    final tail = size.width * (isRtl ? 0.08 : 0.92);

    if (isRtl) {
      path.moveTo(size.width, 0);
      path.lineTo(tail, 0);
      path.lineTo(0, size.height * 0.5);
      path.lineTo(tail, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(tail, 0);
      path.lineTo(size.width, size.height * 0.5);
      path.lineTo(tail, size.height);
      path.lineTo(0, size.height);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CampaignLabelClipper oldClipper) {
    return oldClipper.textDirection != textDirection;
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.productId,
    required this.selectedVariantUuid,
    required this.productName,
    required this.price,
    required this.initiallyInWishList,
    required this.wishlistEnabled,
    required this.iconSize,
    required this.buttonSize,
    this.forceIsInWishList,
    this.imageUrl,
  });

  final String productId;
  final String selectedVariantUuid;
  final String productName;
  final String price;
  final String? imageUrl;
  final bool initiallyInWishList;
  final bool wishlistEnabled;
  final double iconSize;
  final Size buttonSize;
  final bool? forceIsInWishList;

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty || productId == '0') {
      return _WishlistIconContainer(
        isInWishList: false,
        iconSize: iconSize,
        buttonSize: buttonSize,
      );
    }

    if (!wishlistEnabled) {
      final isInWishList = forceIsInWishList ?? initiallyInWishList;
      return AppTapFeedback(
        onTap: null,
        customBorder: const CircleBorder(),
        child: _WishlistIconContainer(
          isInWishList: isInWishList,
          iconSize: iconSize,
          buttonSize: buttonSize,
        ),
      );
    }

    return BlocBuilder<GetWishListCubit, GetWishListState>(
      builder: (context, state) {
        final bool isInWishList =
            forceIsInWishList ??
            (state is GetWishListSuccess
                ? state.wishLists.any((item) => item.productId == productId)
                : initiallyInWishList);

        return AppTapFeedback(
          onTap: wishlistEnabled
              ? () => _handleWishlistTap(context, isInWishList)
              : null,
          customBorder: const CircleBorder(),
          child: _WishlistIconContainer(
            isInWishList: isInWishList,
            iconSize: iconSize,
            buttonSize: buttonSize,
          ),
        );
      },
    );
  }

  Future<void> _handleWishlistTap(
    BuildContext context,
    bool isInWishList,
  ) async {
    final canProceed = await AppNavigator.ensureAuthenticatedCustomer(context);
    if (!canProceed) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final wishListCubit = context.read<GetWishListCubit>();
    final addToWishListCubit = context.read<AddToWishListCubit>();

    if (isInWishList) {
      await wishListCubit.removeFromWishList(productId: productId);
    } else {
      await addToWishListCubit.addtoWishList(
        productId: productId,
        variantUuid: selectedVariantUuid.trim().isEmpty
            ? null
            : selectedVariantUuid.trim(),
        title: productName,
        price: price,
        image: imageUrl ?? '',
      );
    }

    if (!context.mounted) {
      return;
    }
    await wishListCubit.getWishList();
  }
}

class _WishlistIconContainer extends StatelessWidget {
  const _WishlistIconContainer({
    required this.isInWishList,
    required this.iconSize,
    required this.buttonSize,
  });

  final bool isInWishList;
  final double iconSize;
  final Size buttonSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonSize.width,
      height: buttonSize.height,
      decoration: BoxDecoration(
        color: isInWishList ? const Color(0x1A000000) : null,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x1A000000), width: 1),
      ),
      child: Center(
        child: isInWishList
            ? SvgPicture.asset(
                Assets.imagesIconsNewwwActiveHeart,
                width: iconSize * 0.82,
                height: iconSize * 0.82,
              )
            : Image.asset(
                Assets.imagesIconsWishlistOutlineHeart,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
