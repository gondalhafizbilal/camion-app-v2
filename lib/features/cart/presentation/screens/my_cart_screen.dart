import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/api/graphql_error_parser.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/features/cart/presentation/widgets/cart_sliver_app_bar.dart';
import 'package:camion/features/cart/presentation/widgets/custom_product_to_cart.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/cache/secure_cache_storage.dart';
import '../../../../core/services/auth_session_notifier.dart';
import '../../../../core/services/service_locator.dart';

class Variation {
  final String? attribute;
  final String? value;

  const Variation({this.attribute, this.value});

  factory Variation.fromJson(Map<String, dynamic> json) => Variation(
    attribute: json['attribute']?.toString(),
    value: json['value']?.toString(),
  );
}

class ShippingModel {
  final double total;

  const ShippingModel({required this.total});

  static double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory ShippingModel.fromJson(Map<String, dynamic> json) {
    return ShippingModel(total: _parse(json['total']));
  }
}

class GetCartModel {
  String? id;
  String? userId;
  String? guestId;
  String? productId;
  String? productSlug;
  String? variantUuid;
  int? quantity;
  List<Variation>? variation;
  String? title;
  String? image;
  String? variantImageUrl;
  String? price;
  String? currencyCode;
  HomeGraphqlProductCampaign? campaign;
  dynamic couponCode;
  int? discountPercentage;
  DateTime? createdAt;
  DateTime? updatedAt;
  double? totalPrice;
  double? discountPrice;
  double? apiTotal;

  GetCartModel({
    this.id,
    this.userId,
    this.guestId,
    this.productId,
    this.productSlug,
    this.variantUuid,
    this.quantity,
    this.variation,
    this.title,
    this.image,
    this.variantImageUrl,
    this.price,
    this.currencyCode,
    this.campaign,
    this.couponCode,
    this.discountPercentage,
    this.createdAt,
    this.updatedAt,
    this.totalPrice,
    this.discountPrice,
    this.apiTotal,
  });

