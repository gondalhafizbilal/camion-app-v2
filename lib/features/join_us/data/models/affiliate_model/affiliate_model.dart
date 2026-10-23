import 'package:camion/core/utils/money_utils.dart';

class AffiliateModel {
  final String id;
  final String userId;
  final String fullName;
  final String gender;
  final String nationality;
  final String status;
  final int totalEarnings;
  final int couponsCreated;
  final int couponsUsed;
  final String bio;
  final String? referralLink;
  final num totalPaid;
  final num remainingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  AffiliateModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.gender,
    required this.nationality,
    required this.status,
    required this.totalEarnings,
    required this.couponsCreated,
    required this.couponsUsed,
    required this.bio,
    this.referralLink,
    required this.totalPaid,
    required this.remainingBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AffiliateModel.fromJson(Map<String, dynamic> json) {
    num amountOf(String key) {
      return parseMoneyValue(json[key]);
    }

    return AffiliateModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      userId: (json['userId'] ?? json['customerId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      nationality: (json['nationality'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      totalEarnings: amountOf('totalCommission').toInt(),
      couponsCreated: (json['couponsCreated'] as num? ?? 0).toInt(),
      couponsUsed: (json['couponsUsed'] as num? ?? 0).toInt(),
      bio: (json['bio'] ?? '').toString(),
      referralLink: json['referralLink']?.toString(),
      totalPaid: amountOf('totalPaid'),
      remainingBalance: amountOf('remainingBalance'),
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
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'gender': gender,
      'nationality': nationality,
      'status': status,
      'totalEarnings': totalEarnings,
      'couponsCreated': couponsCreated,
      'couponsUsed': couponsUsed,
      'bio': bio,
      'referralLink': referralLink,
      'totalPaid': totalPaid,
      'remainingBalance': remainingBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
