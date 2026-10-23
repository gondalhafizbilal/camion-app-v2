import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/core/utils/server_date_time_parser.dart';

// class GetCouponsModel {
//   final String id;
//   final String code;
//   final bool isActive;
//   final Affiliate affiliate;
//   final double discountPercentage;
//   final DateTime createdAt;
//
//   GetCouponsModel({
//     required this.id,
//     required this.code,
//     required this.isActive,
//     required this.affiliate,
//     required this.discountPercentage,
//     required this.createdAt,
//   });
//
//   factory GetCouponsModel.fromJson(Map<String, dynamic> json) {
//     return GetCouponsModel(
//       id: json['id'],
//       code: json['code'],
//       isActive: json['isActive'],
//       affiliate: Affiliate.fromJson(json['affiliate']),
//       discountPercentage: (json['discountPercentage'] as num).toDouble(),
//       createdAt: DateTime.parse(json['createdAt']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'code': code,
//       'isActive': isActive,
//       'affiliate': affiliate.toJson(),
//       'discountPercentage': discountPercentage,
//       'createdAt': createdAt.toIso8601String(),
//     };
//   }
// }
//
// class Affiliate {
//   final String id;
//   final String userId;
//   final String fullName;
//   final String gender;
//   final String nationality;
//   final String status;
//   final double totalEarnings;
//   final int couponsCreated;
//   final String bio;
//   final String? referralLink;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//
//   Affiliate({
//     required this.id,
//     required this.userId,
//     required this.fullName,
//     required this.gender,
//     required this.nationality,
//     required this.status,
//     required this.totalEarnings,
//     required this.couponsCreated,
//     required this.bio,
//     this.referralLink,
//     required this.createdAt,
//     required this.updatedAt,
//   });
//
//   factory Affiliate.fromJson(Map<String, dynamic> json) {
//     return Affiliate(
//       id: json['id'],
//       userId: json['userId'],
//       fullName: json['fullName'],
//       gender: json['gender'],
//       nationality: json['nationality'],
//       status: json['status'],
//       totalEarnings: (json['totalEarnings'] as num).toDouble(),
//       couponsCreated: json['couponsCreated'],
//       bio: json['bio'],
//       referralLink: json['referralLink'],
//       createdAt: DateTime.parse(json['createdAt']),
//       updatedAt: DateTime.parse(json['updatedAt']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'userId': userId,
//       'fullName': fullName,
//       'gender': gender,
//       'nationality': nationality,
//       'status': status,
//       'totalEarnings': totalEarnings,
//       'couponsCreated': couponsCreated,
//       'bio': bio,
//       'referralLink': referralLink,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }
// }
class GetCouponsModel {
  final String id;
  final String code;
  final bool isActive;

  final Affiliate affiliate;

  final double discountPercentage;
  final double commissionPercentage;
  final double totalSalesAmount;
  final String? totalSalesCurrencyCode;
  final double totalCommissionAmount;
  final String? totalCommissionCurrencyCode;

  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int ordersCount;

  final List<CouponOrder> orders;

  GetCouponsModel({
    required this.id,
    required this.code,
    required this.isActive,
    required this.affiliate,
    required this.discountPercentage,
    required this.commissionPercentage,
    required this.totalSalesAmount,
    required this.totalSalesCurrencyCode,
    required this.totalCommissionAmount,
    required this.totalCommissionCurrencyCode,
    required this.createdAt,
    required this.expiresAt,
    required this.ordersCount,
    required this.orders,
  });

