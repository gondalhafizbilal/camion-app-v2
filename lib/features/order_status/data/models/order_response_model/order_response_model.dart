import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/money_utils.dart';

class OrderResponse {
  final int status;
  final String message;
  final OrderData data;

  OrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('data') && json.containsKey('uuid')) {
      return OrderResponse._fromV1OrderJson(json);
    }
    return OrderResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: OrderData.fromJson(json['data'] ?? {}),
    );
  }

  factory OrderResponse._fromV1OrderJson(Map<String, dynamic> json) {
    final orderUuid = json['uuid']?.toString() ?? '';
    final status = json['status']?.toString() ?? '';
    final total = parseMoneyValue(json['total']).toString();
    final currency = parseMoneyCurrencyCode(json['total']) ?? '';
    final paymentPayUrl = _extractPaymentPayUrl(json);
    final orderItems = (json['orderItems'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return OrderResponse(
      status: 200,
      message: '',
      data: OrderData(
        sessionId: '',
        orderId: orderUuid,
        paymentPayUrl: paymentPayUrl,
        order: Order(
          id: orderUuid,
          wcOrderId: 0,
          wcOrderKey: '',
          wcOrderStatus: status,
          wcPaymentStatus: status,
          currency: currency,
          total: total,
          eta: json['eta']?.toString() ?? '',
          userId: '',
          items: orderItems.map((item) {
            final product =
                (item['product'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final variant =
                (item['variant'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final price =
                (item['price'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final resolvedImage = _resolveOrderItemImage(
              product: product,
              variant: variant,
              item: item,
            );
            return OrderItem(
              id: item['uuid']?.toString() ?? '',
              userId: '',
              productId: product['uuid']?.toString() ?? '',
              productSlug: product['slug']?.toString() ?? '',
              categoryName: _extractCategoryNameFromProduct(product),
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
              variation: const [],
              title: _firstNonEmpty([
                _resolveLocalizedTitle(item),
                _parseProductTitle(product),
                _resolveLocalizedTitle(variant),
              ]),
              image: resolvedImage,
              price: parseMoneyValue(price).toString(),
              couponCode: null,
              discountPercentage: 0,
              createdAt: '',
              updatedAt: '',
            );
          }).toList(),
          customerData: CustomerData(
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            address1: '',
            address2: '',
            city: '',
            state: '',
            postcode: '',
            country: '',
            shippingAddress: ShippingAddress(
              firstName: '',
              lastName: '',
              address1: '',
              address2: '',
              city: '',
              state: '',
              postcode: '',
              country: '',
            ),
            shippingOption: ShippingOption(
              methodId: '',
              methodTitle: '',
              cost: '0',
            ),
          ),
          paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
          paymentData: const [],
          trackingUrl: '',
          isPaid: false,
          paidAt: null,
          isDelivered: false,
          deliveredAt: null,
          skipCashPaymentUrl: paymentPayUrl,
          createdAt: '',
          updatedAt: '',
        ),
      ),
    );
  }

  static String _extractPaymentPayUrl(Map<String, dynamic> json) {
    final paymentTransaction =
        (json['paymentTransaction'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final rawResponse =
        (paymentTransaction['rawResponse'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final resultObj =
        (rawResponse['resultObj'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final payUrl =
        resultObj['payUrl'] ??
        resultObj['payURL'] ??
        resultObj['url'] ??
        rawResponse['payUrl'] ??
        paymentTransaction['payUrl'] ??
        json['payUrl'];

    return payUrl?.toString().trim() ?? '';
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data.toJson()};
  }
}

String _parseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
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

String _parseProductTitle(Map<String, dynamic> product) {
  return _resolveLocalizedTitle(product);
}

String _resolveOrderItemImage({
  required Map<String, dynamic> product,
  required Map<String, dynamic> variant,
  required Map<String, dynamic> item,
}) {
  final variantImages = (variant['images'] as List? ?? const <dynamic>[])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
  for (final entry in variantImages) {
    final thumbnail = entry['thumbnailUrl']?.toString().trim() ?? '';
    if (thumbnail.isNotEmpty) return thumbnail;
    final imageUrl = entry['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) return imageUrl;
  }

  final directImage = variant['image']?.toString().trim() ?? '';
  if (directImage.isNotEmpty) return directImage;

  final itemImage = item['image']?.toString().trim() ?? '';
  if (itemImage.isNotEmpty) return itemImage;

  final featuredThumbnailUrl =
      product['featuredThumbnailUrl']?.toString().trim() ?? '';
  if (featuredThumbnailUrl.isNotEmpty) return featuredThumbnailUrl;

  final featuredImageUrl = product['featuredImageUrl']?.toString().trim() ?? '';
  if (featuredImageUrl.isNotEmpty) return featuredImageUrl;

  return '';
}

String _extractCategoryNameFromProduct(Map<String, dynamic> product) {
  final direct = product['categoryName']?.toString() ?? '';
  if (direct.trim().isNotEmpty) return direct;

  final category = product['category'];
  if (category is Map) {
    final categoryName =
        (category['name'] ?? category['title'] ?? category['label'])
            ?.toString() ??
        '';
    if (categoryName.trim().isNotEmpty) return categoryName;
  }

  final categories = product['categories'];
  if (categories is List && categories.isNotEmpty) {
    for (final entry in categories) {
      if (entry is Map) {
        final name =
            (entry['name'] ?? entry['title'] ?? entry['label'])?.toString() ??
            '';
        if (name.trim().isNotEmpty) return name;
      }
    }
  }

  return '';
}

class OrderData {
  final String sessionId;

  final String orderId;
  final String paymentPayUrl;
  final Order order;

  OrderData({
    required this.sessionId,

    required this.orderId,
    required this.paymentPayUrl,
    required this.order,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      sessionId: json['sessionId'] ?? '',

      orderId: json['orderId'] ?? '',
      paymentPayUrl: json['paymentPayUrl']?.toString() ?? '',
      order: Order.fromJson(json['order'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,

      'orderId': orderId,
      'paymentPayUrl': paymentPayUrl,
      'order': order.toJson(),
    };
  }
}

class Order {
  final String id;
  final int wcOrderId;
  final String wcOrderKey;
  final String wcOrderStatus;
  final String wcPaymentStatus;
  final String currency;
  final String total;
  final String eta;
  final String userId;
  final List<OrderItem> items;
  final CustomerData customerData;
  final String paymentMethod;
  final List<dynamic> paymentData;
  final String trackingUrl;
  final bool isPaid;
  final String? paidAt;
  final bool isDelivered;
  final String? deliveredAt;
  final String skipCashPaymentUrl;
  final String createdAt;
  final String updatedAt;

  Order({
    required this.id,
    required this.wcOrderId,
    required this.wcOrderKey,
    required this.wcOrderStatus,
    required this.wcPaymentStatus,
    required this.currency,
    required this.total,
    required this.eta,
    required this.userId,
    required this.items,
    required this.customerData,
    required this.paymentMethod,
    required this.paymentData,
    required this.trackingUrl,
    required this.isPaid,
    required this.paidAt,
    required this.isDelivered,
    required this.deliveredAt,

    required this.skipCashPaymentUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      wcOrderId: json['wcOrderId'] ?? 0,
      wcOrderKey: json['wcOrderKey']?.toString() ?? '',
      wcOrderStatus: json['wcOrderStatus']?.toString() ?? '',
      wcPaymentStatus: json['wcPaymentStatus']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      total: json['total']?.toString() ?? '', // ✅ تحويل لـ String
      eta: json['eta']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      customerData: CustomerData.fromJson(json['customerData'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentData: json['paymentData'] ?? [],
      trackingUrl: json['trackingUrl']?.toString() ?? '',
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'],
      isDelivered: json['isDelivered'] ?? false,
      deliveredAt: json['deliveredAt'],

      skipCashPaymentUrl: json['skipCashPaymentUrl'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wcOrderId': wcOrderId,
      'wcOrderKey': wcOrderKey,
      'wcOrderStatus': wcOrderStatus,
      'wcPaymentStatus': wcPaymentStatus,
      'currency': currency,
      'total': total,
      'eta': eta,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'customerData': customerData.toJson(),
      'paymentMethod': paymentMethod,
      'paymentData': paymentData,
      'trackingUrl': trackingUrl,
      'isPaid': isPaid,
      'paidAt': paidAt,
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt,

      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class OrderItem {
  final String id;
  final String userId;
  final String productId;
  final String productSlug;
  final String categoryName;
  final int quantity;
  final List<dynamic> variation;
  final String title;
  final String image;
  final String price;
  final String? couponCode;
  final int discountPercentage;
  final String createdAt;
  final String updatedAt;

  OrderItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.productSlug = '',
    this.categoryName = '',
    required this.quantity,
    required this.variation,
    required this.title,
    required this.image,
    required this.price,
    required this.couponCode,
    required this.discountPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};
    final variant = json['variant'] is Map
        ? Map<String, dynamic>.from(json['variant'] as Map)
        : const <String, dynamic>{};
    final variantImages = (variant['images'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final productVariants = (product['variants'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    String resolvedImage = _resolveOrderItemImage(
      product: product,
      variant: variant,
      item: json,
    );
    if (resolvedImage.isEmpty) {
      List<Map<String, dynamic>> candidateImages = variantImages;
      if (candidateImages.isEmpty) {
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
      for (final entry in candidateImages) {
        final thumbnail = entry['thumbnailUrl']?.toString().trim() ?? '';
        if (thumbnail.isNotEmpty) {
          resolvedImage = thumbnail;
          break;
        }
        final imageUrl = entry['imageUrl']?.toString().trim() ?? '';
        if (imageUrl.isNotEmpty) {
          resolvedImage = imageUrl;
          break;
        }
      }
    }

    return OrderItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '', // ✅ تحويل لـ String
      productSlug:
          json['productSlug']?.toString() ?? json['slug']?.toString() ?? '',
      categoryName:
          json['categoryName']?.toString() ??
          json['category']?.toString() ??
          '',
      quantity: json['quantity'] ?? 0,
      variation: json['variation'] ?? [],
      title: _firstNonEmpty([
        _resolveLocalizedTitle(json),
        _resolveLocalizedTitle(product),
        _resolveLocalizedTitle(variant),
      ]),
      image: resolvedImage,
      price: json['price']?.toString() ?? '', // ✅ تحويل لـ String
      couponCode: json['couponCode']?.toString(),
      discountPercentage: json['discountPercentage'] ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productSlug': productSlug,
      'categoryName': categoryName,
      'quantity': quantity,
      'variation': variation,
      'title': title,
      'image': image,
      'price': price,
      'couponCode': couponCode,
      'discountPercentage': discountPercentage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class CustomerData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final ShippingAddress shippingAddress;
  final ShippingOption shippingOption;

  CustomerData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.shippingAddress,
    required this.shippingOption,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      shippingAddress: ShippingAddress.fromJson(json['shipping_address'] ?? {}),
      shippingOption: ShippingOption.fromJson(json['shipping_option'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'shipping_address': shippingAddress.toJson(),
      'shipping_option': shippingOption.toJson(),
    };
  }
}

class ShippingAddress {
  final String firstName;
  final String lastName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  ShippingAddress({
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
    };
  }
}

class ShippingOption {
  final String methodId;
  final String methodTitle;
  final String cost;

  ShippingOption({
    required this.methodId,
    required this.methodTitle,
    required this.cost,
  });

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    return ShippingOption(
      methodId: json['method_id']?.toString() ?? '',
      methodTitle: json['method_title']?.toString() ?? '',
      cost: json['cost']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'method_id': methodId, 'method_title': methodTitle, 'cost': cost};
  }
}
