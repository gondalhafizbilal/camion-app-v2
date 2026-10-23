import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/variation.dart';
import 'package:flutter/foundation.dart';

double _parseDouble(dynamic v) {
  return parseMoneyValue(v);
}

String _parseString(dynamic v) {
  if (v == null) return '';
  return v.toString();
}

String _currentLanguageCode() {
  final saved = sl<CacheHelper>().getDataString(key: 'languageCode');
  final normalized = saved?.trim().toLowerCase() ?? '';
  if (normalized.isNotEmpty) {
    return normalized;
  }
  return AppDefaults.defaultLanguageCode.toLowerCase();
}

String _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final text = _parseString(value).trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _resolveLocalizedTitle(Map<String, dynamic> data) {
  final languageCode = _currentLanguageCode();
  final preferredKeys = languageCode == 'ar'
      ? <String>[
          'titleAr',
          'arabicTitle',
          'nameAr',
          'localizedTitleAr',
          'title',
          'name',
          'titleEn',
          'englishTitle',
          'nameEn',
        ]
      : <String>[
          'titleEn',
          'englishTitle',
          'nameEn',
          'localizedTitleEn',
          'title',
          'name',
          'titleAr',
          'arabicTitle',
          'nameAr',
        ];
  return _firstNonEmpty(preferredKeys.map((key) => data[key]));
}

DateTime? _parseServerUtcToLocal(dynamic value) {
  final raw = _parseString(value).trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  if (parsed.isUtc) {
    final local = parsed.toLocal();
    _logTimeConversion(raw, local);
    return local;
  }

  final hasExplicitTimezone = RegExp(r'(z|Z|[+-]\d{2}:\d{2})$').hasMatch(raw);
  if (hasExplicitTimezone) {
    final local = parsed.toLocal();
    _logTimeConversion(raw, local);
    return local;
  }

  final assumedUtc = DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
  final local = assumedUtc.toLocal();
  _logTimeConversion(raw, local);
  return local;
}

void _logTimeConversion(String serverRawTime, DateTime localTime) {
  if (!kDebugMode) return;
  final offset = localTime.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hh = offset.inHours.abs().toString().padLeft(2, '0');
  final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  debugPrint(
    '[OrderTime] server="$serverRawTime" local="${localTime.toIso8601String()}" timezone="${localTime.timeZoneName} (UTC$sign$hh:$mm)"',
  );
}

String _parseProductTitle(Map<String, dynamic> product) {
  return _resolveLocalizedTitle(product);
}