  factory GetCartModel.fromJson(Map<String, dynamic> json) {
    final rawVariations =
        (json['variation'] as List?) ??
        (json['variations'] as List?) ??
        const [];
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};
    final campaign = product['campaign'] is Map
        ? Map<String, dynamic>.from(product['campaign'] as Map)
        : json['campaign'] is Map
        ? Map<String, dynamic>.from(json['campaign'] as Map)
        : null;
    final variantRaw = json['variation'] ?? json['variant'];
    final variant = variantRaw is Map
        ? Map<String, dynamic>.from(variantRaw)
        : const <String, dynamic>{};
    final variantImages = (variant['images'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((image) => Map<String, dynamic>.from(image))
        .toList();
    final productVariants = (product['variants'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final variantImage = variant['image'];
    String? variantImageUrl;
    String? image;
    if (variantImage is String) {
      final resolvedVariantImage = variantImage.trim();
      if (resolvedVariantImage.isNotEmpty) {
        variantImageUrl = resolvedVariantImage;
        image = resolvedVariantImage;
      }
    } else if (variantImage is Map) {
      final map = Map<String, dynamic>.from(variantImage);
      final resolvedVariantImage =
          map['thumbnailUrl']?.toString().trim() ??
          map['imageUrl']?.toString().trim() ??
          '';
      if (resolvedVariantImage.isNotEmpty) {
        variantImageUrl = resolvedVariantImage;
        image = resolvedVariantImage;
      }
    } else if (variantImage is List && variantImage.isNotEmpty) {
      final first = variantImage.first;
      if (first is String) {
        final resolvedVariantImage = first.trim();
        if (resolvedVariantImage.isNotEmpty) {
          variantImageUrl = resolvedVariantImage;
          image = resolvedVariantImage;
        }
      } else if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        final resolvedVariantImage =
            map['thumbnailUrl']?.toString().trim() ??
            map['imageUrl']?.toString().trim() ??
            '';
        if (resolvedVariantImage.isNotEmpty) {
          variantImageUrl = resolvedVariantImage;
          image = resolvedVariantImage;
        }
      }
    }

    final variantUuid = variant['uuid']?.toString().trim() ?? '';
    var candidateImages = List<Map<String, dynamic>>.from(variantImages);
    if (candidateImages.isEmpty && productVariants.isNotEmpty) {
      final matchedProductVariant = productVariants.firstWhere(
        (entry) =>
            (entry['uuid']?.toString().trim() ?? '').isNotEmpty &&
            (entry['uuid']?.toString().trim() ?? '') == variantUuid,
        orElse: () => const <String, dynamic>{},
      );
      final matchedImages =
          (matchedProductVariant['images'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
      if (matchedImages.isNotEmpty) {
        candidateImages = matchedImages;
      } else {
        for (final productVariant in productVariants) {
          final fallbackImages =
              (productVariant['images'] as List? ?? const <dynamic>[])
                  .whereType<Map>()
                  .map((entry) => Map<String, dynamic>.from(entry))
                  .toList();
          if (fallbackImages.isNotEmpty) {
            candidateImages = fallbackImages;
            break;
          }
        }
      }
    }

    if ((image ?? '').trim().isEmpty) {
      final featuredImages = candidateImages.where((imageMap) {
        final featured = imageMap['isFeatured'];
        if (featured is bool) return featured;
        return featured?.toString().toLowerCase() == 'true';
      }).toList();
      final prioritizedImages = [
        ...featuredImages,
        ...candidateImages.where((entry) => !featuredImages.contains(entry)),
      ];
      for (final entry in prioritizedImages) {
        final thumbnail = entry['thumbnailUrl']?.toString().trim() ?? '';
        if (thumbnail.isNotEmpty) {
          image = thumbnail;
          variantImageUrl ??= thumbnail;
          break;
        }
        final imageUrl = entry['imageUrl']?.toString().trim() ?? '';
        if (imageUrl.isNotEmpty) {
          image = imageUrl;
          variantImageUrl ??= imageUrl;
          break;
        }
      }
    }

    if ((image ?? '').trim().isEmpty) {
      final productFeaturedThumbnail =
          product['featuredThumbnailUrl']?.toString().trim() ?? '';
      final productFeaturedImage =
          product['featuredImageUrl']?.toString().trim() ?? '';
      if (productFeaturedThumbnail.isNotEmpty) {
        image = productFeaturedThumbnail;
      } else if (productFeaturedImage.isNotEmpty) {
        image = productFeaturedImage;
      }
    }

    return GetCartModel(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      guestId: json['guestId'] as String?,
      productId: json['productId']?.toString(),
      productSlug: json['productSlug']?.toString(),
      variantUuid: json['variantUuid']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
      variation: rawVariations
          .map((v) => Variation.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      title: json['title'] as String?,
      image: image,
      price: json['price']?.toString(),
      currencyCode: json['currencyCode']?.toString(),
      campaign: campaign == null
          ? null
          : HomeGraphqlProductCampaign.fromJson(campaign),
      couponCode: json['couponCode'],
      discountPercentage: (json['discountPercentage'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
    );
  }
}

class CartWithShippingResponse {
  final List<GetCartModel> cart;
  final Map<String, dynamic>? address;

  /// keep as-is (Map)
  final Map<String, dynamic>? shipping;

  /// parsed shipping model
  final ShippingModel? shippingModel;

  final bool isShippingValid;

  /// ✅ totals coming from API
  final double? cartTotal;
  final double? shippingTotal;
  final double? grandTotal;

  const CartWithShippingResponse({
    required this.cart,
    required this.address,
    required this.shipping,
    required this.shippingModel,
    required this.isShippingValid,
    required this.cartTotal,
    required this.shippingTotal,
    required this.grandTotal,
  });

  static double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  factory CartWithShippingResponse.fromJson(Map<String, dynamic> json) {
    final cartJson = (json['cart'] as List?) ?? const [];

    final shippingMap = json['shipping'] == null
        ? null
        : Map<String, dynamic>.from(json['shipping'] as Map);

    return CartWithShippingResponse(
      cart: cartJson
          .map(
            (e) => GetCartModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      address: json['address'] == null
          ? null
          : Map<String, dynamic>.from(json['address'] as Map),
      shipping: shippingMap,
      shippingModel: shippingMap == null
          ? null
          : ShippingModel.fromJson(shippingMap),
      isShippingValid: (json['is_shipping_valid'] as bool?) ?? false,

      cartTotal: _parseNullableDouble(json['cart_total']),
      shippingTotal: _parseNullableDouble(json['shipping_total']),
      grandTotal: _parseNullableDouble(json['grand_total']),
    );
  }
}

/// ===============================
/// SCREEN (NO CUBIT)
/// ===============================

class MyCartScreen extends StatefulWidget {
  const MyCartScreen({
    super.key,
    this.lang = AppDefaults.defaultLanguageCode,
    this.couponCode,
  });

  final String lang;
  final String? couponCode;

  @override
  State<MyCartScreen> createState() => _MyCartScreenState();
}

class _MyCartScreenState extends State<MyCartScreen> {
  static const String _ignoredCartGraphqlError =
      'Cannot return null for non-nullable field ProductVariant.images.';

  final Dio _dio = sl<Dio>();
  final HomeRepository _homeRepository = sl<HomeRepository>();
  final Random _random = Random();

  String? token;
  String? userId;
  String? email;

  List<GetCartModel> cartList = [];
  List<HomeGraphqlProduct> popularProducts = [];

  // new endpoint flags
  bool _isShippingValid = false;
  Map<String, dynamic>? _shipping;
  Map<String, dynamic>? _address;

  // ✅ API totals
  double? _apiCartTotal;
  String? _apiCurrencyCode;
  double? _minimumOrderAmountFromApi;
  double? _freeShippingAmountFromApi;

  // UI
  bool _loading = false;
  String? _errorMessage;
  int _cartRenderVersion = 0;
  final Set<String> _quantitySyncingItemKeys = <String>{};
  bool _isLoggedIn = false;
  bool _popularLoading = false;
  bool _popularGridView = true;
  bool _isFetchingCart = false;
  bool _wasMinimumOrderReached = false;
  String? _lastLocaleCode;
  int _cartRequestGeneration = 0;
  Future<void>? _cartLoadInFlight;
  bool _cartRefreshQueued = false;
  final Set<String> _selectedCartItemUuids = <String>{};
  final Set<String> _knownCartItemUuids = <String>{};

  void _handleAuthChanged() {
    if (!mounted) return;
    unawaited(sl<AppsFlyerService>().logConversionEvent('view_cart'));
    _loadUserDataThenFetchCart();
  }

  void _handleExternalRefreshSignal() {
    if (!mounted) return;
    unawaited(_loadUserDataThenFetchCart());
  }

  bool _isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

  bool _isDisplayableVariation(String attribute, String value) {
    final normalized = attribute.trim().toLowerCase();
    if (normalized.isEmpty || value.trim().isEmpty) return false;
    return normalized != 'variantuuid' &&
        normalized != 'variant_uuid' &&
        normalized != 'sku' &&
        normalized != 'barcode';
  }

  int _variationPriority(String attribute) {
    final key = attribute.trim().toLowerCase();
    if (key == 'size' || key == 'applicable model' || key == 'model') return 0;
    if (key == 'color' || key == 'colour') return 1;
    if (key == 'variant') return 99;
    return 50;
  }

  String _selectedCurrencyCode() {
    return resolveCurrencyCode([
      _apiCurrencyCode,
      if (cartList.isNotEmpty) cartList.first.currencyCode,
    ]);
  }

  String _selectedCurrencyCodeForApi() {
    final currency = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (currency != null && currency.trim().isNotEmpty) {
      return currency.trim().toLowerCase();
    }
    return AppDefaults.defaultCurrencyCode.toLowerCase();
  }

  String _discountLabel(BuildContext context) =>
      _isArabic(context) ? 'الخصم' : 'Discount';

  String _readUserDataFailedLabel(BuildContext context) => _isArabic(context)
      ? 'فشل قراءة بيانات المستخدم. يرجى تسجيل الدخول مرة أخرى.'
      : 'Failed to read user data. Please login again.';

  List<GetCartModel> _selectedCartItems() {
    if (_selectedCartItemUuids.isEmpty) return const <GetCartModel>[];
    return cartList
        .where(
          (item) => _selectedCartItemUuids.contains((item.id ?? '').trim()),
        )
        .toList();
  }

  bool get _hasSelectedCartItems => _selectedCartItemUuids.isNotEmpty;

  bool get _areAllCartItemsSelected {
    final selectableIds = cartList
        .map((item) => (item.id ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toList();
    return selectableIds.isNotEmpty &&
        selectableIds.every(_selectedCartItemUuids.contains);
  }

  Set<String> _cartItemUuids(List<GetCartModel> items) {
    return items
        .map((item) => (item.id ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  void _syncDefaultSelectedCartItems(List<GetCartModel> items) {
    final currentIds = _cartItemUuids(items);
    _selectedCartItemUuids
      ..removeWhere((selectedId) => !currentIds.contains(selectedId))
      ..addAll(currentIds.difference(_knownCartItemUuids));
    _knownCartItemUuids
      ..clear()
      ..addAll(currentIds);
  }

  void _setCartItemSelected(GetCartModel item, bool selected) {
    final id = (item.id ?? '').trim();
    if (id.isEmpty) return;
    setState(() {
      if (selected) {
        _selectedCartItemUuids.add(id);
        _knownCartItemUuids.add(id);
      } else {
        _selectedCartItemUuids.remove(id);
      }
      _wasMinimumOrderReached = _isMinimumOrderReached();
    });
  }

  void _toggleSelectAllCartItems(bool selected) {
    setState(() {
      _selectedCartItemUuids.clear();
      if (selected) {
        _selectedCartItemUuids.addAll(
          cartList
              .map((item) => (item.id ?? '').trim())
              .where((id) => id.isNotEmpty),
        );
      }
      _knownCartItemUuids.addAll(
        cartList
            .map((item) => (item.id ?? '').trim())
            .where((id) => id.isNotEmpty),
      );
      _wasMinimumOrderReached = _isMinimumOrderReached();
    });
  }

  void _showSelectCartItemRequiredMessage() {
    final isArabic = _isArabic(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD72631),
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Text(
            isArabic
                ? 'يرجى اختيار منتج واحد على الأقل للمتابعة إلى الدفع.'
                : 'Please select at least one item to checkout.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montes',
            ),
          ),
        ),
      );
  }

  String _requestFailedLabel(BuildContext context, int code) =>
      _isArabic(context) ? 'فشل الطلب ($code).' : 'Request failed ($code).';

  double _parseTikTokValue(dynamic rawValue) {
    final text = rawValue?.toString().trim() ?? '';
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0.0;
  }

  Future<void> _trackTikTokCheckout({
    required double cartTotal,
    required String activeCouponCode,
  }) async {
    try {
      final currency = _selectedCurrencyCode();
      final contents = cartList
          .map((item) {
            final contentId =
                (item.productId ?? item.productSlug ?? item.id ?? '')
                    .toString()
                    .trim();
            if (contentId.isEmpty) return null;
            final quantity = (item.quantity ?? 1).clamp(1, 9999).toInt();
            final parsedUnitPrice = _parseTikTokValue(item.price);
            final fallbackUnitPrice = quantity > 0
                ? (item.totalPrice ?? 0) / quantity
                : (item.totalPrice ?? 0);
            final unitPrice = parsedUnitPrice > 0
                ? parsedUnitPrice
                : fallbackUnitPrice;
            return <String, dynamic>{
              'contentId': contentId,
              'contentName': (item.title ?? '').trim(),
              'price': unitPrice,
              'quantity': quantity,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      await TikTokBusinessService.checkout(
        contentId: contents.isNotEmpty
            ? contents.first['contentId']?.toString()
            : 'cart_checkout',
        description: activeCouponCode.trim().isNotEmpty
            ? 'Checkout with coupon'
            : 'Checkout started',
        contentType: 'product',
        value: cartTotal.toStringAsFixed(2),
        currency: currency,
        contents: contents,
      );
    } catch (error, stackTrace) {
      appLog('[TIKTOK][CHECKOUT] tracking failed: $error');
      appLog(stackTrace.toString());
    }
  }

  Future<void> _trackAppsFlyerInitiatedCheckout({
    required double cartTotal,
  }) async {
    try {
      final contentIds = cartList
          .map(
            (item) => (item.productId ?? item.productSlug ?? item.id ?? '')
                .toString()
                .trim(),
          )
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      final totalQuantity = cartList.fold<int>(
        0,
        (sum, item) => sum + ((item.quantity ?? 1).clamp(1, 9999).toInt()),
      );
      final currency = _selectedCurrencyCode();

      if (contentIds.isEmpty) return;

      unawaited(
        sl<AppsFlyerService>().logInitiatedCheckout(
          contentIds: contentIds,
          contentType: 'product',
          price: cartTotal.toStringAsFixed(2),
          currency: currency,
          quantity: totalQuantity <= 0 ? 1 : totalQuantity,
        ),
      );
    } catch (error, stackTrace) {
      appLog('[APPSFLYER][CHECKOUT] tracking failed: $error');
      appLog(stackTrace.toString());
    }
  }

  Future<void> _trackAppsFlyerCheckoutThresholds({
    required double cartTotal,
    required String activeCouponCode,
  }) async {
    final eventParams = <String, dynamic>{
      'cart_value': cartTotal,
      'currency': _selectedCurrencyCode(),
      if (activeCouponCode.trim().isNotEmpty) 'coupon': activeCouponCode.trim(),
    };

    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        _isMinimumOrderReached()
            ? 'minimum_order_reached'
            : 'minimum_order_not_reached',
        eventParams: eventParams,
      ),
    );

    if (_isQualifiedForFreeShipping()) {
      unawaited(
        sl<AppsFlyerService>().logConversionEvent(
          'free_shipping_reached',
          eventParams: eventParams,
        ),
      );
    }
  }

  // -------------------------
  // Debug helpers
  // -------------------------
  String _pretty(dynamic data) {
    try {
      final safeData = _sanitizeIgnoredCartGraphqlErrors(data);
      if (data == null) return "null";
      if (safeData is String) return safeData;
      return const JsonEncoder.withIndent('  ').convert(safeData);
    } catch (_) {
      return data.toString();
    }
  }

  dynamic _sanitizeIgnoredCartGraphqlErrors(dynamic data) {
    if (data is! Map) return data;
    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    if (errors is! List) {
      return map;
    }
    final filteredErrors = errors.where((entry) {
      if (entry is! Map) return true;
      final entryMap = Map<String, dynamic>.from(entry);
      final message = entryMap['message']?.toString() ?? '';
      return !message.contains(_ignoredCartGraphqlError);
    }).toList();
    if (filteredErrors.isEmpty) {
      map.remove('errors');
    } else {
      map['errors'] = filteredErrors;
    }
    return map;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if ((token ?? '').isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String? _extractApiError(dynamic data) {
    try {
      final sanitizedData = _sanitizeIgnoredCartGraphqlErrors(data);
      final parsed = ApiErrorModel.fromDynamic(sanitizedData).message.trim();
      if (parsed.isEmpty) return null;
      final lower = parsed.toLowerCase();
      if (lower.contains('unauthorized') ||
          lower.contains('unauthenticated') ||
          lower.contains('forbidden') ||
          lower.contains('invalid token') ||
          lower.contains('token expired') ||
          lower.contains('jwt')) {
        return _isArabic(context)
            ? 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.'
            : 'Your session expired. Please login again.';
      }
      return parsed;
    } catch (_) {}
    return null;
  }

  List<GetCartModel> _parseGraphqlCartItems(dynamic data) {
    if (data is! List) return const <GetCartModel>[];

    final items = <GetCartModel>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final product = map['product'] is Map
          ? Map<String, dynamic>.from(map['product'] as Map)
          : const <String, dynamic>{};
      final variant = map['variant'] is Map
          ? Map<String, dynamic>.from(map['variant'] as Map)
          : const <String, dynamic>{};
      final productVariants =
          (product['variants'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
      final variantPrice = variant['price'] is Map
          ? Map<String, dynamic>.from(variant['price'] as Map)
          : const <String, dynamic>{};
      final variantDiscountedPrice = variant['discountedPrice'] is Map
          ? Map<String, dynamic>.from(variant['discountedPrice'] as Map)
          : const <String, dynamic>{};
      final subTotal = map['subTotal'] is Map
          ? Map<String, dynamic>.from(map['subTotal'] as Map)
          : const <String, dynamic>{};
      final discountPrice = map['discountPrice'] is Map
          ? Map<String, dynamic>.from(map['discountPrice'] as Map)
          : const <String, dynamic>{};
      final total = map['total'] is Map
          ? Map<String, dynamic>.from(map['total'] as Map)
          : const <String, dynamic>{};
      final variantImages = (variant['images'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((image) => Map<String, dynamic>.from(image))
          .toList();

      final itemUuid = map['uuid']?.toString().trim() ?? '';
      final productUuid = product['uuid']?.toString().trim() ?? '';
      final productSlug = product['slug']?.toString().trim() ?? '';
      final variantUuid = variant['uuid']?.toString().trim() ?? '';
      final variantTitle = variant['title']?.toString().trim() ?? '';
      final quantity = (map['quantity'] as num?)?.toInt() ?? 1;
      final priceAmount = variantPrice;
      final discountedPriceAmount = variantDiscountedPrice;
      final subTotalAmount = subTotal;
      final discountPriceAmount = discountPrice;
      final totalAmount = total;
      final campaign = product['campaign'] is Map
          ? Map<String, dynamic>.from(product['campaign'] as Map)
          : map['campaign'] is Map
          ? Map<String, dynamic>.from(map['campaign'] as Map)
          : null;

      final effectivePriceAmount = parseMoneyValue(discountedPriceAmount) > 0
          ? parseMoneyValue(discountedPriceAmount)
          : parseMoneyValue(priceAmount);
      final priceText = effectivePriceAmount.toString();
      final subTotalValue = parseMoneyValue(subTotalAmount);
      final discountPriceValue = parseMoneyValue(discountPriceAmount);
      final totalValue = parseMoneyValue(totalAmount);
      String? variantImageUrl;
      String resolvedImage = '';
      final directVariantImage = variant['image'];
      if (directVariantImage is String) {
        final resolved = directVariantImage.trim();
        if (resolved.isNotEmpty) {
          variantImageUrl = resolved;
          resolvedImage = resolved;
        }
      } else if (directVariantImage is Map) {
        final map = Map<String, dynamic>.from(directVariantImage);
        final resolved =
            map['thumbnailUrl']?.toString().trim() ??
            map['imageUrl']?.toString().trim() ??
            '';
        if (resolved.isNotEmpty) {
          variantImageUrl = resolved;
          resolvedImage = resolved;
        }
      } else if (directVariantImage is List && directVariantImage.isNotEmpty) {
        final first = directVariantImage.first;
        if (first is String) {
          final resolved = first.trim();
          if (resolved.isNotEmpty) {
            variantImageUrl = resolved;
            resolvedImage = resolved;
          }
        } else if (first is Map) {
          final map = Map<String, dynamic>.from(first);
          final resolved =
              map['thumbnailUrl']?.toString().trim() ??
              map['imageUrl']?.toString().trim() ??
              '';
          if (resolved.isNotEmpty) {
            variantImageUrl = resolved;
            resolvedImage = resolved;
          }
        }
      }

      var candidateImages = List<Map<String, dynamic>>.from(variantImages);
      if (candidateImages.isEmpty && productVariants.isNotEmpty) {
        final matchedProductVariant = productVariants.firstWhere(
          (entry) =>
              (entry['uuid']?.toString().trim() ?? '').isNotEmpty &&
              (entry['uuid']?.toString().trim() ?? '') == variantUuid,
          orElse: () => const <String, dynamic>{},
        );
        final matchedImages =
            (matchedProductVariant['images'] as List? ?? const <dynamic>[])
                .whereType<Map>()
                .map((entry) => Map<String, dynamic>.from(entry))
                .toList();
        if (matchedImages.isNotEmpty) {
          candidateImages = matchedImages;
        } else {
          for (final productVariant in productVariants) {
            final fallbackImages =
                (productVariant['images'] as List? ?? const <dynamic>[])
                    .whereType<Map>()
                    .map((entry) => Map<String, dynamic>.from(entry))
                    .toList();
            if (fallbackImages.isNotEmpty) {
              candidateImages = fallbackImages;
              break;
            }
          }
        }
      }
      if (resolvedImage.isEmpty) {
        final candidateFeaturedImages = candidateImages.where((image) {
          final featured = image['isFeatured'];
          if (featured is bool) return featured;
          return featured?.toString().toLowerCase() == 'true';
        }).toList();
        final prioritizedImages = [
          ...candidateFeaturedImages,
          ...candidateImages.where(
            (image) => !candidateFeaturedImages.contains(image),
          ),
        ];
        for (final image in prioritizedImages) {
          final thumbnail = (image['thumbnailUrl'] ?? '').toString().trim();
          if (thumbnail.isNotEmpty) {
            resolvedImage = thumbnail;
            variantImageUrl ??= thumbnail;
            break;
          }
          final imageUrl = (image['imageUrl'] ?? '').toString().trim();
          if (imageUrl.isNotEmpty) {
            resolvedImage = imageUrl;
            variantImageUrl ??= imageUrl;
            break;
          }
        }
      }
      if (resolvedImage.isEmpty) {
        final productFeaturedThumbnail = (product['featuredThumbnailUrl'] ?? '')
            .toString()
            .trim();
        final productFeaturedImage = (product['featuredImageUrl'] ?? '')
            .toString()
            .trim();
        resolvedImage = productFeaturedThumbnail.isNotEmpty
            ? productFeaturedThumbnail
            : productFeaturedImage;
      }

      final variations = <Variation>[];
      final seenVariations = <String>{};
      void addVariation(String attribute, String value) {
        final label = attribute.trim();
        final normalizedValue = value.trim();
        if (!_isDisplayableVariation(label, normalizedValue)) return;
        final dedupe =
            '${label.toLowerCase()}|${normalizedValue.toLowerCase()}';
        if (!seenVariations.add(dedupe)) return;
        variations.add(Variation(attribute: label, value: normalizedValue));
      }

      final optionValues =
          (variant['optionValues'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
      for (final optionValueEntry in optionValues) {
        final optionValueRaw = optionValueEntry['optionValue'];
        if (optionValueRaw is! Map) continue;
        final optionValue = Map<String, dynamic>.from(optionValueRaw);
        final optionRaw = optionValue['option'];
        if (optionRaw is! Map) continue;
        final option = Map<String, dynamic>.from(optionRaw);
        addVariation(
          option['name']?.toString() ?? '',
          optionValue['value']?.toString() ?? '',
        );
      }
      if (variantTitle.isNotEmpty) {
        addVariation('Variant', variantTitle);
      }
      if (variantUuid.isNotEmpty) {
        variations.add(Variation(attribute: 'variantUuid', value: variantUuid));
      }

      items.add(
        GetCartModel(
          id: itemUuid,
          productId: productUuid,
          productSlug: productSlug,
          variantUuid: variantUuid,
          quantity: quantity,
          variation: variations,
          title: product['title']?.toString() ?? '',
          image: resolvedImage,
          variantImageUrl: variantImageUrl,
          price: priceText,
          currencyCode:
              total['currencyCode']?.toString() ??
              total['curreny']?.toString() ??
              discountPrice['currencyCode']?.toString() ??
              discountPrice['curreny']?.toString() ??
              variantDiscountedPrice['currencyCode']?.toString() ??
              variantPrice['currencyCode']?.toString() ??
              subTotal['currencyCode']?.toString() ??
              subTotal['curreny']?.toString(),
          campaign: campaign == null
              ? null
              : HomeGraphqlProductCampaign.fromJson(campaign),
          totalPrice: subTotalValue,
          discountPrice: discountPriceValue,
          apiTotal: totalValue,
        ),
      );
    }

    return items;
  }

  List<Map<String, String>> _normalizedVariations(GetCartModel item) {
    final raw = item.variation ?? const <Variation>[];
    final normalized = raw
        .map(
          (v) => <String, String>{
            "attribute": (v.attribute ?? '').trim(),
            "value": (v.value ?? '').trim(),
          },
        )
        .where(
          (v) =>
              (v["attribute"] ?? '').isNotEmpty ||
              (v["value"] ?? '').isNotEmpty,
        )
        .toList();
    normalized.sort((a, b) {
      final aKey = "${a["attribute"]}|${a["value"]}";
      final bKey = "${b["attribute"]}|${b["value"]}";
      return aKey.compareTo(bKey);
    });
    return normalized;
  }

  String _variantUuidFromItem(GetCartModel item) {
    for (final entry in _normalizedVariations(item)) {
      final attribute = (entry['attribute'] ?? '').trim().toLowerCase();
      final value = (entry['value'] ?? '').trim();
      if ((attribute == 'variantuuid' || attribute == 'variant_uuid') &&
          value.isNotEmpty) {
        return value;
      }
    }
    return (item.variantUuid ?? '').trim();
  }

  String _variationDisplayText(GetCartModel item) {
    final normalized = _normalizedVariations(item)
        .where(
          (entry) => _isDisplayableVariation(
            (entry['attribute'] ?? '').trim(),
            (entry['value'] ?? '').trim(),
          ),
        )
        .toList();
    if (normalized.isEmpty) {
      return '';
    }
    normalized.sort((a, b) {
      final aLabel = (a['attribute'] ?? '').trim();
      final bLabel = (b['attribute'] ?? '').trim();
      final pA = _variationPriority(aLabel);
      final pB = _variationPriority(bLabel);
      if (pA != pB) return pA.compareTo(pB);
      return aLabel.compareTo(bLabel);
    });

    return normalized
        .map((v) {
          final attribute = (v["attribute"] ?? '').trim();
          final value = (v["value"] ?? '').trim();
          if (attribute.isEmpty) {
            return value;
          }
          if (value.isEmpty) {
            return attribute;
          }
          return '$attribute: $value';
        })
        .where((part) => part.isNotEmpty)
        .join('\n');
  }

  String _cartItemKey(GetCartModel item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return "id:$id";

    final productId = (item.productId ?? '').trim();
    final signature = _normalizedVariations(
      item,
    ).map((v) => "${v["attribute"]}=${v["value"]}").join("&");
    return "product:$productId|variation:$signature";
  }

  // -------------------------
  // Lifecycle
  // -------------------------
  @override
  void initState() {
    super.initState();
    sl<AuthSessionNotifier>().addListener(_handleAuthChanged);
    CartRefreshNotifier.signal.addListener(_handleExternalRefreshSignal);

    if (AppConfig.instance.enableNetworkLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: false,
          error: true,
          logPrint: (o) => appLog(o.toString()),
        ),
      );
    }

    _loadUserDataThenFetchCart();
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
      _loading = true;
      _errorMessage = null;
      _popularLoading = true;
      _cartRequestGeneration++;
    });
    unawaited(_loadUserDataThenFetchCart());
  }

  @override
  void dispose() {
    sl<AuthSessionNotifier>().removeListener(_handleAuthChanged);
    CartRefreshNotifier.signal.removeListener(_handleExternalRefreshSignal);
    super.dispose();
  }

  Future<void> _loadPopularProducts() async {
    if (!mounted || _popularLoading) return;
    setState(() => _popularLoading = true);

    final appLanguage = Localizations.localeOf(context).languageCode.trim();
    final language = ApiLocaleMapper.toGraphqlLocale(appLanguage);
    final cachedToken = await sl<SecureCacheHelper>().getData(key: 'token');
    final result = await _homeRepository.getPopularGraphqlProducts(
      token: cachedToken,
      language: language,
      pageNumber: 1,
      itemsPerPage: 4,
    );

    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        popularProducts = const <HomeGraphqlProduct>[];
        _popularLoading = false;
      }),
      (products) => setState(() {
        final shuffled = List<HomeGraphqlProduct>.from(products)
          ..shuffle(_random);
        popularProducts = shuffled.take(4).toList();
        _popularLoading = false;
      }),
    );
  }

  Future<void> _loadUserDataThenFetchCart() async {
    if (_cartLoadInFlight != null) {
      _cartRefreshQueued = true;
      return _cartLoadInFlight;
    }

    final completer = Completer<void>();
    _cartLoadInFlight = completer.future;

    try {
      do {
        _cartRefreshQueued = false;
        await _loadUserDataThenFetchCartOnce();
      } while (_cartRefreshQueued && mounted);
    } finally {
      _cartLoadInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> _loadUserDataThenFetchCartOnce() async {
    final requestGeneration = ++_cartRequestGeneration;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final cache = sl<SecureCacheHelper>();

      final t = await cache.getData(key: 'token');
      final id = await cache.getData(key: 'id');
      final em = await cache.getData(key: 'email');
      final pendingAuthSession =
          (await cache.getData(key: 'authSessionToken'))?.trim() ?? '';
      final guestId = (await cache.getData(key: 'guestId'))?.trim() ?? '';

      if (AppConfig.instance.enableNetworkLogs) {
        appLog("🧩 cache token=$t");
        appLog("🧩 cache id=$id");
        appLog("🧩 cache email=$em");
        appLog("🧩 cache authSessionToken=$pendingAuthSession");
        appLog("🧩 cache guestId=$guestId");
      }

      token = t?.toString();
      userId = id?.toString();
      email = em?.toString();
      final loginMethod =
          (await cache.getData(key: 'authLoginMethod'))?.trim().toLowerCase() ??
          '';
      _isLoggedIn = (token ?? '').isNotEmpty && loginMethod != 'guest';

      unawaited(_loadPopularProducts());
      if (pendingAuthSession.isNotEmpty) {
        if (!mounted) return;
        if (requestGeneration != _cartRequestGeneration) return;
        setState(() {
          _loading = false;
        });
        return;
      }
      final resolvedToken = (token ?? '').trim();
      if (resolvedToken.isEmpty && guestId.isEmpty) {
        if (!mounted) return;
        if (requestGeneration != _cartRequestGeneration) return;
        setState(() {
          _loading = false;
        });
        return;
      }
      await _fetchCartWithShipping(refreshGeneration: requestGeneration);
    } catch (e, st) {
      appLog("❌ loadUserData error: $e\n$st");
      if (!mounted) return;
      if (requestGeneration != _cartRequestGeneration) return;
      setState(() {
        _errorMessage = _readUserDataFailedLabel(context);
        _loading = false;
      });
    }
  }

  // -------------------------
  // Fetch cart items (guest + authenticated)
  // -------------------------
  Future<void> _fetchCartWithShipping({
    bool showLoading = true,
    int? refreshGeneration,
  }) async {
    if (!mounted) return;
    if (_isFetchingCart) return;
    final requestGeneration = refreshGeneration ?? _cartRequestGeneration;
    final cache = sl<SecureCacheHelper>();
    final cachedToken = (await cache.getData(key: 'token'))?.trim() ?? '';
    final cachedGuestId = (await cache.getData(key: 'guestId'))?.trim() ?? '';
    final pendingAuthSession =
        (await cache.getData(key: 'authSessionToken'))?.trim() ?? '';
    if (pendingAuthSession.isNotEmpty) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    if (cachedToken.isEmpty && cachedGuestId.isEmpty) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    // Keep token aligned with cache before building request headers.
    token = cachedToken;
    _isFetchingCart = true;

    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final url = EndPoints.graphql;
    const query = r'''
      query GetCustomerCart($language: String, $currency: String) {
          getCustomerCart(language: $language, currency: $currency) {
              uuid
              product {
                  uuid
                  slug
                  title(language: $language)
                  featuredThumbnailUrl
                  featuredImageUrl
                  brief(language: $language)
                  description(language: $language)
                  descriptionHtml(language: $language)
                  status
                  salesCount
                  likesCount
                  reviewsCount
                  ratingAvg
                  ratingOneStarCount
                  ratingTwoStarCount
                  ratingThreeStarCount
                  ratingFourStarCount
                  ratingFiveStarCount
                  campaign {
                      uuid
                      name(language: $language)
                      brief(language: $language)
                      slug
                      discountPercentage
                      startsAt
                      finishesAt
                  }
              }
              variant {
                  uuid
                  title(language: $language)
                  sku
                  barcode
                  price(currency: $currency) {
                      amount
                      currencyCode
                  }
                  discountedPrice(currency: $currency) {
                      amount
                      currencyCode
                  }
                  weight {
                      amount
                      unit
                  }
                  dimensions {
                      width
                      height
                      length
                      unit
                  }
                  images {
                      uuid
                      imageUrl
                      thumbnailUrl
                      alt
                      isFeatured
                      position
                  }
                  optionValues{
                      optionValue{
                          uuid
                          value(language: $language)
                          position
                          option {
                              uuid
                              name(language: $language)
                              position
                          }
                      }
                  }
              }
              availableStock
              subTotal {
                  amount
                  currencyCode
              }
              discountPrice {
                  amount
                  currencyCode
              }
              total {
                  amount
                  currencyCode
              }
              quantity
          }
          getMinimumOrderValue(currency: $currency) {
              uuid
              name
              type
              integerValue
              decimalValue
              stringValue
              booleanValue
              sensitive
          }
          getFreeShippingValue(currency: $currency) {
              uuid
              name
              type
              integerValue
              decimalValue
              stringValue
              booleanValue
              sensitive
          }
      }
    ''';
    if (!mounted) return;
    final language = ApiLocaleMapper.toGraphqlLocale(
      Localizations.localeOf(context).languageCode,
    );
    final payload = <String, dynamic>{
      'query': query,
      'variables': {
        'language': language,
        'currency': _selectedCurrencyCodeForApi(),
      },
    };
    final requestHeaders = <String, String>{
      ..._headers,
      'x-allow-graphql-partial-data': 'true',
    };
    appLog("➡️ [cart-graphql/get] URL: $url");
    appLog("➡️ [cart-graphql/get] Headers: ${_pretty(requestHeaders)}");
    appLog("➡️ [cart-graphql/get] Payload: ${_pretty(payload)}");

    try {
      final res = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: requestHeaders,
          responseType: ResponseType.json,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 500,
        ),
      );

      appLog("⬅️ [cart-graphql/get] Status: ${res.statusCode}");
      appLog("⬅️ [cart-graphql/get] Response: ${_pretty(res.data)}");

      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        if (!mounted) return;
        if (requestGeneration != _cartRequestGeneration) return;
        setState(() {
          _errorMessage =
              _extractApiError(res.data) ?? _requestFailedLabel(context, code);
        });
        return;
      }

      GraphqlErrorParser.throwIfAny(res);

      final dataMap = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : const <String, dynamic>{};
      final graphqlData = dataMap['data'] is Map
          ? Map<String, dynamic>.from(dataMap['data'] as Map)
          : const <String, dynamic>{};
      final minimumOrderAmount = _parseMinimumOrderAmount(
        graphqlData['getMinimumOrderValue'],
      );
      final freeShippingAmount = _parseKeyValueAmount(
        graphqlData['getFreeShippingValue'],
      );
      final parsedItems = _parseGraphqlCartItems(
        graphqlData['getCustomerCart'],
      );
      final apiCartTotal = _sumNullableMoney(
        parsedItems,
        (item) => item.totalPrice,
      );
      final fallbackCartTotal = _computedCartTotalFromCurrentItems(parsedItems);

      if (!mounted) return;
      if (requestGeneration != _cartRequestGeneration) return;
      setState(() {
        cartList = parsedItems;
        _syncDefaultSelectedCartItems(parsedItems);
        _isShippingValid = false;
        _shipping = null;
        _address = null;

        _apiCartTotal = apiCartTotal ?? fallbackCartTotal;
        _apiCurrencyCode = parsedItems.isNotEmpty
            ? parsedItems.first.currencyCode
            : null;
        _minimumOrderAmountFromApi = minimumOrderAmount;
        _freeShippingAmountFromApi = freeShippingAmount;
        _cartRenderVersion++;
      });
      _maybeShowMinimumOrderReachedBlooper();
    } catch (e, st) {
      appLog("❌ [cart-graphql/get] Exception: $e");
      appLog("❌ [cart-graphql/get] Stack: $st");
      String fallbackError = 'Failed to load cart.';
      if (e is DioException) {
        if (BackendUnavailableDetector.isBackendUnavailableDioException(e)) {
          BackendUnavailableNotifier.show();
        }
        fallbackError =
            _extractApiError(e.response?.data) ??
            (e.message?.trim().isNotEmpty == true
                ? e.message!.trim()
                : fallbackError);
      }
      if (!mounted) return;
      if (requestGeneration != _cartRequestGeneration) return;
      setState(() {
        cartList = const <GetCartModel>[];
        _selectedCartItemUuids.clear();
        _knownCartItemUuids.clear();
        _errorMessage = fallbackError;
        _isShippingValid = false;
        _shipping = null;
        _address = null;
        _apiCartTotal = 0;
        _apiCurrencyCode = null;
        _minimumOrderAmountFromApi = null;
        _freeShippingAmountFromApi = null;
        _cartRenderVersion++;
      });
      _wasMinimumOrderReached = false;
    } finally {
      _isFetchingCart = false;
      if (showLoading &&
          mounted &&
          requestGeneration == _cartRequestGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  int? _quantityForCartItemUuid(String cartItemUuid) {
    if (cartItemUuid.trim().isEmpty) return null;
    for (final item in cartList) {
      final itemId = (item.id ?? '').trim();
      if (itemId == cartItemUuid) {
        return item.quantity;
      }
    }
    return null;
  }

  void _applyLocalQuantityForCartItem({
    required String cartItemUuid,
    required int quantity,
  }) {
    final normalizedId = cartItemUuid.trim();
    if (normalizedId.isEmpty || quantity < 1) return;
    final index = cartList.indexWhere(
      (item) => (item.id ?? '').trim() == normalizedId,
    );
    if (index == -1) return;
    setState(() {
      cartList[index].quantity = quantity;
      final computedCartTotal = _computedCartTotalFromCurrentItems(cartList);
      _apiCartTotal = computedCartTotal;
      _apiCurrencyCode = cartList[index].currencyCode ?? _apiCurrencyCode;
    });
  }

  Future<void> _refreshCartAfterSuccessfulPatch({
    required String cartItemUuid,
    required int expectedQuantity,
  }) async {
    await _fetchCartWithShipping(showLoading: false);
    final serverQty = _quantityForCartItemUuid(cartItemUuid);
    if (serverQty == expectedQuantity) {
      return;
    }

    appLog(
      "⚠️ [cart-items/update] backend lag detected cartItemUuid=$cartItemUuid expectedQty=$expectedQuantity observedQty=${serverQty?.toString() ?? 'N/A'}",
    );
    _applyLocalQuantityForCartItem(
      cartItemUuid: cartItemUuid,
      quantity: expectedQuantity,
    );
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        await _fetchCartWithShipping(showLoading: false);
      }),
    );
  }

  Future<void> _refreshCartScreen() async {
    await _loadUserDataThenFetchCart();
  }

  String _money(double v) => v.toStringAsFixed(2);

  double _effectiveMinimumOrderAmount() {
    final apiMinimum = _minimumOrderAmountFromApi;
    return apiMinimum != null && apiMinimum > 0 ? apiMinimum : 0;
  }

  double? _effectiveFreeShippingThreshold() {
    final apiFreeShipping = _freeShippingAmountFromApi;
    if (apiFreeShipping != null && apiFreeShipping > 0) {
      return apiFreeShipping;
    }
    final shipping = _shipping;
    if (shipping != null) {
      const keys = <String>[
        'freeShippingThreshold',
        'free_shipping_threshold',
        'minimumOrderForFreeShipping',
        'minimum_order_for_free_shipping',
        'minFreeShippingAmount',
        'min_free_shipping_amount',
      ];
      for (final key in keys) {
        final raw = shipping[key];
        if (raw == null) continue;
        final amount = raw is num
            ? raw.toDouble()
            : double.tryParse(raw.toString().trim());
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return null;
  }

  double? _parseKeyValueAmount(dynamic rawConfig) {
    if (rawConfig is! Map) return null;
    final map = Map<String, dynamic>.from(rawConfig);

    final integerValue = map['integerValue'];
    final decimalValue = map['decimalValue'];
    final asInteger = integerValue is num
        ? integerValue.toDouble()
        : double.tryParse((integerValue ?? '').toString());
    final asDecimal = decimalValue is num
        ? decimalValue.toDouble()
        : double.tryParse((decimalValue ?? '').toString());
    final asString = double.tryParse((map['stringValue'] ?? '').toString());

    if (asDecimal != null && asDecimal > 0) return asDecimal;
    if (asInteger != null && asInteger > 0) return asInteger;
    if (asString != null && asString > 0) return asString;
    return null;
  }

  double? _parseMinimumOrderAmount(dynamic rawConfig) {
    return _parseKeyValueAmount(rawConfig);
  }

  double _cartSubtotalForFreeShipping() {
    final selectedItems = _selectedCartItems();
    if (selectedItems.isNotEmpty) {
      return _computedCartTotalFromCurrentItems(selectedItems);
    }
    return 0;
  }

  double _remainingForMinimumOrder() {
    final remaining =
        _effectiveMinimumOrderAmount() - _cartSubtotalForFreeShipping();
    return remaining <= 0 ? 0 : remaining;
  }

  bool _isMinimumOrderReached() {
    return _remainingForMinimumOrder() <= 0;
  }

  bool _isQualifiedForFreeShipping() {
    final threshold = _effectiveFreeShippingThreshold();
    if (threshold == null) return false;
    return _cartSubtotalForFreeShipping() >= threshold;
  }

  double _remainingForFreeShipping() {
    final threshold = _effectiveFreeShippingThreshold();
    if (threshold == null) return 0;
    final remaining = threshold - _cartSubtotalForFreeShipping();
    return remaining <= 0 ? 0 : remaining;
  }

  void _maybeShowMinimumOrderReachedBlooper() {
    final isReached = _isMinimumOrderReached();
    if (!_wasMinimumOrderReached &&
        isReached &&
        mounted &&
        _isCartRouteVisible()) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0E9F6E),
            margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            content: Text(
              _isArabic(context)
                  ? 'تم الوصول إلى الحد الأدنى للطلب. يمكنك المتابعة للدفع'
                  : 'Minimum order reached. You can now checkout.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montes',
              ),
            ),
          ),
        );
    }
    _wasMinimumOrderReached = isReached;
  }

  bool _isCartRouteVisible() {
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) {
      return false;
    }

    try {
      final location = GoRouterState.of(context).uri.toString().toLowerCase();
      if (location.startsWith(AppRouter.myCart.toLowerCase())) {
        return true;
      }
      if (location.startsWith(
            AppRouter.selectingFromBottomNavBar.toLowerCase(),
          ) &&
          location.contains('tab=3')) {
        return true;
      }
    } catch (_) {
      // Fallback to route visibility only.
      return true;
    }

    return false;
  }

  // -------------------------
  // Quantity update (UI only)
  // -------------------------
  double? _sumNullableMoney(
    List<GetCartModel> items,
    double? Function(GetCartModel item) selector,
  ) {
    var hasAny = false;
    var total = 0.0;
    for (final item in items) {
      final amount = selector(item);
      if (amount == null) continue;
      hasAny = true;
      total += amount;
    }
    return hasAny ? total : null;
  }

  double _computedCartTotalFromCurrentItems(List<GetCartModel> items) {
    return items.fold<double>(0, (sum, item) {
      final itemTotal = item.totalPrice;
      if (itemTotal != null) {
        return sum + itemTotal;
      }
      final price = double.tryParse((item.price ?? '0').toString()) ?? 0;
      final qty = item.quantity ?? 1;
      return sum + (price * qty);
    });
  }

  void _onQuantityChanged(GetCartModel targetItem, int newQuantity) {
    final targetKey = _cartItemKey(targetItem);
    final index = cartList.indexWhere((e) => _cartItemKey(e) == targetKey);
    if (index == -1) return;

    setState(() {
      cartList[index].quantity = newQuantity;
      final computedCartTotal = _computedCartTotalFromCurrentItems(cartList);
      _apiCartTotal = computedCartTotal;
      _apiCurrencyCode = cartList[index].currencyCode ?? _apiCurrencyCode;
    });
    _maybeShowMinimumOrderReachedBlooper();
  }

  Future<bool> _updateQuantityOnServer(
    GetCartModel targetItem,
    int newQuantity,
  ) async {
    final itemKey = _cartItemKey(targetItem);
    if (itemKey.isEmpty) return false;
    if (_quantitySyncingItemKeys.contains(itemKey)) return false;
    if (mounted) {
      setState(() {
        _quantitySyncingItemKeys.add(itemKey);
      });
    }
    try {
      final cartItemUuid = (targetItem.id ?? '').trim();
      final productUuid = (targetItem.productId ?? '').trim();
      final variantUuid = _variantUuidFromItem(targetItem);
      if (cartItemUuid.isEmpty || productUuid.isEmpty || variantUuid.isEmpty) {
        appLog(
          "❌ [cart-items/update] missing payload cartItemUuid=$cartItemUuid productUuid=$productUuid variantUuid=$variantUuid",
        );
        return false;
      }

      final res = await _dio.patch(
        "${EndPoints.baseUrl}/v1/cart-items/$cartItemUuid",
        options: Options(
          headers: _headers,
          responseType: ResponseType.json,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 500,
        ),
        data: {
          "currency": _selectedCurrencyCodeForApi(),
          "productUuid": productUuid,
          "variantUuid": variantUuid,
          "quantity": newQuantity,
        },
      );

      final code = res.statusCode ?? 0;
      final success = code >= 200 && code < 300;
      if (success) {
        final responseQuantity = _extractUpdatedQuantityFromResponse(res.data);
        appLog(
          "✅ [cart-items/update] requestQty=$newQuantity responseQty=${responseQuantity?.toString() ?? 'N/A'} cartItemUuid=$cartItemUuid variantUuid=$variantUuid",
        );
        if (responseQuantity != null &&
            responseQuantity > 0 &&
            responseQuantity != newQuantity) {
          appLog(
            "⚠️ [cart-items/update] quantity mismatch requestQty=$newQuantity responseQty=$responseQuantity cartItemUuid=$cartItemUuid",
          );
          final index = cartList.indexWhere((e) => _cartItemKey(e) == itemKey);
          if (index != -1) {
            setState(() {
              cartList[index].quantity = responseQuantity;
              final computedCartTotal = _computedCartTotalFromCurrentItems(
                cartList,
              );
              _apiCartTotal = computedCartTotal;
              _apiCurrencyCode =
                  cartList[index].currencyCode ?? _apiCurrencyCode;
            });
          }
        }
        await _refreshCartAfterSuccessfulPatch(
          cartItemUuid: cartItemUuid,
          expectedQuantity: newQuantity,
        );
        return true;
      }

      appLog(
        "❌ [cart-items/update] failed status=$code body=${_pretty(res.data)}",
      );
      return false;
    } catch (e, st) {
      appLog("❌ [cart-items/update] exception: $e");
      appLog("❌ [cart-items/update] stack: $st");
      if (e is DioException &&
          BackendUnavailableDetector.isBackendUnavailableDioException(e)) {
        BackendUnavailableNotifier.show();
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _quantitySyncingItemKeys.remove(itemKey);
        });
      }
    }
  }

  int? _extractUpdatedQuantityFromResponse(dynamic data) {
    if (data is! Map) return null;
    final root = Map<String, dynamic>.from(data);

    int? readQty(dynamic value) {
      if (value is num) return value.toInt();
      final parsed = int.tryParse((value ?? '').toString().trim());
      return parsed;
    }

    final directQty = readQty(root['quantity']);
    if (directQty != null) return directQty;

    final dataMap = root['data'];
    if (dataMap is Map) {
      final normalizedData = Map<String, dynamic>.from(dataMap);
      final nestedDirect = readQty(normalizedData['quantity']);
      if (nestedDirect != null) return nestedDirect;

      final cartItem = normalizedData['cartItem'];
      if (cartItem is Map) {
        final nested = readQty(cartItem['quantity']);
        if (nested != null) return nested;
      }

      final updatedCartItem = normalizedData['updatedCartItem'];
      if (updatedCartItem is Map) {
        final nested = readQty(updatedCartItem['quantity']);
        if (nested != null) return nested;
      }
    }

    final item = root['item'];
    if (item is Map) {
      return readQty(item['quantity']);
    }

    return null;
  }

  // -------------------------
  // Delete (optimistic + rollback)
  // -------------------------
  Future<void> _deleteCartItem(GetCartModel targetItem) async {
    final itemKey = _cartItemKey(targetItem);
    if (itemKey.isEmpty) return;

    final index = cartList.indexWhere((e) => _cartItemKey(e) == itemKey);
    if (index == -1) return;

    final removedItem = cartList[index];
    final backup = List<GetCartModel>.from(cartList);
    final selectedBackup = Set<String>.from(_selectedCartItemUuids);
    final knownBackup = Set<String>.from(_knownCartItemUuids);
    final cartItemUuid = (removedItem.id ?? '').trim();
    if (cartItemUuid.isEmpty) return;

    setState(() {
      cartList.removeAt(index);
      _selectedCartItemUuids.remove(cartItemUuid);
      _knownCartItemUuids.remove(cartItemUuid);
    });

    try {
      await _dio.delete(
        "${EndPoints.baseUrl}/v1/cart-items/$cartItemUuid",
        options: Options(headers: _headers),
      );

      unawaited(
        sl<AppsFlyerService>().logRemoveFromCart(
          contentId:
              (removedItem.productId ?? removedItem.productSlug ?? cartItemUuid)
                  .toString(),
          contentType: 'product',
        ),
      );
      HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
    } catch (e, st) {
      appLog("❌ delete error: $e\n$st");
      if (e is DioException &&
          BackendUnavailableDetector.isBackendUnavailableDioException(e)) {
        BackendUnavailableNotifier.show();
      }
      if (!mounted) return;
      setState(() {
        cartList = backup; // rollback
        _selectedCartItemUuids
          ..clear()
          ..addAll(selectedBackup);
        _knownCartItemUuids
          ..clear()
          ..addAll(knownBackup);
      });
    }
  }

  Future<void> _confirmDeleteCartItem(GetCartModel targetItem) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isArabic =
            Localizations.localeOf(dialogContext).languageCode == 'ar';
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(isArabic ? 'حذف العنصر' : 'Delete item'),
          content: Text(
            isArabic
                ? 'هل أنت متأكد أنك تريد حذف هذا العنصر؟'
                : 'Are you sure you want to delete this item?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(S.of(dialogContext).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isArabic ? 'نعم، احذف' : 'Yes, delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;
    await _deleteCartItem(targetItem);
    if (!mounted) return;
    await _fetchCartWithShipping();
  }

  // -------------------------
  // Navigation / UI helpers
  // -------------------------
  Map<String, dynamic> _cartNavigationResult() {
    return {
      "cartEmpty": cartList.isEmpty,
      "cartProductIds": cartList
          .map((item) => (item.productId ?? '').trim())
          .where((id) => id.isNotEmpty)
          .toList(),
    };
  }

  void _popWithCartState() {
    final rememberedBackTarget = AppNavigator.consumeCartBackTarget();
    if (rememberedBackTarget != null &&
        rememberedBackTarget.location.trim().isNotEmpty) {
      GoRouter.of(
        context,
      ).go(rememberedBackTarget.location, extra: rememberedBackTarget.extra);
      return;
    }

    if (cartList.isEmpty) {
      GoRouter.of(context).go(AppRouter.selectingFromBottomNavBar);
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_cartNavigationResult());
      return;
    }
    GoRouter.of(context).go(AppRouter.selectingFromBottomNavBar);
  }

  void _goToHomeFromCart() {
    GoRouter.of(context).push(
      AppRouter.homeSectionDetails,
      extra: {'title': S.of(context).all, 'section': 'all'},
    );
  }

  List<HomeGraphqlProduct> _resolvedPopularProducts() {
    return popularProducts;
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popWithCartState();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: _refreshCartScreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 50.h)),
              CartSliverAppBar(
                title: S.of(context).cart,
                onBackPressed: _popWithCartState,
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              ..._buildCartBodySlivers(),
              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCartBodySlivers() {
    if (_loading && cartList.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: _CartShimmerList(),
          ),
        ),
      ];
    }