  factory GetCouponsModel.fromJson(Map<String, dynamic> json) {
    final affiliateRaw = json['affiliate'];
    final affiliateMap = affiliateRaw is Map<String, dynamic>
        ? affiliateRaw
        : const <String, dynamic>{};
    return GetCouponsModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      isActive: _isCouponActive(json),
      affiliate: Affiliate.fromJson(affiliateMap),
      discountPercentage: _parseDouble(json['discountPercentage']),
      commissionPercentage: (json['commissionPercentage'] as num? ?? 0)
          .toDouble(),
      totalSalesAmount: _moneyAmount(json['totalSales']) ?? 0,
      totalSalesCurrencyCode: _moneyCurrencyCode(json['totalSales']),
      totalCommissionAmount: _moneyAmount(json['totalCommission']) ?? 0,
      totalCommissionCurrencyCode: _moneyCurrencyCode(json['totalCommission']),
      createdAt: _parseDate(json['createdAt']),
      expiresAt: _parseDate(json['expiresAt']),
      ordersCount: (json['ordersCount'] as num? ?? 0).toInt(),
      orders: ((json['orders'] as List?) ?? [])
          .map((e) => CouponOrder.fromJson((e ?? {}) as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "code": code,
      "isActive": isActive,
      "affiliate": affiliate.toJson(),
      "discountPercentage": discountPercentage,
      "commissionPercentage": commissionPercentage,
      "totalSales": {
        "amount": totalSalesAmount,
        "currencyCode": totalSalesCurrencyCode,
      },
      "totalCommission": {
        "amount": totalCommissionAmount,
        "currencyCode": totalCommissionCurrencyCode,
      },
      "createdAt": createdAt?.toIso8601String(),
      "expiresAt": expiresAt?.toIso8601String(),
      "ordersCount": ordersCount,
      "orders": orders.map((e) => e.toJson()).toList(),
    };
  }

  static bool _isCouponActive(Map<String, dynamic> json) {
    if (json['isActive'] is bool) {
      return json['isActive'] as bool;
    }
    final expiresAt = _parseDate(json['expiresAt']);
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    return !expiryDate.isBefore(today);
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    return ServerDateTimeParser.parseToLocal(value);
  }

  static double? _moneyAmount(dynamic value) {
    if (value == null) return null;
    return parseMoneyValue(value);
  }

  static String? _moneyCurrencyCode(dynamic value) {
    return parseMoneyCurrencyCode(value);
  }
}

class Affiliate {
  final String id;
  final String userId;
  final String fullName;
  final String gender;
  final String nationality;
  final String status;
  final String? type;

  final double totalEarnings;
  final int couponsCreated;
  final String bio;

  final String? referralLink;
  final double? walletBalance;

  final DateTime createdAt;
  final DateTime updatedAt;

