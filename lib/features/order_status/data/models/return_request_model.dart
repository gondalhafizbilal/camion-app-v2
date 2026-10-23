import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/features/order_status/data/models/order_model/order_model.dart';

double _toDouble(dynamic raw) {
  return parseMoneyValue(raw);
}

String _toStringValue(dynamic raw) => raw?.toString() ?? '';

Map<String, dynamic> _toMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

class ReturnRequestMoney {
  const ReturnRequestMoney({
    required this.amount,
    required this.minorAmount,
    required this.currencyCode,
  });

  final double amount;
  final double minorAmount;
  final String currencyCode;

  double get decimalAmount => amount + (minorAmount / 100);

  factory ReturnRequestMoney.fromJson(Map<String, dynamic> json) {
    return ReturnRequestMoney(
      amount: _toDouble(json['amount']),
      minorAmount: _toDouble(json['minorAmount']),
      currencyCode: _toStringValue(json['currencyCode']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'minorAmount': minorAmount,
      'currencyCode': currencyCode,
    };
  }
}

class ReturnRequestEvidence {
  const ReturnRequestEvidence({
    required this.uuid,
    required this.url,
    required this.mimeType,
    this.createdAt,
  });

  final String uuid;
  final String url;
  final String mimeType;
  final DateTime? createdAt;

  bool get isVideo => mimeType.toLowerCase().startsWith('video/');

  factory ReturnRequestEvidence.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = _toStringValue(json['createdAt']);
    return ReturnRequestEvidence(
      uuid: _toStringValue(json['uuid']),
      url: _toStringValue(json['url']),
      mimeType: _toStringValue(json['mimeType']),
      createdAt: createdAtRaw.trim().isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw),
    );
  }
}

class ReturnRequestProductCategory {
  const ReturnRequestProductCategory({
    required this.uuid,
    required this.slug,
    required this.name,
    required this.thumbnailUrl,
  });

  final String uuid;
  final String slug;
  final String name;
  final String thumbnailUrl;

  factory ReturnRequestProductCategory.fromJson(Map<String, dynamic> json) {
    return ReturnRequestProductCategory(
      uuid: _toStringValue(json['uuid']),
      slug: _toStringValue(json['slug']),
      name: _toStringValue(
        json['name'] ?? json['nameEn'] ?? json['nameAr'] ?? json['label'],
      ),
      thumbnailUrl: _toStringValue(json['thumbnailUrl']),
    );
  }
}

class ReturnRequestProduct {
  const ReturnRequestProduct({
    required this.uuid,
    required this.slug,
    required this.title,
    required this.featuredThumbnailUrl,
    required this.featuredImageUrl,
    required this.brief,
    required this.description,
    required this.descriptionHtml,
    required this.status,
    required this.categories,
  });

  final String uuid;
  final String slug;
  final String title;
  final String featuredThumbnailUrl;
  final String featuredImageUrl;
  final String brief;
  final String description;
  final String descriptionHtml;
  final String status;
  final List<ReturnRequestProductCategory> categories;

  String get primaryCategoryName {
    final category = categories.firstWhere(
      (entry) => entry.name.trim().isNotEmpty,
      orElse: () => const ReturnRequestProductCategory(
        uuid: '',
        slug: '',
        name: '',
        thumbnailUrl: '',
      ),
    );
    return category.name.trim();
  }

  factory ReturnRequestProduct.fromJson(Map<String, dynamic> json) {
    final categories = (json['productCategories'] as List<dynamic>? ?? const [])
        .map(_toMap)
        .map((entry) => _toMap(entry['category']))
        .where((entry) => entry.isNotEmpty)
        .map(ReturnRequestProductCategory.fromJson)
        .toList();
    return ReturnRequestProduct(
      uuid: _toStringValue(json['uuid']),
      slug: _toStringValue(json['slug']),
      title: _toStringValue(json['title']),
      featuredThumbnailUrl: _toStringValue(json['featuredThumbnailUrl']),
      featuredImageUrl: _toStringValue(json['featuredImageUrl']),
      brief: _toStringValue(json['brief']),
      description: _toStringValue(json['description']),
      descriptionHtml: _toStringValue(json['descriptionHtml']),
      status: _toStringValue(json['status']),
      categories: categories,
    );
  }
}