    if (_errorMessage != null && cartList.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50.sp),
                  SizedBox(height: 12.h),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.red),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: _fetchCartWithShipping,
                    child: Text(
                      S.of(context).retry,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (cartList.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _CartEmptyStateCard(onContinueShopping: _goToHomeFromCart),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
        ..._buildPopularProductsSection(),
      ];
    }

    final allSelected = _areAllCartItemsSelected;
    final selectedCount = _selectedCartItemUuids.length;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
          child: Row(
            children: [
              SizedBox(
                width: 24.w,
                height: 24.w,
                child: Checkbox(
                  value: allSelected,
                  activeColor: const Color(0xFFD72631),
                  side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  onChanged: (value) =>
                      _toggleSelectAllCartItems(value ?? false),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  _isArabic(context) ? 'تحديد الكل' : 'Select all',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montes',
                  ),
                ),
              ),
              Text(
                _isArabic(context)
                    ? '$selectedCount محدد'
                    : '$selectedCount selected',
                style: TextStyle(
                  color: const Color(0xFF707070),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Montes',
                ),
              ),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = cartList[index];
          final cartItemUuid = (item.id ?? '').trim();
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => GoRouter.of(context).push(
                AppRouter.productDetails,
                extra: {
                  'id': item.productId,
                  'slug': item.productSlug,
                  'selectedVariantUuid': _variantUuidFromItem(item),
                },
              ),
              child: Stack(
                children: [
                  ProductCartItem(
                    key: ValueKey(
                      "cart-item-${_cartItemKey(item)}-${item.quantity ?? 1}-$_cartRenderVersion",
                    ),
                    productId: item.productId ?? '',
                    cartItemUuid: item.id,
                    isSelected: _selectedCartItemUuids.contains(cartItemUuid),
                    onSelectionChanged: cartItemUuid.isEmpty
                        ? null
                        : (selected) => _setCartItemSelected(item, selected),
                    variantUuid: _variantUuidFromItem(item),
                    imageUrl: (item.variantImageUrl ?? '').trim().isNotEmpty
                        ? item.variantImageUrl!.trim()
                        : (item.image ?? ''),
                    title: item.title ?? '',
                    price: item.price ?? '',
                    currencyCode: item.currencyCode,
                    campaignLabel: item.campaign?.name.trim().isNotEmpty == true
                        ? item.campaign!.name
                        : (item.campaign?.finishesAt != null
                              ? (item.title ?? '')
                              : ''),
                    campaignEndsAt: item.campaign?.finishesAt,
                    variationText: _variationDisplayText(item),
                    initialQuantity: item.quantity ?? 1,
                    onDelete: () => _confirmDeleteCartItem(item),
                    onQuantityChanged: (newQ) => _onQuantityChanged(item, newQ),
                    onUpdateQuantity: (newQ) =>
                        _updateQuantityOnServer(item, newQ),
                  ),
                  if (_loading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.35,
                          child: _Shimmer(
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }, childCount: cartList.length),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
          child: _buildCheckoutSection(context),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ..._buildPopularProductsSection(),
    ];
  }

  List<Widget> _buildPopularProductsSection() {
    final displayProducts = _resolvedPopularProducts();

    if (_popularLoading && displayProducts.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _PopularProductsShimmerRow(),
          ),
        ),
      ];
    }

    if (displayProducts.isEmpty) {
      return [
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
                AppTapFeedback(
                  onTap: () => context.push(
                    AppRouter.homeSectionDetails,
                    extra: {
                      'title': S.of(context).popular_products,
                      'section': 'popular',
                    },
                  ),
                  borderRadius: BorderRadius.circular(6.r),
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
                AppTapFeedback(
                  onTap: () => setState(() => _popularGridView = false),
                  borderRadius: BorderRadius.circular(5.r),
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
                AppTapFeedback(
                  onTap: () => setState(() => _popularGridView = true),
                  borderRadius: BorderRadius.circular(5.r),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _CartStateMessageCard(
              icon: Icon(
                Icons.inventory_2_outlined,
                color: const Color(0xFFD72631),
                size: 42.sp,
              ),
              title: 'Popular products will appear here soon.',
              subtitle: 'This area will stay dynamic as product data loads.',
            ),
          ),
        ),
      ];
    }

    return [
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
              AppTapFeedback(
                onTap: () => context.push(
                  AppRouter.homeSectionDetails,
                  extra: {
                    'title': S.of(context).popular_products,
                    'section': 'popular',
                  },
                ),
                borderRadius: BorderRadius.circular(6.r),
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
              AppTapFeedback(
                onTap: () => setState(() => _popularGridView = false),
                borderRadius: BorderRadius.circular(5.r),
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
              AppTapFeedback(
                onTap: () => setState(() => _popularGridView = true),
                borderRadius: BorderRadius.circular(5.r),
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
      if (_popularGridView)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 8.w,
              mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
            ),
            itemCount: displayProducts.length,
            itemBuilder: (context, index) {
              final product = displayProducts[index];
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
                    '${formatLocalizedNumber(context, product.variants.length)}  •  ${S.of(context).favorites}',
                reviewsLabel:
                    '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${S.of(context).reviews}',
                imageUrl: product.primaryVariantImageUrl,
                imageAssetPath: Assets.imagesShoes,
                campaignLabel: product.campaign?.name.trim().isNotEmpty == true
                    ? product.campaign!.name
                    : (product.campaign?.finishesAt != null
                          ? product.title
                          : ''),
                campaignEndsAt: product.campaign?.finishesAt,
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
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 28.w, 20.h),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: displayProducts.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final product = displayProducts[index];
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
                        '${formatLocalizedNumber(context, product.variants.length)}  •  ${S.of(context).favorites}',
                    reviewsLabel:
                        '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${S.of(context).reviews}',
                    imageUrl: product.primaryVariantImageUrl,
                    imageAssetPath: Assets.imagesShoes,
                    campaignLabel:
                        product.campaign?.name.trim().isNotEmpty == true
                        ? product.campaign!.name
                        : (product.campaign?.finishesAt != null
                              ? product.title
                              : ''),
                    campaignEndsAt: product.campaign?.finishesAt,
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
      SliverToBoxAdapter(child: SizedBox(height: 90.h)),
    ];
  }

  Widget _buildCheckoutSection(BuildContext context) {
    final selectedItems = _selectedCartItems();
    final hasSelectedItems = selectedItems.isNotEmpty;
    final double cartTotal = hasSelectedItems
        ? (_sumNullableMoney(selectedItems, (item) => item.totalPrice) ??
              _computedCartTotalFromCurrentItems(selectedItems))
        : 0.0;
    final double? discountAmount = hasSelectedItems
        ? _sumNullableMoney(selectedItems, (item) => item.discountPrice)
        : null;
    final double effectiveGrandTotal = hasSelectedItems
        ? (_sumNullableMoney(selectedItems, (item) => item.apiTotal) ??
              (cartTotal - (discountAmount ?? 0.0))
                  .clamp(0, double.infinity)
                  .toDouble())
        : 0.0;
    final mutedBorder = const Color(0xFFD9D9D9);
    final titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 16.sp,
      fontWeight: FontWeight.w400,
      fontFamily: 'Montes',
      height: 24 / 16,
    );
    final labelStyle = TextStyle(
      color: Colors.black,
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      fontFamily: 'Montes',
      height: 18 / 14,
    );
    final valueStyle = TextStyle(
      color: Colors.black,
      fontSize: 16.sp,
      fontWeight: FontWeight.w400,
      fontFamily: 'Montes',
      height: 24 / 16,
    );
    final totalLabelStyle = TextStyle(
      color: Colors.black,
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      fontFamily: 'Montes',
      height: 24 / 16,
    );
    final totalAmountStyle = TextStyle(
      color: Colors.black,
      fontSize: 20.sp,
      fontWeight: FontWeight.w400,
      fontFamily: 'Montes',
      height: 24 / 20,
    );
    final activeCouponCode = (widget.couponCode ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFreeShippingStatusCard(context),
        SizedBox(height: 14.h),
        Divider(height: 1, thickness: 1, color: mutedBorder),
        SizedBox(height: 28.h),
        Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'ملخص الطلب'
              : 'Order Summary',
          style: titleStyle,
        ),
        SizedBox(height: 18.h),
        _priceRow(
          context,
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'المجموع الفرعي'
              : 'Subtotal',
          _money(cartTotal),
          textStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        if (discountAmount != null)
          _priceRow(
            context,
            _discountLabel(context),
            _money(discountAmount),
            textStyle: labelStyle,
            valueStyle: valueStyle,
            valuePrefix: '-',
          )
        else
          _priceRow(
            context,
            _discountLabel(context),
            '-',
            textStyle: labelStyle,
            valueStyle: valueStyle,
            appendCurrency: false,
          ),
        SizedBox(height: 10.h),
        _priceRow(
          context,
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'الإجمالي'
              : 'Total',
          _money(effectiveGrandTotal),
          textStyle: totalLabelStyle,
          valueStyle: totalAmountStyle,
        ),
        SizedBox(height: 28.h),
        Divider(height: 1, thickness: 1, color: mutedBorder),
        SizedBox(height: 28.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: (_quantitySyncingItemKeys.isNotEmpty || _loading)
                ? null
                : () async {
                    if (!_hasSelectedCartItems) {
                      _showSelectCartItemRequiredMessage();
                      return;
                    }
                    if (!_isLoggedIn) {
                      unawaited(
                        sl<AppsFlyerService>().logConversionEvent(
                          'login_required',
                          eventParams: {
                            'category': 'checkout',
                            'cart_value': cartTotal,
                            'currency': _selectedCurrencyCode(),
                          },
                        ),
                      );
                      final next = Uri.encodeComponent(
                        AppRouter.selectingFromBottomNavBarCartTab,
                      );
                      GoRouter.of(
                        context,
                      ).push('${AppRouter.login}?next=$next');
                      return;
                    }
                    if (!_isMinimumOrderReached()) {
                      await _trackAppsFlyerCheckoutThresholds(
                        cartTotal: cartTotal,
                        activeCouponCode: activeCouponCode,
                      );
                      _showMinimumOrderWarningDialog();
                      return;
                    }
                    await _trackAppsFlyerCheckoutThresholds(
                      cartTotal: cartTotal,
                      activeCouponCode: activeCouponCode,
                    );
                    await _trackTikTokCheckout(
                      cartTotal: cartTotal,
                      activeCouponCode: activeCouponCode,
                    );
                    await _trackAppsFlyerInitiatedCheckout(
                      cartTotal: cartTotal,
                    );
                    _goToCheckout(
                      cartTotal: cartTotal,
                      discountAmount: discountAmount ?? 0.0,
                      effectiveGrandTotal: effectiveGrandTotal,
                      activeCouponCode: activeCouponCode,
                    );
                  },
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD72631),
                  disabledBackgroundColor: const Color(0xFFD72631),
                  elevation: 0,
                  shadowColor: const Color(0x33D72631),
                  animationDuration: const Duration(milliseconds: 160),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return null;
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.white.withAlpha(46);
                    }
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)) {
                      return Colors.white.withAlpha(20);
                    }
                    return null;
                  }),
                  splashFactory: InkRipple.splashFactory,
                ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'إلى الدفع'
                  : 'To Checkout',
              style: AppStyle.styleButtonLabel14Regular(
                context,
              ).copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _goToCheckout({
    required double cartTotal,
    required double discountAmount,
    required double effectiveGrandTotal,
    required String activeCouponCode,
  }) {
    final selectedItems = _selectedCartItems();
    final selectedCartItemUuids = selectedItems
        .map((item) => (item.id ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toList();
    GoRouter.of(context).push(
      AppRouter.confirmShippingAddressScreen,
      extra: <String, dynamic>{
        "cartList": selectedItems,
        "cartItemUuids": selectedCartItemUuids,
        "subTotal": cartTotal,
        "shipping": 0.0,
        "discountTotal": discountAmount,
        "total": effectiveGrandTotal,
        "itemsDiscount": 0.0,
        "couponDiscount": 0.0,
        "couponCode": activeCouponCode,
        "appliedCouponCode": activeCouponCode,
        "isShippingValid": _isShippingValid,
        "shippingDetails": _shipping,
        "address": _address,
        "api_cart_total": _apiCartTotal,
        "api_shipping_total": 0.0,
        "api_grand_total": effectiveGrandTotal,
      },
    );
  }

  Widget _buildFreeShippingStatusCard(BuildContext context) {
    final threshold = _effectiveMinimumOrderAmount();
    final subtotal = _cartSubtotalForFreeShipping();
    final remaining = _remainingForMinimumOrder();
    final minimumReached = remaining <= 0;
    final freeShippingThreshold = _effectiveFreeShippingThreshold();
    final freeShippingRemaining = _remainingForFreeShipping();
    final freeShippingReached = _isQualifiedForFreeShipping();
    final progress = threshold <= 0
        ? 1.0
        : (subtotal / threshold).clamp(0.0, 1.0).toDouble();
    final currency = _selectedCurrencyCode().toUpperCase();
    final remainingText = formatMoneyForDisplay(context, remaining, currency);
    final thresholdText = formatMoneyForDisplay(context, threshold, currency);
    final freeShippingRemainingText = formatMoneyForDisplay(
      context,
      freeShippingRemaining,
      currency,
    );
    final isArabic = _isArabic(context);

    final title = minimumReached
        ? (isArabic
              ? 'تم الوصول إلى الحد الأدنى للطلب'
              : 'Minimum order reached')
        : (isArabic
              ? 'أضف $remainingText للوصول إلى الحد الأدنى للطلب'
              : 'Add $remainingText more to reach the minimum order');
    final subtitle = !minimumReached
        ? (isArabic
              ? 'الحد الأدنى للطلب: $thresholdText'
              : 'Minimum order value: $thresholdText')
        : freeShippingThreshold == null
        ? (isArabic
              ? 'يمكنك الآن المتابعة إلى الدفع.'
              : 'You can now checkout.')
        : freeShippingReached
        ? (isArabic
              ? 'أنت مؤهل للشحن المجاني.'
              : 'You are qualified for free shipping.')
        : (isArabic
              ? 'أضف $freeShippingRemainingText إضافية للحصول على الشحن المجاني.'
              : 'Add $freeShippingRemainingText more to unlock free shipping.');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: minimumReached
            ? const Color(0xFFEAF9F2)
            : const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: minimumReached
              ? const Color(0xFFB7E4CF)
              : const Color(0xFFF7D3B8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                minimumReached
                    ? Icons.verified_rounded
                    : Icons.shopping_cart_checkout_rounded,
                color: minimumReached
                    ? const Color(0xFF0E9F6E)
                    : const Color(0xFFD97706),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montes',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7.h,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                minimumReached
                    ? const Color(0xFF0E9F6E)
                    : const Color(0xFFD97706),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF374151),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Montes',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMinimumOrderWarningDialog() async {
    final isArabic = _isArabic(context);
    final remaining = _remainingForMinimumOrder();
    final threshold = _effectiveMinimumOrderAmount();
    final currency = _selectedCurrencyCode().toUpperCase();
    final remainingText = formatMoneyForDisplay(context, remaining, currency);
    final thresholdText = formatMoneyForDisplay(context, threshold, currency);

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 22.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 14.h),
                Text(
                  isArabic
                      ? 'أنت قريب من الحد الأدنى للطلب'
                      : 'You are close to the minimum order',
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montes',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isArabic
                      ? 'أضف $remainingText إضافية للوصول إلى الحد الأدنى للطلب $thresholdText.'
                      : 'Add $remainingText more to reach the minimum order value of $thresholdText.',
                  style: TextStyle(
                    color: const Color(0xFF4B5563),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montes',
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      minimumSize: Size.fromHeight(46.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(isArabic ? 'أضف المزيد' : 'Add More'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? textStyle,
    TextStyle? valueStyle,
    bool appendCurrency = true,
    String valuePrefix = '',
  }) {
    final resolvedTextStyle =
        textStyle ??
        TextStyle(
          color: Colors.black,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Montes',
          height: 24 / 16,
        );
    final resolvedValueStyle = valueStyle ?? resolvedTextStyle;
    final displayValue = appendCurrency
        ? '$valuePrefix${formatMoneyForDisplay(context, value, _selectedCurrencyCode())}'
        : '$valuePrefix$value';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: resolvedTextStyle)),
          Text(displayValue, style: resolvedValueStyle),
        ],
      ),
    );
  }
}

