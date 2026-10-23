import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/startup_gate_service.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

enum _AppsFlyerRouteSource { none, deferred, direct }

class AppsFlyerService {
  AppsFlyerService();

  AppsflyerSdk? _sdk;
  bool _initialized = false;
  bool _reportedMissingConfig = false;
  String? _pendingRoute;
  _AppsFlyerRouteSource _pendingRouteSource = _AppsFlyerRouteSource.none;
  String? _lastCustomerUserId;
  final String _sessionId = const Uuid().v4();
  Future<Map<String, dynamic>>? _staticMetadataFuture;
  Map<String, String> _campaignMetadata = const <String, String>{};

  bool get isEnabled {
    final devKey = _devKey;
    if (devKey.isEmpty) return false;
    if (Platform.isIOS && _iosAppId.isEmpty) return false;
    return true;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isEnabled) {
      if (!_reportedMissingConfig) {
        _reportedMissingConfig = true;
        debugPrint(
          '[APPSFLYER] Skipping SDK initialization because APPSFLYER_DEV_KEY'
          '${Platform.isIOS ? ' / APPSFLYER_APP_ID' : ''} is missing.',
        );
      }
      return;
    }

    try {
      final options = AppsFlyerOptions(
        afDevKey: _devKey,
        appId: Platform.isIOS ? _iosAppId : '',
        showDebug: !AppConfig.instance.flavor.isProduction,
        manualStart: true,
      );
      _sdk = AppsflyerSdk(options);

      _sdk!.onDeepLinking(_handleDeepLinking);
      _sdk!.onInstallConversionData(_handleConversionData);

      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      if (Platform.isAndroid) {
        _sdk!.performOnDeepLinking();
      }

      _sdk!.startSDK(
        onSuccess: () {
          debugPrint('[APPSFLYER] SDK started successfully');
        },
        onError: (int errorCode, String errorMessage) {
          debugPrint(
            '[APPSFLYER] SDK start failed: Code $errorCode - $errorMessage',
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('[APPSFLYER] Initialization failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> syncCustomerUserId({String? customerUserId}) async {
    final resolvedId = (customerUserId?.trim().isNotEmpty ?? false)
        ? customerUserId!.trim()
        : await _resolveCustomerUserIdFromCache();
    if (resolvedId.isEmpty || resolvedId == _lastCustomerUserId) {
      return;
    }

    _lastCustomerUserId = resolvedId;
    try {
      _sdk?.setCustomerUserId(resolvedId);
    } catch (error, stackTrace) {
      debugPrint('[APPSFLYER] setCustomerUserId failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> logProductView({
    required String productId,
    String? productSlug,
    bool isDeepLink = false,
  }) async {
    await logConversionEvent(
      'view_item',
      eventParams: {'product_id': productId.trim(), 'category': 'product'},
    );
    await _logContentView(
      contentType: 'product',
      contentId: productId,
      contentSlug: productSlug,
      isDeepLink: isDeepLink,
    );
  }

  Future<void> logCompleteRegistration({
    required String registrationMethod,
  }) async {
    final method = registrationMethod.trim();
    await _logEvent('af_complete_registration', <String, dynamic>{
      if (method.isNotEmpty) 'af_registration_method': method,
    });
  }

  Future<void> logAppOpen() async {
    await logConversionEvent('app_open');
    await _logEvent('af_app_open', <String, dynamic>{});
  }

  Future<void> logLogin() async {
    await logConversionEvent('otp_verified');
    await _logEvent('af_login', <String, dynamic>{});
  }

  Future<void> logUserLogin() async {
    await logLogin();
  }

  Future<void> logUserRegister({required String registrationMethod}) async {
    await logCompleteRegistration(registrationMethod: registrationMethod);
  }

  Future<void> logSearch({
    required String searchString,
    List<String>? contentList,
  }) async {
    final query = searchString.trim();
    await logConversionEvent('search', eventParams: {'category': query});
    await logConversionEvent(
      'view_search_results',
      eventParams: {
        'category': query,
        if ((contentList ?? const []).isNotEmpty)
          'product_id': _normalizeStringList(contentList!).join(','),
      },
    );
    await _logEvent('af_search', <String, dynamic>{
      if (query.isNotEmpty) 'af_search_string': query,
      if ((contentList ?? const []).isNotEmpty)
        'af_content_list': _normalizeStringList(contentList!),
    });
  }

  Future<void> logListView({
    required String contentType,
    required List<String> contentList,
  }) async {
    await logConversionEvent(
      'view_item_list',
      eventParams: {
        'category': contentType.trim(),
        if (contentList.isNotEmpty)
          'product_id': _normalizeStringList(contentList).join(','),
      },
    );
    await _logEvent('af_list_view', <String, dynamic>{
      'af_content_type': contentType.trim(),
      if (contentList.isNotEmpty)
        'af_content_list': _normalizeStringList(contentList),
    });
  }

  Future<void> logCategoryView({
    required String categorySlug,
    int? categoryId,
    String? parentName,
    String? childName,
    bool isDeepLink = false,
  }) async {
    await logConversionEvent(
      'view_category',
      eventParams: {
        'category': childName?.trim().isNotEmpty == true
            ? childName!.trim()
            : parentName?.trim().isNotEmpty == true
            ? parentName!.trim()
            : categorySlug.trim(),
      },
    );
    await _logContentView(
      contentType: 'category',
      contentId: categoryId?.toString() ?? categorySlug,
      contentSlug: categorySlug,
      parentName: parentName,
      childName: childName,
      isDeepLink: isDeepLink,
    );
  }

  Future<void> logAddToWishlist({
    required String contentId,
    String? contentType,
    String? price,
    String? currency,
  }) async {
    await logConversionEvent(
      'add_to_wishlist',
      eventParams: {
        'product_id': contentId.trim(),
        'category': (contentType ?? 'product').trim(),
        'item_value': _numberValue(price),
        if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
      },
    );
    await _logEvent('af_add_to_wishlist', <String, dynamic>{
      'af_content_id': contentId.trim(),
      if (contentId.trim().isNotEmpty) 'af_content': contentId.trim(),
      if ((contentType ?? '').trim().isNotEmpty)
        'af_content_type': contentType!.trim(),
      if ((price ?? '').trim().isNotEmpty) 'af_price': price!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'af_currency': currency!.trim(),
    });
  }

  Future<void> logAddToCart({
    required String contentId,
    required String contentType,
    required String price,
    required String currency,
    int quantity = 1,
  }) async {
    final trimmedContentId = contentId.trim();
    await logConversionEvent(
      'add_to_cart',
      eventParams: {
        'product_id': trimmedContentId,
        'category': contentType.trim(),
        'quantity': quantity,
        'item_value': _numberValue(price),
        if (currency.trim().isNotEmpty) 'currency': currency.trim(),
      },
    );
    await _logEvent('af_add_to_cart', <String, dynamic>{
      'af_content_id': trimmedContentId,
      if (trimmedContentId.isNotEmpty) 'af_content': trimmedContentId,
      'af_content_type': contentType.trim(),
      'af_price': price.trim(),
      'af_currency': currency.trim(),
      'af_quantity': quantity,
    });
  }

  Future<void> logInitiatedCheckout({
    required List<String> contentIds,
    required String contentType,
    required String price,
    required String currency,
    int quantity = 1,
  }) async {
    final normalizedContentIds = _normalizeStringList(contentIds);
    await logConversionEvent(
      'begin_checkout',
      eventParams: {
        if (normalizedContentIds.isNotEmpty)
          'product_id': normalizedContentIds.join(','),
        'category': contentType.trim(),
        'quantity': quantity,
        'cart_value': _numberValue(price),
        if (currency.trim().isNotEmpty) 'currency': currency.trim(),
      },
    );
    await _logEvent('af_initiated_checkout', <String, dynamic>{
      if (normalizedContentIds.isNotEmpty)
        'af_content_id': normalizedContentIds,
      if (normalizedContentIds.isNotEmpty)
        'af_content': normalizedContentIds.first,
      'af_content_type': contentType.trim(),
      'af_price': price.trim(),
      'af_currency': currency.trim(),
      'af_quantity': quantity,
    });
  }

  Future<void> logPurchase({
    required String orderId,
    String? receiptId,
    required List<String> contentIds,
    required String contentType,
    required String revenue,
    required String price,
    required String currency,
    int quantity = 1,
  }) async {
    final trimmedOrderId = orderId.trim();
    final trimmedReceiptId = (receiptId ?? orderId).trim();
    final normalizedContentIds = _normalizeStringList(contentIds);
    final purchaseParams = <String, dynamic>{
      'order_id': trimmedOrderId,
      'gateway_transaction_reference': trimmedReceiptId,
      if (normalizedContentIds.isNotEmpty)
        'product_id': normalizedContentIds.join(','),
      'category': contentType.trim(),
      'quantity': quantity,
      'item_value': _numberValue(price),
      'cart_value': _numberValue(revenue),
      if (currency.trim().isNotEmpty) 'currency': currency.trim(),
    };
    await logConversionEvent(
      'payment_success_client',
      eventParams: purchaseParams,
    );
    await logConversionEvent('purchase', eventParams: purchaseParams);
    await _logEvent('af_purchase', <String, dynamic>{
      'af_revenue': revenue.trim(),
      'af_price': price.trim(),
      if (normalizedContentIds.isNotEmpty)
        'af_content': normalizedContentIds.first,
      if (normalizedContentIds.isNotEmpty)
        'af_content_id': normalizedContentIds,
      'af_content_type': contentType.trim(),
      'af_currency': currency.trim(),
      'af_quantity': quantity,
      if (trimmedOrderId.isNotEmpty) 'af_order_id': trimmedOrderId,
      if (trimmedReceiptId.isNotEmpty) 'af_receipt_id': trimmedReceiptId,
    });
  }

  Future<void> logRemoveFromCart({
    required String contentId,
    required String contentType,
  }) async {
    final trimmedContentId = contentId.trim();
    await logConversionEvent(
      'remove_from_cart',
      eventParams: {
        'product_id': trimmedContentId,
        'category': contentType.trim(),
      },
    );
    await _logEvent('af_remove_from_cart', <String, dynamic>{
      'af_content_id': trimmedContentId,
      if (trimmedContentId.isNotEmpty) 'af_content': trimmedContentId,
      'af_content_type': contentType.trim(),
    });
  }

  Future<void> logConversionEvent(
    String eventName, {
    Map<String, dynamic> eventParams = const <String, dynamic>{},
  }) async {
    final trimmedEventName = eventName.trim();
    if (trimmedEventName.isEmpty) return;

    try {
      final params = await _buildConversionEventParams(eventParams);
      await _logEvent(trimmedEventName, params);
    } catch (error, stackTrace) {
      debugPrint('[APPSFLYER] conversion event failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  String? buildProductShareLink({
    required String productId,
    String? productSlug,
    String? variantUuid,
  }) {
    return _buildOneLink(
      deepLinkValue: 'product',
      params: {
        if (productId.trim().isNotEmpty) 'product_id': productId.trim(),
        if ((productSlug ?? '').trim().isNotEmpty)
          'product_slug': productSlug!.trim(),
        if ((variantUuid ?? '').trim().isNotEmpty)
          'selectedVariantUuid': variantUuid!.trim(),
      },
    );
  }

  String? buildCategoryShareLink({
    String? categorySlug,
    int? categoryId,
    String? parentName,
    String? parentSlug,
    String? childName,
  }) {
    return _buildOneLink(
      deepLinkValue: 'category',
      params: {
        if ((categorySlug ?? '').trim().isNotEmpty)
          'category_slug': categorySlug!.trim(),
        if (categoryId != null) 'category_id': categoryId.toString(),
        if ((parentName ?? '').trim().isNotEmpty)
          'parent_name': parentName!.trim(),
        if ((parentSlug ?? '').trim().isNotEmpty)
          'parent_slug': parentSlug!.trim(),
        if ((childName ?? '').trim().isNotEmpty)
          'child_name': childName!.trim(),
      },
    );
  }

  String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    _pendingRouteSource = _AppsFlyerRouteSource.none;
    return route;
  }

  String? peekPendingRoute() => _pendingRoute;

  void _handleDeepLinking(DeepLinkResult result) {
    if (result.status != Status.FOUND) {
      debugPrint('[APPSFLYER] Deep link not found: ${result.status}');
      return;
    }

    final payload = _extractPayload(
      result,
      fallbackSource: _AppsFlyerRouteSource.direct,
    );
    _captureCampaignMetadata(payload);
    unawaited(
      logConversionEvent(
        'deep_link_open',
        eventParams: _eventParamsFromAttributionPayload(payload),
      ),
    );
    final route = _routeFromPayload(payload);
    if (route == null) return;
    _storeRoute(route, _AppsFlyerRouteSource.direct);
  }

  void _handleConversionData(dynamic response) {
    final payload = _extractPayload(
      response,
      fallbackSource: _AppsFlyerRouteSource.deferred,
    );
    final status = _stringValue(payload, const [
      'af_status',
      'afStatus',
    ]).toLowerCase();
    final isFirstLaunch =
        _boolValue(payload['is_first_launch']) ||
        _boolValue(payload['isFirstLaunch']);
    _captureCampaignMetadata(payload);
    if (isFirstLaunch) {
      unawaited(
        logConversionEvent(
          'first_open',
          eventParams: _eventParamsFromAttributionPayload(payload),
        ),
      );
    }
    if (status != 'non-organic' || !isFirstLaunch) {
      return;
    }

    unawaited(
      logConversionEvent(
        'campaign_attributed',
        eventParams: _eventParamsFromAttributionPayload(payload),
      ),
    );

    final route = _routeFromPayload(payload);
    if (route == null) return;
    _storeRoute(route, _AppsFlyerRouteSource.deferred);
  }

  Future<void> _logContentView({
    required String contentType,
    required String contentId,
    String? contentSlug,
    String? parentName,
    String? childName,
    required bool isDeepLink,
  }) async {
    final sdk = _sdk;
    if (sdk == null || contentId.trim().isEmpty) return;

    final eventValues = <String, dynamic>{
      'af_content_type': contentType,
      'af_content_id': contentId.trim(),
      if ((contentSlug ?? '').trim().isNotEmpty)
        'content_slug': contentSlug!.trim(),
      if ((parentName ?? '').trim().isNotEmpty)
        'parent_name': parentName!.trim(),
      if ((childName ?? '').trim().isNotEmpty) 'child_name': childName!.trim(),
      'deep_link_source': isDeepLink ? 'appsflyer' : 'in_app',
    };

    try {
      await sdk.logEvent('af_content_view', eventValues);
    } catch (error, stackTrace) {
      debugPrint('[APPSFLYER] logEvent failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _logEvent(
    String eventName,
    Map<String, dynamic> eventValues,
  ) async {
    final sdk = _sdk;
    if (sdk == null) return;

    try {
      await sdk.logEvent(eventName, eventValues);
    } catch (error, stackTrace) {
      debugPrint('[APPSFLYER] logEvent failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Future<Map<String, dynamic>> _buildConversionEventParams(
    Map<String, dynamic> eventParams,
  ) async {
    final staticMetadata = await (_staticMetadataFuture ??=
        _loadStaticMetadata());
    final userMetadata = await _loadUserMetadata();

    final params = <String, dynamic>{
      'anonymous_user_id': '',
      'logged_in_user_id': '',
      'session_id': _sessionId,
      'event_id': const Uuid().v4(),
      'platform': _platformName(),
      'app_version': '',
      'os_version': '',
      'device_type': '',
      'language': '',
      'country': '',
      'currency': '',
      'campaign_source': '',
      'campaign_name': '',
      'ad_set': '',
      'ad_or_creative_id': '',
      'product_id': '',
      'variant_id': '',
      'category': '',
      'quantity': 0,
      'item_value': 0,
      'cart_value': 0,
      'coupon': '',
      'shipping_method': '',
      'payment_method': '',
      'order_id': '',
      'gateway_transaction_reference': '',
      'error_code': '',
      'error_stage': '',
    };

    params
      ..addAll(staticMetadata)
      ..addAll(userMetadata)
      ..addAll(_campaignMetadata)
      ..addAll(_cleanConversionParams(eventParams));

    return params;
  }

  Future<Map<String, dynamic>> _loadStaticMetadata() async {
    String appVersion = '';
    String osVersion = '';
    String deviceType = '';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.buildNumber.trim().isNotEmpty
          ? '${packageInfo.version}+${packageInfo.buildNumber}'
          : packageInfo.version;
    } catch (_) {}

    try {
      osVersion = Platform.operatingSystemVersion;
    } catch (_) {}

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceType = [
          info.manufacturer,
          info.model,
        ].where((value) => value.trim().isNotEmpty).join(' ');
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceType = [
          info.utsname.machine,
          info.name,
        ].where((value) => value.trim().isNotEmpty).join(' ');
      }
    } catch (_) {}

    return <String, dynamic>{
      'platform': _platformName(),
      'app_version': appVersion,
      'os_version': osVersion,
      'device_type': deviceType,
    };
  }

  Future<Map<String, dynamic>> _loadUserMetadata() async {
    final secureCache = sl<SecureCacheHelper>();
    final cache = sl<CacheHelper>();
    final loggedInId = await _firstSecureValue(secureCache, const [
      'id',
      'customerId',
      'customerUuid',
      'uuid',
    ]);
    final anonymousId =
        await _firstSecureValue(secureCache, const ['guestId', 'guestUUID']) ??
        _sessionId;
    final language =
        _firstCacheValue(cache, const ['languageCode', 'language']) ??
        AppDefaults.defaultLanguageCode;
    final currency =
        _firstCacheValue(cache, const ['currencyCode', 'currency']) ??
        AppDefaults.defaultCurrencyCode;
    final country =
        _firstCacheValue(cache, const [
          'countryCode',
          'country_code',
          'country',
          'selectedCountry',
        ]) ??
        '';

    return <String, dynamic>{
      'anonymous_user_id': anonymousId,
      'logged_in_user_id': loggedInId ?? '',
      'language': language,
      'country': country,
      'currency': currency.toUpperCase(),
    };
  }

  Future<String?> _firstSecureValue(
    SecureCacheHelper cache,
    List<String> keys,
  ) async {
    for (final key in keys) {
      final value = (await cache.getData(key: key))?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _firstCacheValue(CacheHelper cache, List<String> keys) {
    for (final key in keys) {
      final value = cache.getDataString(key: key)?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, dynamic> _cleanConversionParams(Map<String, dynamic> params) {
    return params.map((key, value) {
      if (value is String) return MapEntry(key, value.trim());
      return MapEntry(key, value);
    });
  }

  double _numberValue(String? value) {
    return double.tryParse((value ?? '').trim().replaceAll(',', '')) ?? 0;
  }

  void _captureCampaignMetadata(Map<String, dynamic> payload) {
    final next = _eventParamsFromAttributionPayload(payload);
    if (next.isEmpty) return;
    _campaignMetadata = <String, String>{
      ..._campaignMetadata,
      ...next.map((key, value) => MapEntry(key, value.toString())),
    }..removeWhere((_, value) => value.trim().isEmpty);
  }

  Map<String, dynamic> _eventParamsFromAttributionPayload(
    Map<String, dynamic> payload,
  ) {
    return <String, dynamic>{
      'campaign_source': _stringValue(payload, const [
        'media_source',
        'pid',
        'source',
        'campaign_source',
      ]),
      'campaign_name': _stringValue(payload, const [
        'campaign',
        'c',
        'campaign_name',
      ]),
      'ad_set': _stringValue(payload, const ['adset', 'af_adset', 'ad_set']),
      'ad_or_creative_id': _stringValue(payload, const [
        'ad_id',
        'af_ad_id',
        'ad',
        'creative_id',
        'af_ad',
      ]),
      'product_id': _stringValue(payload, const [
        'product_id',
        'productId',
        'product_uuid',
        'productUuid',
        'af_content_id',
      ]),
      'variant_id': _stringValue(payload, const [
        'selectedVariantUuid',
        'variant_uuid',
        'variantUuid',
      ]),
      'category': _stringValue(payload, const [
        'category',
        'category_slug',
        'categorySlug',
        'deep_link_value',
      ]),
    }..removeWhere((_, value) => value.toString().trim().isEmpty);
  }

  Future<String> _resolveCustomerUserIdFromCache() async {
    final cache = sl<SecureCacheHelper>();
    final customerId = (await cache.getData(key: 'id'))?.trim() ?? '';
    if (customerId.isNotEmpty) return customerId;

    final guestUUID = (await cache.getData(key: 'guestUUID'))?.trim() ?? '';
    if (guestUUID.isNotEmpty) return guestUUID;

    final guestId = (await cache.getData(key: 'guestId'))?.trim() ?? '';
    return guestId;
  }

  List<String> _normalizeStringList(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  void _storeRoute(String route, _AppsFlyerRouteSource source) {
    if (route.trim().isEmpty) return;
    if (_pendingRoute == null || source.index >= _pendingRouteSource.index) {
      _pendingRoute = route;
      _pendingRouteSource = source;
      _navigateToRouteIfReady(route);
    }
  }

  void _navigateToRouteIfReady(String route) {
    if (!sl.isRegistered<StartupGateService>()) return;
    if (!sl<StartupGateService>().isReleased) return;

    scheduleMicrotask(() {
      if (_pendingRoute != route) return;
      try {
        RouterGenerator.mainRouting.go(route);
        _pendingRoute = null;
        _pendingRouteSource = _AppsFlyerRouteSource.none;
      } catch (error, stackTrace) {
        debugPrint('[APPSFLYER] route navigation failed: $error');
        debugPrint(stackTrace.toString());
      }
    });
  }

  Map<String, dynamic> _extractPayload(
    dynamic response, {
    required _AppsFlyerRouteSource fallbackSource,
  }) {
    final payload = _objectToMap(response);
    final deepLink = _objectToMap(payload['deepLink']);
    final clickEvent = _objectToMap(deepLink['clickEvent']);

    final merged = <String, dynamic>{}
      ..addAll(payload)
      ..addAll(deepLink)
      ..addAll(clickEvent);

    _mergeQueryParameters(merged, payload['link']);
    _mergeQueryParameters(merged, deepLink['link']);
    _mergeQueryParameters(merged, deepLink['af_dp']);
    _mergeQueryParameters(merged, payload['af_dp']);

    if (merged.isEmpty && fallbackSource == _AppsFlyerRouteSource.deferred) {
      return payload;
    }
    return merged;
  }

  void _mergeQueryParameters(Map<String, dynamic> target, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return;

    final uri = Uri.tryParse(text);
    if (uri == null) return;

    for (final entry in uri.queryParameters.entries) {
      if (entry.value.trim().isEmpty) continue;
      target.putIfAbsent(entry.key, () => entry.value);
    }

    final host = uri.host.trim();
    final path = uri.path.trim();
    if (host.isNotEmpty) {
      target.putIfAbsent('host', () => host);
    }
    if (path.isNotEmpty) {
      target.putIfAbsent('path', () => path);
    }
  }

  Map<String, dynamic> _objectToMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    try {
      final decoded = jsonDecode(jsonEncode(value));
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  String? _routeFromPayload(Map<String, dynamic> payload) {
    final deepLinkValue = _stringValue(payload, const [
      'deep_link_value',
      'deepLinkValue',
    ]).toLowerCase().trim();
    final genericSlug = _stringValue(payload, const ['slug']).trim();
    final genericId = _stringValue(payload, const ['id']).trim();

    if (deepLinkValue == 'product') {
      final productId = _stringValue(payload, const [
        'product_id',
        'productId',
        'product_uuid',
        'productUuid',
        'product',
        'id',
        'deep_link_sub1',
        'deepLinkSub1',
        'af_sub1',
      ]).trim();
      final productSlug = _stringValue(payload, const [
        'product_slug',
        'productSlug',
        'product_handle',
        'slug',
        'deep_link_sub2',
        'deepLinkSub2',
        'af_sub2',
      ]).trim();
      final variantUuid = _stringValue(payload, const [
        'selectedVariantUuid',
        'variant_uuid',
        'variantUuid',
        'deep_link_sub3',
        'deepLinkSub3',
        'af_sub3',
      ]).trim();
      final params = <String, String>{};
      if (productId.isNotEmpty) params['id'] = productId;
      if (productSlug.isNotEmpty) params['slug'] = productSlug;
      if (variantUuid.isNotEmpty) params['selectedVariantUuid'] = variantUuid;
      if (params.isEmpty) return null;
      return _encodeRoute(AppRouter.productDetails, params);
    }

    if (deepLinkValue == 'category') {
      final categoryId = _stringValue(payload, const [
        'category_id',
        'categoryId',
        'category_uuid',
        'categoryUuid',
      ]).trim();
      final categorySlug = _stringValue(payload, const [
        'category_slug',
        'categorySlug',
        'category',
        'category_handle',
        'slug',
      ]).trim();
      final parentName = _stringValue(payload, const [
        'parent_name',
        'parentName',
      ]).trim();
      final parentSlug = _stringValue(payload, const [
        'parent_slug',
        'parentSlug',
      ]).trim();
      final childName = _stringValue(payload, const [
        'child_name',
        'childName',
      ]).trim();
      final params = <String, String>{};
      if (categorySlug.isNotEmpty) params['slug'] = categorySlug;
      if (categoryId.isNotEmpty) params['id'] = categoryId;
      if (parentName.isNotEmpty) params['parentName'] = parentName;
      if (parentSlug.isNotEmpty) params['parentSlug'] = parentSlug;
      if (childName.isNotEmpty) params['childName'] = childName;
      if (params.isEmpty) return null;
      return _encodeRoute(AppRouter.productByCategory, params);
    }

    // Backward-compatible fallback for older links.
    final rawType = _stringValue(payload, const [
      'screen',
      'route',
      'type',
      'content_type',
    ]).toLowerCase().trim();
    final productId = _stringValue(payload, const [
      'product_id',
      'productId',
      'product_uuid',
      'productUuid',
      'product',
      'id',
      'content_id',
      'af_content_id',
      'deep_link_sub1',
      'deepLinkSub1',
      'af_sub1',
    ]).trim();
    final productSlug = _stringValue(payload, const [
      'product_slug',
      'productSlug',
      'product_handle',
      'deep_link_sub2',
      'deepLinkSub2',
      'af_sub2',
    ]).trim();
    final categorySlug = _stringValue(payload, const [
      'category_slug',
      'categorySlug',
      'category',
      'category_handle',
    ]).trim();
    final categoryId = _stringValue(payload, const [
      'category_id',
      'categoryId',
      'category_uuid',
      'categoryUuid',
      'id',
    ]).trim();

    final productSignals =
        productId.isNotEmpty ||
        productSlug.isNotEmpty ||
        _looksLikeProductRoute(rawType, payload, productId, productSlug);
    final categorySignals =
        categorySlug.isNotEmpty ||
        categoryId.isNotEmpty ||
        genericSlug.isNotEmpty ||
        _looksLikeCategoryRoute(rawType, payload, categorySlug, categoryId);

    if (productSignals || (genericId.isNotEmpty && !categorySignals)) {
      final params = <String, String>{};
      if (productId.isNotEmpty) params['id'] = productId;
      final routeSlug = productSlug.isNotEmpty ? productSlug : genericSlug;
      if (routeSlug.isNotEmpty) params['slug'] = routeSlug;
      return _encodeRoute(AppRouter.productDetails, params);
    }

    if (categorySignals ||
        (genericId.isNotEmpty && !productSignals && genericSlug.isNotEmpty)) {
      final params = <String, String>{};
      final routeSlug = categorySlug.isNotEmpty ? categorySlug : genericSlug;
      if (routeSlug.isNotEmpty) params['slug'] = routeSlug;
      if (categoryId.isNotEmpty) params['id'] = categoryId;
      return _encodeRoute(AppRouter.productByCategory, params);
    }

    return null;
  }

  bool _looksLikeProductRoute(
    String rawType,
    Map<String, dynamic> payload,
    String productId,
    String productSlug,
  ) {
    if (productId.isNotEmpty || productSlug.isNotEmpty) {
      return true;
    }

    final rawTarget = <String>[
      rawType,
      _stringValue(payload, const ['af_dp']).toLowerCase(),
      _stringValue(payload, const ['path']).toLowerCase(),
      _stringValue(payload, const ['host']).toLowerCase(),
    ].join(' ');

    return rawTarget.contains('product') ||
        rawTarget.contains('productdetail') ||
        rawTarget.contains('product-details') ||
        rawTarget.contains('product_details');
  }

  bool _looksLikeCategoryRoute(
    String rawType,
    Map<String, dynamic> payload,
    String categorySlug,
    String categoryId,
  ) {
    if (categorySlug.isNotEmpty || categoryId.isNotEmpty) {
      return true;
    }

    final rawTarget = <String>[
      rawType,
      _stringValue(payload, const ['af_dp']).toLowerCase(),
      _stringValue(payload, const ['path']).toLowerCase(),
      _stringValue(payload, const ['host']).toLowerCase(),
    ].join(' ');

    return rawTarget.contains('category') ||
        rawTarget.contains('categories') ||
        rawTarget.contains('products_by_category') ||
        rawTarget.contains('productbycategory') ||
        rawTarget.contains('product-by-category');
  }

  String _encodeRoute(String path, Map<String, String> queryParameters) {
    final uri = Uri(
      path: path,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return uri.toString();
  }

  String? _buildOneLink({
    required String deepLinkValue,
    required Map<String, String> params,
  }) {
    final base = _normalizedOneLinkUrl;
    if (base.isEmpty) return null;

    final cleaned = <String, String>{
      'deep_link_value': deepLinkValue,
      ...params,
    }..removeWhere((key, value) => value.trim().isEmpty);

    final uri = Uri.parse(base);
    return uri.replace(queryParameters: cleaned).toString();
  }

  String get _normalizedOneLinkUrl {
    final raw = _oneLinkUrl;
    if (raw.isEmpty) return '';

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return raw;
    }

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      return uri.replace(path: '').toString();
    }

    // Keep only the OneLink template id and drop any short-link suffix.
    return uri
        .replace(path: '/${pathSegments.first}', queryParameters: null)
        .toString();
  }

  String _stringValue(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return const {'true', '1', 'yes', 'y'}.contains(text);
  }

  String _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }

  String get _devKey => dotenv.env['APPSFLYER_DEV_KEY']?.trim() ?? '';

  String get _iosAppId => dotenv.env['APPSFLYER_APP_ID']?.trim() ?? '';

  String get _oneLinkUrl => dotenv.env['APPSFLYER_ONELINK_URL']?.trim() ?? '';
}