  Affiliate({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.gender,
    required this.nationality,
    required this.status,
    this.type,
    required this.totalEarnings,
    required this.couponsCreated,
    required this.bio,
    this.referralLink,
    this.walletBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Affiliate.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'];
    final walletMap = wallet is Map<String, dynamic>
        ? wallet
        : const <String, dynamic>{};
    return Affiliate(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      userId: (json['userId'] ?? json['customerId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      nationality: (json['nationality'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      type: json['type']?.toString(),
      totalEarnings:
          _moneyAmount(json['totalCommission']) ??
          (json['totalEarnings'] as num? ?? 0).toDouble(),
      couponsCreated: (json['couponsCreated'] as num? ?? 0).toInt(),
      bio: (json['bio'] ?? '').toString(),
      referralLink: json['referralLink']?.toString(),
      walletBalance:
          (json['walletBalance'] as num?)?.toDouble() ??
          _moneyAmount(walletMap['amount']),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "fullName": fullName,
      "gender": gender,
      "nationality": nationality,
      "status": status,
      "type": type,
      "totalEarnings": totalEarnings,
      "couponsCreated": couponsCreated,
      "bio": bio,
      "referralLink": referralLink,
      "walletBalance": walletBalance,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  static double? _moneyAmount(dynamic value) {
    if (value is Map<String, dynamic>) {
      return (value['amount'] as num?)?.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}

class CouponOrder {
  final String orderId;
  final String wcOrderId;
  final String userId;

  final String buyerName;
  final String buyerEmail;

  final List<CouponProduct> products;

  final double commission;
  final double total;

  final DateTime createdAt;

  CouponOrder({
    required this.orderId,
    required this.wcOrderId,
    required this.userId,
    required this.buyerName,
    required this.buyerEmail,
    required this.products,
    required this.commission,
    required this.total,
    required this.createdAt,
  });

  factory CouponOrder.fromJson(Map<String, dynamic> json) {
    return CouponOrder(
      orderId: (json['orderId'] ?? '').toString(),
      wcOrderId: (json['wcOrderId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      buyerName: (json['buyerName'] ?? '').toString(),
      buyerEmail: (json['buyerEmail'] ?? '').toString(),
      products: ((json['products'] as List?) ?? [])
          .map((e) => CouponProduct.fromJson((e ?? {}) as Map<String, dynamic>))
          .toList(),
      commission: parseMoneyValue(json['commission']),
      total: parseMoneyValue(json['total']),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "orderId": orderId,
      "wcOrderId": wcOrderId,
      "userId": userId,
      "buyerName": buyerName,
      "buyerEmail": buyerEmail,
      "products": products.map((e) => e.toJson()).toList(),
      "commission": commission,
      "total": total,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}

class CouponOrderStat {
  final String uuid;
  final double totalAmount;
  final String? totalCurrencyCode;
  final double commissionAmount;
  final String? commissionCurrencyCode;
  final String status;
  final DateTime createdAt;

  CouponOrderStat({
    required this.uuid,
    required this.totalAmount,
    required this.totalCurrencyCode,
    required this.commissionAmount,
    required this.commissionCurrencyCode,
    required this.status,
    required this.createdAt,
  });

  factory CouponOrderStat.fromJson(Map<String, dynamic> json) {
    final totalMap = (json['total'] is Map<String, dynamic>)
        ? json['total'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final commissionMap = (json['commission'] is Map<String, dynamic>)
        ? json['commission'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return CouponOrderStat(
      uuid: (json['uuid'] ?? '').toString(),
      totalAmount: parseMoneyValue(totalMap),
      totalCurrencyCode: parseMoneyCurrencyCode(totalMap),
      commissionAmount: parseMoneyValue(commissionMap),
      commissionCurrencyCode: parseMoneyCurrencyCode(commissionMap),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class CouponProduct {
  final String id;
  final String? image;

  /// API sends string sometimes: "15.33"
  final double price;

  final String title;
  final String userId;
  final String? guestId;

  final int quantity;
  final String productId;

  final DateTime createdAt;
  final DateTime updatedAt;

  final List<ProductVariation> variation;

  final String? couponCode;
  final double? discountPercentage;

  CouponProduct({
    required this.id,
    required this.image,
    required this.price,
    required this.title,
    required this.userId,
    required this.guestId,
    required this.quantity,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    required this.variation,
    required this.couponCode,
    required this.discountPercentage,
  });

  factory CouponProduct.fromJson(Map<String, dynamic> json) {
    return CouponProduct(
      id: (json['id'] ?? '').toString(),
      image: json['image']?.toString(),
      price: _parseDouble(json['price']),
      title: (json['title'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      guestId: json['guestId']?.toString(),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      productId: (json['productId'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      variation: ((json['variation'] as List?) ?? [])
          .map(
            (e) => ProductVariation.fromJson((e ?? {}) as Map<String, dynamic>),
          )
          .toList(),
      couponCode: json['couponCode']?.toString(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "image": image,
      "price": price,
      "title": title,
      "userId": userId,
      "guestId": guestId,
      "quantity": quantity,
      "productId": productId,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "variation": variation.map((e) => e.toJson()).toList(),
      "couponCode": couponCode,
      "discountPercentage": discountPercentage,
    };
  }

  static double _parseDouble(dynamic v) {
    return parseMoneyValue(v);
  }
}

class ProductVariation {
  final String value;
  final String attribute;

  ProductVariation({required this.value, required this.attribute});

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      value: (json['value'] ?? '').toString(),
      attribute: (json['attribute'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {"value": value, "attribute": attribute};
  }
}