/// ===============================
/// SHIMMER (NO PACKAGES)
/// ===============================

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;

        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.0 - 2.0 * (1.0 - t), -0.2),
              end: Alignment(1.0 + 2.0 * t, 0.2),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.height,
    required this.width,
    this.radius = 12,
    this.margin,
  });

  final double height;
  final double width;
  final double radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _CartShimmerList extends StatelessWidget {
  const _CartShimmerList();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: List.generate(4, (i) {
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _ShimmerBox(height: 72.h, width: 72.h, radius: 12),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(
                          height: 12.h,
                          width: double.infinity,
                          radius: 8,
                          margin: EdgeInsets.only(bottom: 10.h),
                        ),
                        _ShimmerBox(
                          height: 12.h,
                          width: 180.w,
                          radius: 8,
                          margin: EdgeInsets.only(bottom: 14.h),
                        ),
                        Row(
                          children: [
                            _ShimmerBox(height: 12.h, width: 80.w, radius: 8),
                            const Spacer(),
                            _ShimmerBox(height: 28.h, width: 90.w, radius: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CartEmptyStateCard extends StatelessWidget {
  const _CartEmptyStateCard({required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFD72631);
    const iconBackgroundColor = Color(0xFFD72631);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 343.w, minHeight: 326.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 18.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50.w,
                height: 50.h,
                decoration: const BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                isArabic ? 'سلة التسوق فارغة!' : 'Your cart is empty!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montes',
                  height: 24 / 16,
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Text(
                  isArabic
                      ? 'أضف منتجات إلى سلة التسوق لمراجعتها وإتمام الدفع بسرعة.'
                      : 'Add products to your cart to review and checkout quickly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 14.sp,
                    height: 24 / 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Montes',
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: 295.w,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: onContinueShopping,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'متابعة التسوق' : 'Continue Shopping',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montes',
                      height: 24 / 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              const _PaymentMethodsRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodsRow extends StatelessWidget {
  const _PaymentMethodsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 10.h,
      children: const [
        _PaymentMethodBadge.image(assetPath: Assets.imagesImageVisa),
        _PaymentMethodBadge.svg(assetPath: Assets.imagesIconsLogosMastercard),
        _PaymentMethodBadge.googlePay(),
        _PaymentMethodBadge.applePay(),
      ],
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  const _PaymentMethodBadge.image({required this.assetPath})
    : label = null,
      iconAssetPath = null,
      isSvg = false;

  const _PaymentMethodBadge.svg({required this.assetPath})
    : label = null,
      iconAssetPath = null,
      isSvg = true;

  const _PaymentMethodBadge.googlePay()
    : assetPath = null,
      iconAssetPath = Assets.imagesGoogleIcon,
      label = 'Pay',
      isSvg = true;

  const _PaymentMethodBadge.applePay()
    : assetPath = null,
      iconAssetPath = Assets.imagesAppleIcon,
      label = 'Pay',
      isSvg = true;

  final String? assetPath;
  final String? iconAssetPath;
  final String? label;
  final bool isSvg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88.w,
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Center(
        child: assetPath != null
            ? (isSvg
                  ? SvgPicture.asset(assetPath!, height: 20.h)
                  : Image.asset(assetPath!, height: 24.h, fit: BoxFit.contain))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(iconAssetPath!, width: 18.w, height: 18.h),
                  SizedBox(width: 4.w),
                  Text(
                    label!,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montes',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PopularProductsShimmerRow extends StatelessWidget {
  const _PopularProductsShimmerRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProductCollectionCard.compactCardHeight.h,
      child: Row(
        children: List.generate(
          2,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == 0 ? 8.w : 0),
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE6E6E6),
                highlightColor: const Color(0xFFF5F5F5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartStateMessageCard extends StatelessWidget {
  const _CartStateMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Widget icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          icon,
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montes',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF667085),
              fontSize: 14.sp,
              height: 1.5,
              fontFamily: 'Montes',
            ),
          ),
        ],
      ),
    );
  }
}