class ReturnRequestVariantImage {
  const ReturnRequestVariantImage({
    required this.uuid,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.alt,
    required this.isFeatured,
    required this.position,
  });

  final String uuid;
  final String imageUrl;
  final String thumbnailUrl;
  final String alt;
  final bool isFeatured;
  final int position;

  String get bestUrl {
    final thumb = thumbnailUrl.trim();
    if (thumb.isNotEmpty) return thumb;
    return imageUrl.trim();
  }

  factory ReturnRequestVariantImage.fromJson(Map<String, dynamic> json) {
    return ReturnRequestVariantImage(
      uuid: _toStringValue(json['uuid']),
      imageUrl: _toStringValue(json['imageUrl']),
      thumbnailUrl: _toStringValue(json['thumbnailUrl']),
      alt: _toStringValue(json['alt']),
      isFeatured: json['isFeatured'] == true,
      position: json['position'] is int
          ? json['position'] as int
          : int.tryParse(_toStringValue(json['position'])) ?? 0,
    );
  }
}

class ReturnRequestVariant {
  const ReturnRequestVariant({
    required this.uuid,
    required this.title,
    required this.sku,
    required this.barcode,
    this.price,
    this.discountedPrice,
    required this.images,
  });

  final String uuid;
  final String title;
  final String sku;
  final String barcode;
  final ReturnRequestMoney? price;
  final ReturnRequestMoney? discountedPrice;
  final List<ReturnRequestVariantImage> images;

  String get bestImageUrl {
    final featured =
        images
            .where((image) => image.isFeatured && image.bestUrl.isNotEmpty)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    if (featured.isNotEmpty) {
      return featured.first.bestUrl;
    }
    final sorted = images.where((image) => image.bestUrl.isNotEmpty).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.isEmpty ? '' : sorted.first.bestUrl;
  }

  factory ReturnRequestVariant.fromJson(Map<String, dynamic> json) {
    return ReturnRequestVariant(
      uuid: _toStringValue(json['uuid']),
      title: _toStringValue(json['title']),
      sku: _toStringValue(json['sku']),
      barcode: _toStringValue(json['barcode']),
      price: _toMap(json['price']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['price'])),
      discountedPrice: _toMap(json['discountedPrice']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['discountedPrice'])),
      images: (json['images'] as List<dynamic>? ?? const [])
          .map(_toMap)
          .where((entry) => entry.isNotEmpty)
          .map(ReturnRequestVariantImage.fromJson)
          .toList(),
    );
  }
}

class ReturnRequestOrderSummary {
  const ReturnRequestOrderSummary({
    required this.uuid,
    required this.status,
    this.subTotal,
    this.shippingCost,
    this.discount,
    this.total,
  });

  final String uuid;
  final String status;
  final ReturnRequestMoney? subTotal;
  final ReturnRequestMoney? shippingCost;
  final ReturnRequestMoney? discount;
  final ReturnRequestMoney? total;

  factory ReturnRequestOrderSummary.fromJson(Map<String, dynamic> json) {
    return ReturnRequestOrderSummary(
      uuid: _toStringValue(json['uuid']),
      status: _toStringValue(json['status']),
      subTotal: _toMap(json['subTotal']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['subTotal'])),
      shippingCost: _toMap(json['shippingCost']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['shippingCost'])),
      discount: _toMap(json['discount']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['discount'])),
      total: _toMap(json['total']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['total'])),
    );
  }
}

class ReturnRequestOrderItem {
  const ReturnRequestOrderItem({
    required this.uuid,
    this.price,
    this.discountedPrice,
    required this.quantity,
    this.total,
    this.product,
    this.variant,
  });

  final String uuid;
  final ReturnRequestMoney? price;
  final ReturnRequestMoney? discountedPrice;
  final int quantity;
  final ReturnRequestMoney? total;
  final ReturnRequestProduct? product;
  final ReturnRequestVariant? variant;

  String get displayTitle {
    final productTitle = product?.title.trim() ?? '';
    if (productTitle.isNotEmpty) return productTitle;
    return variant?.title.trim() ?? 'Returned item';
  }

