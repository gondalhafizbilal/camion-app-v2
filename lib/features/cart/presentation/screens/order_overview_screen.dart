import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/config/widgets/bottom_nav_bar.dart';
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/features/order_status/data/models/order_response_model/order_response_model.dart'
    as order_response;
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class OrderOverviewScreen extends StatefulWidget {
  const OrderOverviewScreen({
    super.key,
    required this.orderResponse,
    this.subTotal = 0,
    this.shipping = 0,
    this.discountTotal = 0,
    this.total = 0,
  });

  final order_response.OrderResponse orderResponse;
  final double subTotal;
  final double shipping;
  final double discountTotal;
  final double total;

  @override
  State<OrderOverviewScreen> createState() => _OrderOverviewScreenState();
}

class _OrderOverviewScreenState extends State<OrderOverviewScreen> {
  final HomeRepository _homeRepository = sl<HomeRepository>();
  List<HomeGraphqlProduct> popularProducts = [];
  bool _popularLoading = true;
  bool _popularGridView = true;
  String? _estimatedDeliveryText;
  bool _estimatedDeliveryLoading = true;
  String? _lastLocaleCode;
  int _popularFetchSequence = 0;
  int _estimateFetchSequence = 0;

  @override
  void initState() {
    super.initState();
    _loadPopularProducts();
    _loadEstimatedDelivery();
  }