String _extractCategoryNameFromProduct(Map<String, dynamic> product) {
  final direct = _parseString(product['categoryName']);
  if (direct.trim().isNotEmpty) return direct;

  final category = _asMap(product['category']);
  final categoryName = _parseString(
    category['name'] ?? category['title'] ?? category['label'],
  );
  if (categoryName.trim().isNotEmpty) return categoryName;

  final categories = product['categories'];
  if (categories is List && categories.isNotEmpty) {
    for (final item in categories) {
      final map = _asMap(item);
      final name = _parseString(map['name'] ?? map['title'] ?? map['label']);
      if (name.trim().isNotEmpty) return name;
    }
  }

  return '';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

String _extractBestVariantImage(Map<String, dynamic> variant) {
  final variantImages = (variant['images'] as List? ?? const <dynamic>[])
      .map(_asMap)
      .toList();
  for (final image in variantImages) {
    final thumbnail = _parseString(image['thumbnailUrl']).trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    final imageUrl = _parseString(image['imageUrl']).trim();
    if (imageUrl.isNotEmpty) return imageUrl;
  }

  final directImage = _parseString(variant['image']).trim();
  if (directImage.isNotEmpty) return directImage;

  return '';
}

List<Variation> _buildVariantVariations({
  required Map<String, dynamic> json,
  required Map<String, dynamic> product,
  required Map<String, dynamic> variant,
  bool includeSkuBarcode = false,
}) {
  final list = <Variation>[];
  final seen = <String>{};

  void addVariation(String attribute, String value) {
    final attr = attribute.trim();
    final val = value.trim();
    if (attr.isEmpty || val.isEmpty) return;
    final key = '${attr.toLowerCase()}|${val.toLowerCase()}';
    if (!seen.add(key)) return;
    list.add(Variation(attribute: attr, value: val));
  }

  final rawVariation = json['variation'];
  if (rawVariation is List) {
    for (final entry in rawVariation.whereType<Map>()) {
      final map = Map<String, dynamic>.from(entry);
      addVariation(
        _parseString(
          map['attribute'].toString().isEmpty ? map['name'] : map['attribute'],
        ),
        _parseString(
          map['value'].toString().isEmpty ? map['option'] : map['value'],
        ),
      );
    }
  } else if (rawVariation is Map) {
    final parsed = Map<String, dynamic>.from(rawVariation);
    final attributes = parsed['attributes'];
    if (attributes is List) {
      for (final entry in attributes.whereType<Map>()) {
        final attr = Map<String, dynamic>.from(entry);
        addVariation(
          _parseString(
            attr['name'].toString().isEmpty ? attr['attribute'] : attr['name'],
          ),
          _parseString(
            attr['option'].toString().isEmpty ? attr['value'] : attr['option'],
          ),
        );
      }
    }
  }

  final optionValues = variant['optionValues'];
  final optionValueByUuid = <String, ({String key, String value})>{};
  final options = (product['options'] as List? ?? const <dynamic>[])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
  for (final option in options) {
    final optionName = _parseString(option['name']).trim();
    if (optionName.isEmpty) continue;
    final values = (option['values'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    for (final value in values) {
      final valueUuid = _parseString(value['uuid']).trim();
      final valueText = _parseString(value['value']).trim();
      if (valueUuid.isEmpty || valueText.isEmpty) continue;
      optionValueByUuid[valueUuid] = (key: optionName, value: valueText);
    }
  }
  if (optionValues is List) {
    for (final entry in optionValues.whereType<Map>()) {
      final ref = Map<String, dynamic>.from(entry);
      final optionValue = _asMap(ref['optionValue']);
      final directOption = _asMap(optionValue['option']);
      final directOptionName = _parseString(directOption['name']).trim();
      final directValue = _parseString(optionValue['value']).trim();
      if (directOptionName.isNotEmpty && directValue.isNotEmpty) {
        addVariation(directOptionName, directValue);
        continue;
      }
      final optionValueUuid = _parseString(optionValue['uuid']).trim();
      if (optionValueUuid.isEmpty) continue;
      final mapped = optionValueByUuid[optionValueUuid];
      if (mapped == null) continue;
      addVariation(mapped.key, mapped.value);
    }
  }

  final variantTitle = _parseString(variant['title']);
  if (variantTitle.isNotEmpty) {
    addVariation('Variant', variantTitle);
  }

  if (includeSkuBarcode) {
    final variantSku = _parseString(variant['sku']);
    final variantBarcode = _parseString(variant['barcode']);
    if (variantSku.isNotEmpty) {
      addVariation('SKU', variantSku);
    }
    if (variantBarcode.isNotEmpty) {
      addVariation('Barcode', variantBarcode);
    }
  }

  final variantUuid = _parseString(variant['uuid']);
  if (variantUuid.isNotEmpty) {
    addVariation('variantUuid', variantUuid);
  }

  return list;
}

/// ===============================
/// 📦 ORDER MODEL (matched to your map)
/// ===============================
class OrderModel {
  // ids / meta
  final String id;
  final String worderId; // wcOrderId
  final String userId;

  // statuses
  final String wcOrderStatus;
  final String wcPaymentStatus;
  final String wcOrderKey;

  // payment
  final String paymentMethod;
  final String skipCashPaymentUrl;
  final String skipCashTransactionId;

  // customer quick fields (top-level)
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  // tracking / ui
  final int itemsCount;
  final String trackingUrl;
  final String statusDisplay;
  final String trackingStage;
  final String trackingStatus;
  final String waybillNo;

  // currency
  final String currencyCode;

  /// 💰 Money (DOUBLE + safe)
  final double subTotal; // netTotal (101.01)
  final double discount; // discount (90.91)
  final double shippingCost; // shippingCost (1.00)
  final double grandTotal; // grandTotal (11.10) payable
  final double total; // total (11.10) reference/fallback

  final String? couponCode;
  final String eta;

  // time
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  // flags
  final bool isPaid;
  final bool isDelivered;

  final List<OrderItemModel> items;
  final CustomerDataModel? customerData;

  OrderModel({
    required this.id,
    required this.worderId,
    required this.userId,
    required this.wcOrderStatus,
    required this.wcPaymentStatus,
    required this.wcOrderKey,
    required this.paymentMethod,
    required this.skipCashPaymentUrl,
    required this.skipCashTransactionId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.itemsCount,
    required this.trackingUrl,
    required this.statusDisplay,
    this.trackingStage = '',
    this.trackingStatus = '',
    this.waybillNo = '',
    required this.currencyCode,
    required this.subTotal,
    required this.discount,
    required this.shippingCost,
    required this.grandTotal,
    required this.total,
    required this.couponCode,
    required this.eta,
    required this.createdAt,
    required this.paidAt,
    required this.deliveredAt,
    required this.isPaid,
    required this.isDelivered,
    required this.items,
    this.customerData,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final isV1Order =
        json.containsKey('uuid') &&
        !json.containsKey('id') &&
        json.containsKey('orderItems');
    if (isV1Order) {
      final shippingAddressMap = _asMap(json['shippingAddress']);
      final orderItems = (json['orderItems'] as List? ?? const [])
          .whereType<Map>()
          .map((item) {
            final map = Map<String, dynamic>.from(item);
            final product =
                (map['product'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final price =
                (map['price'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final discountedPrice =
                (map['discountedPrice'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final total =
                (map['total'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final variant =
                (map['variant'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final variations = _buildVariantVariations(
              json: map,
              product: product,
              variant: variant,
            );
            final featuredThumbnailUrl = _parseString(
              product['featuredThumbnailUrl'],
            ).trim();
            final featuredImageUrl = _parseString(
              product['featuredImageUrl'],
            ).trim();
            final variantImage = _extractBestVariantImage(variant);
            final resolvedImage = variantImage.isNotEmpty
                ? variantImage
                : (featuredThumbnailUrl.isNotEmpty
                      ? featuredThumbnailUrl
                      : featuredImageUrl);
            return OrderItemModel(
              id: _parseString(map['uuid']),
              image: resolvedImage,
              price: _parseDouble(discountedPrice) > 0
                  ? _parseDouble(discountedPrice)
                  : (_parseDouble(price) > 0
                        ? _parseDouble(price)
                        : ((map['quantity'] as num?)?.toInt() ?? 1) > 0
                        ? _parseDouble(total) /
                              ((map['quantity'] as num?)?.toInt() ?? 1)
                        : 0),
              title: _parseProductTitle(product),
              userId: '',
              quantity: (map['quantity'] as num?)?.toInt() ?? 1,
              productId: _parseString(product['uuid']),
              productSlug: _parseString(product['slug']),
              categoryName: _extractCategoryNameFromProduct(product),
              variation: variations,
              couponCode: null,
              discountPercentage: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          })
          .toList();

      final subTotalAmount = _parseDouble(json['subTotal']);
      final shippingAmount = _parseDouble(json['shippingCost']);
      final discountAmount = _parseDouble(json['discount']);
      final totalAmount = _parseDouble(json['total']);
      final trackingMap = _asMap(json['tracking']);

      return OrderModel(
        id: _parseString(json['uuid']),
        worderId: _parseString(json['uuid']),
        userId: '',
        wcOrderStatus: _parseString(json['status']),
        wcPaymentStatus: _parseString(json['status']),
        wcOrderKey: '',
        paymentMethod: _parseString(json['paymentMethod']),
        skipCashPaymentUrl: '',
        skipCashTransactionId: '',
        customerName: '',
        customerEmail: '',
        customerPhone: _parseString(shippingAddressMap['phoneNumber']),
        itemsCount: orderItems.length,
        trackingUrl: '',
        statusDisplay: _parseString(json['status']),
        trackingStage: _parseString(trackingMap['stage']),
        trackingStatus: _parseString(trackingMap['status']),
        waybillNo: _parseString(trackingMap['waybillNo']),
        currencyCode: _parseString(
          (json['total'] as Map?)?['currencyCode'] ??
              (json['subTotal'] as Map?)?['currencyCode'],
        ),
        subTotal: subTotalAmount,
        discount: discountAmount,
        shippingCost: shippingAmount,
        grandTotal: totalAmount,
        total: totalAmount,
        couponCode: null,
        eta: _parseString(json['eta']),
        createdAt:
            _parseServerUtcToLocal(
              _parseString(json['orderPlacementDate']).isNotEmpty
                  ? _parseString(json['orderPlacementDate'])
                  : _parseString(json['orderplacement']).isNotEmpty
                  ? _parseString(json['orderplacement'])
                  : _parseString(json['orderPlacement']).isNotEmpty
                  ? _parseString(json['orderPlacement'])
                  : _parseString(json['createdAt']),
            ) ??
            DateTime.now(),
        paidAt: null,
        deliveredAt: null,
        isPaid: false,
        isDelivered: false,
        items: orderItems,
        customerData: shippingAddressMap.isEmpty
            ? null
            : CustomerDataModel.fromShippingAddress(shippingAddressMap),
      );
    }

    // ---- Money safe reads (based on your map keys) ----
    final double netTotal = _parseDouble(json['netTotal']);
    final double subTotalAlt = _parseDouble(json['subTotal']);
    final double totalRaw = _parseDouble(json['total']);
    final double grandTotalRaw = _parseDouble(json['grandTotal']);
    final double discountRaw = _parseDouble(json['discount']);
    final double shippingRaw = _parseDouble(json['shippingCost']);

    // ✅ subtotal = netTotal first, else subTotal, else total
    final double safeSubTotal = netTotal != 0.0
        ? netTotal
        : (subTotalAlt != 0.0 ? subTotalAlt : totalRaw);

    // ✅ grandTotal = grandTotal first, else total, else compute
    final double computedPayable = (safeSubTotal - discountRaw + shippingRaw);
    final double safeGrandTotal = grandTotalRaw != 0.0
        ? grandTotalRaw
        : (totalRaw != 0.0
              ? totalRaw
              : (computedPayable < 0 ? 0.0 : computedPayable));

    // ✅ total = total first, else grandTotal
    final double safeTotal = totalRaw != 0.0 ? totalRaw : safeGrandTotal;

    return OrderModel(
      id: _parseString(json['id']),
      worderId: _parseString(json['wcOrderId']),
      userId: _parseString(json['userId']),

      wcOrderStatus: _parseString(json['wcOrderStatus']),
      wcPaymentStatus: _parseString(json['wcPaymentStatus']),
      wcOrderKey: _parseString(json['wcOrderKey']),

      paymentMethod: _parseString(
        json['paymentMethod'] ?? json['payment_method'],
      ),
      skipCashPaymentUrl: _parseString(json['skipCashPaymentUrl']),
      skipCashTransactionId: _parseString(json['skipCashTransactionId']),

      customerName: _parseString(json['customerName']),
      customerEmail: _parseString(json['customerEmail']),
      customerPhone: _parseString(json['customerPhone']),

      itemsCount: (json['itemsCount'] is num)
          ? (json['itemsCount'] as num).toInt()
          : int.tryParse(_parseString(json['itemsCount'])) ?? 0,
      trackingUrl: _parseString(json['trackingUrl']),
      statusDisplay: _parseString(json['statusDisplay']),
      trackingStage: _parseString((json['tracking'] as Map?)?['stage']),
      trackingStatus: _parseString((json['tracking'] as Map?)?['status']),
      waybillNo: _parseString((json['tracking'] as Map?)?['waybillNo']),

      currencyCode: _parseString(json['currency']),

      // ✅ money (final)
      subTotal: safeSubTotal,
      discount: discountRaw,
      shippingCost: shippingRaw,
      grandTotal: safeGrandTotal,
      total: safeTotal,

      couponCode: json['couponCode']?.toString(),
      eta: _parseString(json['eta']),

      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),

      customerData: json['customer_data'] != null
          ? CustomerDataModel.fromJson(json['customer_data'])
          : null,

      createdAt: _parseServerUtcToLocal(json['createdAt']) ?? DateTime.now(),
      paidAt: _parseServerUtcToLocal(json['paidAt']),
      deliveredAt: _parseServerUtcToLocal(json['deliveredAt']),

      isPaid: json['isPaid'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
    );
  }
}

/// ===============================
/// 🧾 ORDER ITEM MODEL
/// ===============================
class OrderItemModel {
  final String id;
  final String image;
  final double price;
  final String title;
  final String userId;
  final int quantity;
  final String productId;
  final String productSlug;
  final String categoryName;
  final List<Variation> variation;

  final String? couponCode;
  final int discountPercentage;

  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItemModel({
    required this.id,
    required this.image,
    required this.price,
    required this.title,
    required this.userId,
    required this.quantity,
    required this.productId,
    this.productSlug = '',
    this.categoryName = '',
    required this.variation,
    required this.couponCode,
    required this.discountPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = _asMap(json['product']);
    final variant = _asMap(json['variant']);
    final priceMap = _asMap(json['price']);
    final discountedPriceMap = _asMap(json['discountedPrice']);
    final totalMap = _asMap(json['total']);
    final quantity = (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : int.tryParse(_parseString(json['quantity'])) ?? 0;
    final variations = _buildVariantVariations(
      json: json,
      product: product,
      variant: variant,
      includeSkuBarcode: true,
    );
    final discountedPrice = _parseDouble(discountedPriceMap);
    final price = _parseDouble(priceMap);
    final total = _parseDouble(totalMap);
    final variantImage = _extractBestVariantImage(variant).trim();
    final directImage = _parseString(json['image']).trim();
    final featuredThumbnailUrl = _parseString(
      product['featuredThumbnailUrl'],
    ).trim();
    final featuredImageUrl = _parseString(product['featuredImageUrl']).trim();
    final resolvedFallbackImage = directImage.isNotEmpty
        ? directImage
        : (featuredThumbnailUrl.isNotEmpty
              ? featuredThumbnailUrl
              : featuredImageUrl);

    return OrderItemModel(
      id: _parseString(json['id'] ?? json['uuid']),
      image: variantImage.isNotEmpty ? variantImage : resolvedFallbackImage,
      price: discountedPrice > 0
          ? discountedPrice
          : (price > 0 ? price : (quantity > 0 ? total / quantity : 0)),
      title: _firstNonEmpty([
        _resolveLocalizedTitle(json),
        _parseString(json['productTitle']),
        _resolveLocalizedTitle(product),
        _resolveLocalizedTitle(variant),
      ]),
      userId: _parseString(json['userId']),
      quantity: quantity,
      productId: _parseString(json['productId'] ?? product['uuid']),
      productSlug: _parseString(json['productSlug'] ?? product['slug']),
      categoryName: _parseString(
        json['categoryName'] ?? _extractCategoryNameFromProduct(product),
      ),
      variation: variations.isNotEmpty
          ? variations
          : (json['variation'] as List? ?? [])
                .map((v) => Variation.fromJson(v))
                .toList(),
      couponCode: json['couponCode']?.toString(),
      discountPercentage: (json['discountPercentage'] is num)
          ? (json['discountPercentage'] as num).toInt()
          : int.tryParse(_parseString(json['discountPercentage'])) ?? 0,
      createdAt: _parseServerUtcToLocal(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseServerUtcToLocal(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

/// ✅ Customer Data Model
class CustomerDataModel {
  final String city;
  final String email;
  final String phone;
  final String state;
  final String country;
  final String postcode;
  final String address1;
  final String address2;
  final String lastName;
  final String firstName;
  final ShippingOption? shippingOption;
  final ShippingAddress? shippingAddress;

  CustomerDataModel({
    required this.city,
    required this.email,
    required this.phone,
    required this.state,
    required this.country,
    required this.postcode,
    required this.address1,
    required this.address2,
    required this.lastName,
    required this.firstName,
    this.shippingOption,
    this.shippingAddress,
  });

  factory CustomerDataModel.fromJson(Map<String, dynamic> json) {
    return CustomerDataModel(
      city: _parseString(json['city']),
      email: _parseString(json['email']),
      phone: _parseString(json['phone']),
      state: _parseString(json['state']),
      country: _parseString(json['country']),
      postcode: _parseString(json['postcode']),
      address1: _parseString(json['address_1']),
      address2: _parseString(json['address_2']),
      lastName: _parseString(json['last_name']),
      firstName: _parseString(json['first_name']),
      shippingOption: json['shipping_option'] != null
          ? ShippingOption.fromJson(json['shipping_option'])
          : null,
      shippingAddress: json['shipping_address'] != null
          ? ShippingAddress.fromJson(json['shipping_address'])
          : null,
    );
  }

  factory CustomerDataModel.fromShippingAddress(Map<String, dynamic> json) {
    return CustomerDataModel(
      city: _parseString(json['city']),
      email: '',
      phone: _parseString(json['phoneNumber']),
      state: _parseString(json['state']),
      country: _parseString(json['country']),
      postcode: _parseString(json['zipCode']),
      address1: _parseString(json['streetAddress']),
      address2: _parseString(json['apartment']),
      lastName: _fullNameLast(_parseString(json['fullName'])),
      firstName: _fullNameFirst(_parseString(json['fullName'])),
      shippingOption: null,
      shippingAddress: ShippingAddress.fromJson(json),
    );
  }
}

/// ✅ Shipping Option Model
class ShippingOption {
  final double cost;
  final String title;
  final String methodId;

  ShippingOption({
    required this.cost,
    required this.title,
    required this.methodId,
  });

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    return ShippingOption(
      cost: _parseDouble(json['cost']),
      title: _parseString(json['title']),
      methodId: _parseString(json['method_id']),
    );
  }
}

/// ✅ Shipping Address Model
class ShippingAddress {
  final String fullName;
  final String phoneNumber;
  final String city;
  final String state;
  final String country;
  final String postcode;
  final String address1;
  final String address2;
  final String lastName;
  final String firstName;

  ShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.city,
    required this.state,
    required this.country,
    required this.postcode,
    required this.address1,
    required this.address2,
    required this.lastName,
    required this.firstName,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    final fullName = _parseString(json['fullName']);
    return ShippingAddress(
      fullName: fullName,
      phoneNumber: _parseString(json['phoneNumber']),
      city: _parseString(json['city']),
      state: _parseString(json['state']),
      country: _parseString(json['country']),
      postcode: _parseString(json['postcode'] ?? json['zipCode']),
      address1: _parseString(json['address_1'] ?? json['streetAddress']),
      address2: _parseString(json['address_2'] ?? json['apartment']),
      lastName: _parseString(json['last_name'] ?? _fullNameLast(fullName)),
      firstName: _parseString(json['first_name'] ?? _fullNameFirst(fullName)),
    );
  }
}

String _fullNameFirst(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? '' : parts.first;
}

String _fullNameLast(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length <= 1) return '';
  return parts.sublist(1).join(' ');
}