  String get displayImageUrl {
    final featuredThumbnailUrl = product?.featuredThumbnailUrl.trim() ?? '';
    if (featuredThumbnailUrl.isNotEmpty) return featuredThumbnailUrl;
    final featuredImageUrl = product?.featuredImageUrl.trim() ?? '';
    if (featuredImageUrl.isNotEmpty) return featuredImageUrl;
    return variant?.bestImageUrl ?? '';
  }

  OrderItemModel toOrderItemModel() {
    final priceAmount =
        discountedPrice?.decimalAmount ?? price?.decimalAmount ?? 0;
    final totalAmount = total?.decimalAmount ?? 0;
    return OrderItemModel(
      id: uuid,
      image: displayImageUrl,
      price: priceAmount > 0
          ? priceAmount
          : (quantity > 0 ? totalAmount / quantity : 0),
      title: displayTitle,
      userId: '',
      quantity: quantity,
      productId: product?.uuid ?? '',
      productSlug: product?.slug ?? '',
      categoryName: product?.primaryCategoryName ?? '',
      variation: const [],
      couponCode: null,
      discountPercentage: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory ReturnRequestOrderItem.fromJson(Map<String, dynamic> json) {
    return ReturnRequestOrderItem(
      uuid: _toStringValue(json['uuid']),
      price: _toMap(json['price']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['price'])),
      discountedPrice: _toMap(json['discountedPrice']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['discountedPrice'])),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(_toStringValue(json['quantity'])) ?? 0,
      total: _toMap(json['total']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['total'])),
      product: _toMap(json['product']).isEmpty
          ? null
          : ReturnRequestProduct.fromJson(_toMap(json['product'])),
      variant: _toMap(json['variant']).isEmpty
          ? null
          : ReturnRequestVariant.fromJson(_toMap(json['variant'])),
    );
  }
}

class ReturnRequestModel {
  const ReturnRequestModel({
    required this.uuid,
    this.order,
    this.orderItem,
    required this.reason,
    required this.reasonDetail,
    required this.status,
    required this.adminNote,
    this.refundAmount,
    required this.evidence,
    this.createdAt,
    this.updatedAt,
  });

  final String uuid;
  final ReturnRequestOrderSummary? order;
  final ReturnRequestOrderItem? orderItem;
  final String reason;
  final String reasonDetail;
  final String status;
  final String? adminNote;
  final ReturnRequestMoney? refundAmount;
  final List<ReturnRequestEvidence> evidence;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasEvidence => evidence.isNotEmpty;
  bool get isPending => status.trim().toLowerCase() == 'pending';
  bool get isApproved => status.trim().toLowerCase() == 'approved';
  bool get isRejected => status.trim().toLowerCase() == 'rejected';
  bool get isRefunded => status.trim().toLowerCase() == 'refunded';

  String get subjectTitle {
    final itemTitle = orderItem?.displayTitle.trim() ?? '';
    if (itemTitle.isNotEmpty) return itemTitle;
    return 'Order return';
  }

  factory ReturnRequestModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = _toStringValue(json['createdAt']);
    final updatedAtRaw = _toStringValue(json['updatedAt']);
    return ReturnRequestModel(
      uuid: _toStringValue(json['uuid']),
      order: _toMap(json['order']).isEmpty
          ? null
          : ReturnRequestOrderSummary.fromJson(_toMap(json['order'])),
      orderItem: _toMap(json['orderItem']).isEmpty
          ? null
          : ReturnRequestOrderItem.fromJson(_toMap(json['orderItem'])),
      reason: _toStringValue(json['reason']),
      reasonDetail: _toStringValue(json['reasonDetail']),
      status: _toStringValue(json['status']),
      adminNote: json['adminNote']?.toString(),
      refundAmount: _toMap(json['refundAmount']).isEmpty
          ? null
          : ReturnRequestMoney.fromJson(_toMap(json['refundAmount'])),
      evidence: (json['evidence'] as List<dynamic>? ?? const [])
          .map(_toMap)
          .where((entry) => entry.isNotEmpty)
          .map(ReturnRequestEvidence.fromJson)
          .toList(),
      createdAt: createdAtRaw.trim().isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw),
      updatedAt: updatedAtRaw.trim().isEmpty
          ? null
          : DateTime.tryParse(updatedAtRaw),
    );
  }
}