  Future<void> _loadPopularProducts({int itemsPerPage = 4}) async {
    final fetchVersion = ++_popularFetchSequence;
    final languageCode =
        sl<CacheHelper>().getDataString(key: 'languageCode') ?? '';
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = ApiLocaleMapper.toGraphqlLocale(languageCode);

    final result = await _homeRepository.getPopularGraphqlProducts(
      token: token,
      language: language,
      pageNumber: 1,
      itemsPerPage: itemsPerPage,
    );
    if (!mounted || fetchVersion != _popularFetchSequence) return;

    result.fold(
      (_) => setState(() {
        popularProducts = const <HomeGraphqlProduct>[];
        _popularLoading = false;
      }),
      (products) => setState(() {
        popularProducts = products;
        _popularLoading = false;
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (_lastLocaleCode == null) {
      _lastLocaleCode = localeCode;
      return;
    }
    if (_lastLocaleCode == localeCode) {
      return;
    }
    _lastLocaleCode = localeCode;
    setState(() {
      _popularLoading = true;
      popularProducts = const <HomeGraphqlProduct>[];
      _estimatedDeliveryLoading = true;
    });
    _loadPopularProducts();
    _loadEstimatedDelivery();
  }

  Future<void> _loadEstimatedDelivery() async {
    final fetchVersion = ++_estimateFetchSequence;
    final order = widget.orderResponse.data.order;
    final directEta = order.eta.trim();
    if (directEta.isNotEmpty) {
      if (!mounted || fetchVersion != _estimateFetchSequence) return;
      setState(() {
        _estimatedDeliveryText = directEta;
        _estimatedDeliveryLoading = false;
      });
      return;
    }

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final orderId = order.id.trim();
    if (!mounted || fetchVersion != _estimateFetchSequence) return;
    if (token == null || token.isEmpty || orderId.isEmpty) {
      setState(() {
        _estimatedDeliveryText = null;
        _estimatedDeliveryLoading = false;
      });
      return;
    }

    final orderDetailsResult = await sl<OrderStatusRepository>()
        .getCurrentCustomerOrder(token: token, uuid: orderId);
    if (!mounted || fetchVersion != _estimateFetchSequence) return;
    final orderDetailsEta = orderDetailsResult.fold(
      (_) => '',
      (orderDetails) => orderDetails.eta.trim(),
    );
    if (orderDetailsEta.isNotEmpty) {
      setState(() {
        _estimatedDeliveryText = orderDetailsEta;
        _estimatedDeliveryLoading = false;
      });
      return;
    }

    final trackingResult = await sl<OrderStatusRepository>().getOrderTracking(
      token: token,
      orderId: orderId,
    );
    if (!mounted || fetchVersion != _estimateFetchSequence) return;
    final trackingEstimate = trackingResult.fold(
      (_) => '',
      (tracking) => _extractTrackingEstimate(tracking.data.trackingItems),
    );
    setState(() {
      _estimatedDeliveryText = trackingEstimate.trim().isEmpty
          ? null
          : trackingEstimate.trim();
      _estimatedDeliveryLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final order = widget.orderResponse.data.order;
    final buttonTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montes',
      height: 24 / 18,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _goToCart();
        },
        child: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.order_overview,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montes',
                                height: 40 / 20,
                              ),
                            ),
                          ),
                          AppTapFeedback(
                            onTap: () => openRecentSearchSheet(context),
                            borderRadius: BorderRadius.circular(999.r),
                            child: Padding(
                              padding: EdgeInsets.all(6.r),
                              child: Image.asset(
                                'assets/images/searchicon.png',
                                width: 28.w,
                                height: 28.h,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          NotificationBellWithBadge(
                            onTap: () =>
                                AppNavigator.openNotificationsOrLogin(context),
                            borderRadius: BorderRadius.circular(999.r),
                            childPadding: EdgeInsets.all(6.r),
                            width: 40.w,
                            height: 40.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 36.h)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        s.order_overview_description,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Montes',
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 38.h)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        constraints: BoxConstraints(minHeight: 308.h),
                        padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 18.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72.w,
                              height: 72.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD72631),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 34.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              s.payment_has_been_confirmed,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montes',
                                height: 24 / 16,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              s.order_overview_description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Montes',
                                height: 18 / 12,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoColumn(
                                    title: s.order_number,
                                    value:
                                        '#${order.wcOrderId == 0 ? order.id : order.wcOrderId}',
                                  ),
                                ),
                                SizedBox(width: 18.w),
                                Expanded(
                                  child: _InfoColumn(
                                    title: s.estimated_delivery,
                                    value: _estimatedDeliveryDisplayValue(),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: 295.w,
                              child: CustomElevatedButton(
                                onPressed: () => _trackOrder(order),
                                height: 50.h,
                                backgroundColor: Colors.white,
                                borderColor: const Color(0xFFD72631),
                                textColor: const Color(0xFFD72631),
                                elevation: 0,
                                child: Text(
                                  s.track_your_order,
                                  style: TextStyle(
                                    color: const Color(0xFFD72631),
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
                  SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: CustomElevatedButton(
                        onPressed: _goToHome,
                        height: 62.h,
                        backgroundColor: const Color(0xFFD72631),
                        elevation: 0,
                        child: Text(s.back_to_homepage, style: buttonTextStyle),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 36.h)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).popular_products,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montes',
                                height: 24 / 20,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(
                              AppRouter.homeSectionDetails,
                              extra: {
                                'title': S.of(context).popular_products,
                                'section': 'popular',
                              },
                            ),
                            child: Text(
                              S.of(context).more,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                decoration: TextDecoration.underline,
                                fontFamily: 'Montes',
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _popularGridView = false),
                            child: Opacity(
                              opacity: _popularGridView ? 0.6 : 1,
                              child: Image.asset(
                                'assets/images/sorticon2.png',
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _popularGridView = true),
                            child: Opacity(
                              opacity: _popularGridView ? 1 : 0.6,
                              child: Image.asset(
                                'assets/images/sorticon.png',
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                  ..._buildPopularProductsSection(),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNavBar(
                currentIndex: -1,
                enableCartBadgeAnchor: false,
                onTap: (index) => context.go(
                  '${AppRouter.selectingFromBottomNavBar}?tab=$index',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPopularProductsSection() {
    if (_popularLoading && popularProducts.isEmpty) {
      return const [SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    if (popularProducts.isEmpty) {
      return const [SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    return [
      if (_popularGridView)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 130.h),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 8.w,
              mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
            ),
            itemCount: popularProducts.length,
            itemBuilder: (context, index) {
              final product = popularProducts[index];
              return ProductCollectionCard(
                productId: product.uuid,
                productSlug: product.slug,
                name: product.title,
                subtitle: ProductDescriptionFormatter.resolveShort(
                  brief: product.brief,
                  descriptionHtml: product.descriptionHtml,
                  description: product.description,
                  fallback: S.of(context).description,
                ),
                price: product.formattedPrice,
                oldPrice: product.formattedOriginalPrice,
                currencyCode: product.formattedCurrencyCode,
                favoritesLabel:
                    '${formatLocalizedNumber(context, product.likesCount)}  •  ${S.of(context).favorites}',
                reviewsLabel:
                    '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${S.of(context).reviews}',
                imageUrl: product.primaryVariantImageUrl,
                imageAssetPath: Assets.imagesShoes,
                isInitiallyInWishList: false,
                wishlistEnabled: false,
                onTap: () => context.push(
                  AppRouter.productDetails,
                  extra: {
                    'id': product.uuid,
                    'slug': product.slug,
                    'selectedVariantUuid': product.variantUuid ?? '',
                  },
                ),
              );
            },
          ),
        )
      else
        SliverToBoxAdapter(
          child: SizedBox(
            height: 580.h,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 28.w, 130.h),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: popularProducts.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                return SizedBox(
                  width: ProductCollectionCard.expandedCardWidth.w,
                  child: ProductCollectionCard(
                    productId: product.uuid,
                    productSlug: product.slug,
                    type: ProductCollectionCardType.expanded,
                    width: ProductCollectionCard.expandedCardWidth.w,
                    name: product.title,
                    subtitle: ProductDescriptionFormatter.resolveShort(
                      brief: product.brief,
                      descriptionHtml: product.descriptionHtml,
                      description: product.description,
                      fallback: S.of(context).description,
                    ),
                    price: product.formattedPrice,
                    oldPrice: product.formattedOriginalPrice,
                    currencyCode: product.formattedCurrencyCode,
                    favoritesLabel:
                        '${formatLocalizedNumber(context, product.likesCount)}  •  ${S.of(context).favorites}',
                    reviewsLabel:
                        '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${S.of(context).reviews}',
                    imageUrl: product.primaryVariantImageUrl,
                    imageAssetPath: Assets.imagesShoes,
                    isInitiallyInWishList: false,
                    wishlistEnabled: false,
                    onTap: () => context.push(
                      AppRouter.productDetails,
                      extra: {
                        'id': product.uuid,
                        'slug': product.slug,
                        'selectedVariantUuid': product.variantUuid ?? '',
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    ];
  }

  void _trackOrder(order_response.Order order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    CartRefreshNotifier.requestRefresh();
    context.push(
      AppRouter.orderTrackingWebPage,
      extra: {
        'orderId': order.id,
        'orderNumber': '#${order.wcOrderId == 0 ? order.id : order.wcOrderId}',
        'productTitle': firstItem?.title,
        'variantTitle': _variantTitleFromOrderItem(firstItem),
        'productImage': firstItem?.image,
        'productId': firstItem?.productId,
      },
    );
  }

  String? _variantTitleFromOrderItem(order_response.OrderItem? item) {
    if (item == null) return null;
    for (final variation in item.variation) {
      final map = variation is Map
          ? variation.cast<String, dynamic>()
          : const <String, dynamic>{};
      final attribute = map['attribute']?.toString().trim().toLowerCase() ?? '';
      if (attribute != 'variant') continue;
      final value = map['value']?.toString().trim() ?? '';
      return value.isEmpty ? null : value;
    }
    return null;
  }

  void _goToCart() {
    CartRefreshNotifier.requestRefresh();
    AppNavigator.rememberCartBackTarget(context);
    context.go(AppRouter.selectingFromBottomNavBarCartTab);
  }

  void _goToHome() {
    CartRefreshNotifier.requestRefresh();
    context.go(AppRouter.selectingFromBottomNavBar);
  }

  String _estimatedDeliveryDisplayValue() {
    if (_estimatedDeliveryLoading) return '...';
    final value = _estimatedDeliveryText?.trim() ?? '';
    if (value.isEmpty) return '--';
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return _localizedEstimatedDelivery(value, isArabic: isArabic);
  }

  String _localizedEstimatedDelivery(String value, {required bool isArabic}) {
    if (!isArabic) return value;

    final lowerValue = value.toLowerCase();
    final rangeMatch = RegExp(r'(\d+)\s*[-–—]\s*(\d+)').firstMatch(value);
    if (rangeMatch != null &&
        (lowerValue.contains('working') ||
            lowerValue.contains('business') ||
            lowerValue.contains('day'))) {
      final start = _toArabicDigits(rangeMatch.group(1)!);
      final end = _toArabicDigits(rangeMatch.group(2)!);
      return '$start إلى $end يوم عمل';
    }

    final localized = value
        .replaceAll(
          RegExp(r'\bworking\s+days?\b', caseSensitive: false),
          'أيام عمل',
        )
        .replaceAll(
          RegExp(r'\bbusiness\s+days?\b', caseSensitive: false),
          'أيام عمل',
        )
        .replaceAll(RegExp(r'\bdays?\b', caseSensitive: false), 'أيام');
    return _toArabicDigits(localized);
  }

  String _toArabicDigits(String value) {
    const digits = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return value.split('').map((char) => digits[char] ?? char).join();
  }

  String _extractTrackingEstimate(List<dynamic> trackingItems) {
    const keys = <String>[
      'eta',
      'estimate',
      'estimated_delivery',
      'estimatedDelivery',
      'estimatedRange',
    ];
    for (final item in trackingItems) {
      final value = _readTrackingValue(item, keys);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String? _readTrackingValue(dynamic input, List<String> keys) {
    if (input is Map) {
      for (final entry in input.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (keys.any(
          (candidate) => candidate.toLowerCase() == key.toLowerCase(),
        )) {
          return value?.toString();
        }
        if (value is Map || value is List) {
          final nested = _readTrackingValue(value, keys);
          if (nested != null && nested.trim().isNotEmpty) {
            return nested;
          }
        }
      }
      return null;
    }
    if (input is List) {
      for (final item in input) {
        final nested = _readTrackingValue(item, keys);
        if (nested != null && nested.trim().isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Montes',
            height: 18 / 12,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montes',
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}
