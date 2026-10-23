import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/image_url_transformer.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/variation.dart';

String _readImageUrl(dynamic value) {
  if (value is String) return value.trim();
  if (value is Map) {
    final map = _asMap(value);
    return _firstNonEmpty([
      _readString(map['thumbnailUrl']),
      _readString(map['imageUrl']),
    ]);
  }
  if (value is List) {
    for (final entry in value) {
      final resolved = _readImageUrl(entry);
      if (resolved.isNotEmpty) return resolved;
    }
  }
  return '';
}

String _currentLanguageCode() {
  final saved = sl<CacheHelper>().getDataString(key: 'languageCode');
  final normalized = saved?.trim().toLowerCase() ?? '';
  if (normalized.isNotEmpty) {
    return normalized;
  }
  return AppDefaults.defaultLanguageCode.toLowerCase();
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
  for (final key in preferredKeys) {
    final value = _readString(data[key]).trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _resolveItemImage({
  required Map<String, dynamic> product,
  required Map<String, dynamic> variant,
  required Map<String, dynamic> item,
}) {
  final variantImages = _asList(variant['images']).map(_asMap).toList();
  for (final image in variantImages) {
    final thumbnail = _readString(image['thumbnailUrl']).trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    final imageUrl = _readString(image['imageUrl']).trim();
    if (imageUrl.isNotEmpty) return imageUrl;
  }

  final directVariantImage = _readImageUrl(variant['image']);
  if (directVariantImage.isNotEmpty) return directVariantImage;

  final itemImage = _readImageUrl(item['image']);
  if (itemImage.isNotEmpty) return itemImage;

  final featuredThumbnail = _readString(product['featuredThumbnailUrl']).trim();
  if (featuredThumbnail.isNotEmpty) return featuredThumbnail;

  final featuredImage = _readString(product['featuredImageUrl']).trim();
  if (featuredImage.isNotEmpty) return featuredImage;

  return '';
}

class OrderPreviewModel {
  const OrderPreviewModel({
    required this.items,
    required this.summary,
    required this.coupon,
    required this.shippingMethods,
    required this.shippingAddress,
    required this.eta,
  });

  final List<OrderPreviewItem> items;
  final OrderPreviewSummary summary;
  final OrderPreviewCoupon? coupon;
  final List<OrderPreviewShippingMethod> shippingMethods;
  final OrderPreviewShippingAddress? shippingAddress;
  final String eta;

  factory OrderPreviewModel.fromJson(dynamic json) {
    final root = _asMap(json);
    final data = _asMap(root['data']);
    final v2Payload = _asMap(data['getCurrentCustomerOrderPreviewV2']);
    final v1Payload = _asMap(data['getCurrentCustomerOrderPreview']);
    final payload = v2Payload.isNotEmpty
        ? v2Payload
        : (v1Payload.isNotEmpty ? v1Payload : (data.isNotEmpty ? data : root));

    final summaryMap = _asMap(payload['summary']);
    final orderMap = _asMap(payload['order']);
    final orderItems = _asList(orderMap['items']);
    final cartItems = _asList(payload['cartItems']);
    final cart = _asList(payload['cart']);
    final previewItems = _asList(payload['items']);
    final rawItems = cartItems.isNotEmpty
        ? cartItems
        : (cart.isNotEmpty
              ? cart
              : (previewItems.isNotEmpty ? previewItems : orderItems));

    final items = rawItems
        .map((item) => OrderPreviewItem.fromJson(item))
        .where(
          (item) => item.title.trim().isNotEmpty || item.id.trim().isNotEmpty,
        )
        .toList();

    final shippingMap = _asMap(payload['shipping']);
    final firstCartItem = rawItems.isNotEmpty
        ? _asMap(rawItems.first)
        : const {};
    final firstCartVariant = _asMap(firstCartItem['variant']);
    final firstCartVariantPrice = _asMap(firstCartVariant['price']);

    final fallbackCurrency = _firstNonEmpty([
      _readString(summaryMap['currencyCode']),
      _readString(payload['currencyCode']),
      _readString(orderMap['currency']),
      _readString(shippingMap['currency']),
      _readString(firstCartVariantPrice['currencyCode']),
      _readString(firstCartVariantPrice['currency']),
    ]);

    final fallbackSubTotal = summaryMap.containsKey('subTotal')
        ? _readNum(summaryMap['subTotal'])
        : _readNum(payload['cart_total']);

    final fallbackShipping = summaryMap.containsKey('shippingCost')
        ? _readNum(summaryMap['shippingCost'])
        : (payload.containsKey('shippingTotal')
              ? _readNum(payload['shippingTotal'])
              : _readNum(shippingMap['totalShippingCost']));

    final fallbackDiscount = summaryMap.containsKey('discount')
        ? _readNum(summaryMap['discount'])
        : (payload.containsKey('discountTotal')
              ? _readNum(payload['discountTotal'])
              : _readNum(payload['discount']));

    final fallbackGrandTotal = summaryMap.containsKey('grandTotal')
        ? _readNum(summaryMap['grandTotal'])
        : (payload.containsKey('grand_total')
              ? _readNum(payload['grand_total'])
              : _readNum(orderMap['total']));

    final summary = OrderPreviewSummary(
      subTotal: fallbackSubTotal,
      discount: fallbackDiscount,
      shippingCost: fallbackShipping,
      grandTotal: fallbackGrandTotal,
      currencyCode: fallbackCurrency,
    );

    final couponMap = _asMap(payload['coupon']);
    final coupon = couponMap.isEmpty
        ? null
        : OrderPreviewCoupon.fromJson(couponMap);
    final shippingAddressMap = _asMap(payload['shippingAddress']);
    final shippingAddress = shippingAddressMap.isEmpty
        ? null
        : OrderPreviewShippingAddress.fromJson(shippingAddressMap);

    final shippingMethods = _asList(
      payload['shippingMethods'],
    ).map((method) => OrderPreviewShippingMethod.fromJson(method)).toList();

    return OrderPreviewModel(
      items: items,
      summary: summary,
      coupon: coupon,
      shippingMethods: shippingMethods,
      shippingAddress: shippingAddress,
      eta: _readString(payload['eta']),
    );
  }
}

class OrderPreviewItem {
  const OrderPreviewItem({
    required this.id,
    required this.title,
    required this.image,
    required this.quantity,
    required this.price,
    required this.total,
    required this.variations,
  });

  final String id;
  final String title;
  final String image;
  final int quantity;
  final double price;
  final double total;
  final List<Variation> variations;

  factory OrderPreviewItem.fromJson(dynamic json) {
    final map = _asMap(json);
    final product = _asMap(map['product']);
    final variant = _asMap(map['variant']);
    final variantPrice = _asMap(variant['price']);
    final qty = _readInt(map['quantity'], fallback: 1);
    final rawPrice = _readNum(map['price']);
    final rawDiscountedPrice = _readNum(map['discountedPrice']);
    final variantDiscountedPrice = _readNum(variant['discountedPrice']);

    final title = _firstNonEmpty([
      _resolveLocalizedTitle(map),
      _readString(map['productTitle']),
      _resolveLocalizedTitle(product),
      _resolveLocalizedTitle(variant),
    ]);

    final rawImage = _resolveItemImage(
      product: product,
      variant: variant,
      item: map,
    );
    final transformedImage = ImageUrlTransformer.getTransformedImageUrl(
      rawImage,
      AppConfig.instance.assetsHost,
    );
    final image = transformedImage.isNotEmpty ? transformedImage : rawImage;

    final lineTotal = map.containsKey('total')
        ? _readNum(map['total'])
        : (map.containsKey('subTotal') ? _readNum(map['subTotal']) : 0.0);

    final price = rawDiscountedPrice > 0
        ? rawDiscountedPrice
        : rawPrice > 0
        ? rawPrice
        : variantDiscountedPrice > 0
        ? variantDiscountedPrice
        : (_readNum(variantPrice) > 0
              ? _readNum(variantPrice)
              : (qty > 0 && lineTotal > 0 ? lineTotal / qty : 0.0));

    return OrderPreviewItem(
      id: _firstNonEmpty([
        _readString(map['uuid']),
        _readString(map['id']),
        _readString(map['cartItemUuid']),
      ]),
      title: title,
      image: image,
      quantity: qty,
      price: price,
      total: lineTotal,
      variations: _resolvePreviewVariations(product: product, variant: variant),
    );
  }
}

List<Variation> _resolvePreviewVariations({
  required Map<String, dynamic> product,
  required Map<String, dynamic> variant,
}) {
  final resolved = <Variation>[];
  final seen = <String>{};

  String normalizeKey(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

  void addVariation(String attribute, String value) {
    final attr = attribute.trim();
    final val = value.trim();
    if (attr.isEmpty || val.isEmpty) return;
    final dedupe = '${normalizeKey(attr)}|${val.toLowerCase()}';
    if (!seen.add(dedupe)) return;
    resolved.add(Variation(attribute: attr, value: val));
  }

  final optionValueMap = <String, ({String key, String value})>{};
  final options = _asList(product['options']).map(_asMap).toList();
  for (final option in options) {
    final optionName = _readString(option['name']);
    if (optionName.isEmpty) continue;
    final values = _asList(option['values']).map(_asMap).toList();
    for (final value in values) {
      final valueUuid = _readString(value['uuid']);
      final valueText = _readString(value['value']);
      if (valueUuid.isEmpty || valueText.isEmpty) continue;
      optionValueMap[valueUuid] = (key: optionName, value: valueText);
    }
  }

  final optionValueRefs = _asList(variant['optionValues']).map(_asMap).toList();
  for (final ref in optionValueRefs) {
    final optionValue = _asMap(ref['optionValue']);
    final directOption = _asMap(optionValue['option']);
    final directOptionName = _readString(directOption['name']).trim();
    final directValue = _readString(optionValue['value']).trim();
    if (directOptionName.isNotEmpty && directValue.isNotEmpty) {
      addVariation(directOptionName, directValue);
      continue;
    }
    final optionValueUuid = _readString(optionValue['uuid']);
    if (optionValueUuid.isEmpty) continue;
    final mapped = optionValueMap[optionValueUuid];
    if (mapped == null) continue;
    addVariation(mapped.key, mapped.value);
  }

  final variantTitle = _readString(variant['title']);
  if (variantTitle.isNotEmpty) {
    addVariation('Variant', variantTitle);
  }
  final variantUuid = _readString(variant['uuid']);
  if (variantUuid.isNotEmpty) {
    addVariation('variantUuid', variantUuid);
  }

  return resolved;
}

class OrderPreviewShippingAddress {
  const OrderPreviewShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.apartment,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.country,
  });

  final String fullName;
  final String phoneNumber;
  final String streetAddress;
  final String apartment;
  final String zipCode;
  final String city;
  final String state;
  final String country;

  factory OrderPreviewShippingAddress.fromJson(dynamic json) {
    final map = _asMap(json);
    return OrderPreviewShippingAddress(
      fullName: _readString(map['fullName']),
      phoneNumber: _readString(map['phoneNumber']),
      streetAddress: _readString(map['streetAddress']),
      apartment: _readString(map['apartment']),
      zipCode: _readString(map['zipCode']),
      city: _readString(map['city']),
      state: _readString(map['state']),
      country: _readString(map['country']),
    );
  }
}

class OrderPreviewSummary {
  const OrderPreviewSummary({
    required this.subTotal,
    required this.discount,
    required this.shippingCost,
    required this.grandTotal,
    required this.currencyCode,
  });

  final double subTotal;
  final double discount;
  final double shippingCost;
  final double grandTotal;
  final String currencyCode;
}

class OrderPreviewCoupon {
  const OrderPreviewCoupon({
    required this.code,
    required this.discountPercentage,
  });

  final String code;
  final double discountPercentage;

  factory OrderPreviewCoupon.fromJson(dynamic json) {
    final map = _asMap(json);
    return OrderPreviewCoupon(
      code: _readString(map['code']),
      discountPercentage: _readNum(map['discountPercentage']),
    );
  }
}

class OrderPreviewShippingMethod {
  const OrderPreviewShippingMethod({
    required this.methodId,
    required this.title,
    required this.cost,
  });

  final String methodId;
  final String title;
  final double cost;

  factory OrderPreviewShippingMethod.fromJson(dynamic json) {
    final map = _asMap(json);
    return OrderPreviewShippingMethod(
      methodId: _readString(map['method_id']),
      title: _readString(map['title']),
      cost: _readNum(map['cost']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

String _readString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

double _readNum(dynamic value) {
  return parseMoneyValue(value);
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
