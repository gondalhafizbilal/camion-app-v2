import 'package:camion/core/utils/money_utils.dart';

class AffiliateStatus {
  final String affiliateId;
  final String fullName;
  final String status;
  final String? token;
  final String? type;
  final String? walletId;
  final num walletBalance;
  final num totalCommission;
  final num totalPaid;
  final num remainingBalance;
  final int couponsCreated;
  final int couponsUsed;
  final String? trendingCouponId;
  final String? topProductId;
  final DateTime? createdAt;

  AffiliateStatus({
    required this.affiliateId,
    required this.fullName,
    required this.status,
    required this.token,
    this.type,
    this.walletId,
    required this.walletBalance,
    required this.totalCommission,
    required this.totalPaid,
    required this.remainingBalance,
    required this.couponsCreated,
    required this.couponsUsed,
    this.trendingCouponId,
    this.topProductId,
    this.createdAt,
  });

  factory AffiliateStatus.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'];
    final walletMap = wallet is Map<String, dynamic>
        ? wallet
        : const <String, dynamic>{};
    num money(dynamic value) {
      return parseMoneyValue(value);
    }

    final trendingCoupon = json['trendingCoupon'];
    final topProduct = json['topProduct'];

    return AffiliateStatus(
      affiliateId: (json['affiliateId'] ?? json['uuid'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      token: json['token']?.toString(),
      type: json['type']?.toString(),
      walletId: walletMap['uuid']?.toString(),
      walletBalance: money(walletMap['amount']),
      totalCommission: money(json['totalCommission']),
      totalPaid: money(json['totalPaid']),
      remainingBalance: money(json['remainingBalance']),
      couponsCreated: (json['couponsCreated'] as num? ?? 0).toInt(),
      couponsUsed: (json['couponsUsed'] as num? ?? 0).toInt(),
      trendingCouponId: trendingCoupon is Map<String, dynamic>
          ? trendingCoupon['uuid']?.toString()
          : null,
      topProductId: topProduct is Map<String, dynamic>
          ? topProduct['uuid']?.toString()
          : null,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'affiliateId': affiliateId,
      'fullName': fullName,
      'status': status,
      'token': token,
      'type': type,
      'walletId': walletId,
      'walletBalance': walletBalance,
      'totalCommission': totalCommission,
      'totalPaid': totalPaid,
      'remainingBalance': remainingBalance,
      'couponsCreated': couponsCreated,
      'couponsUsed': couponsUsed,
      'trendingCouponId': trendingCouponId,
      'topProductId': topProductId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
