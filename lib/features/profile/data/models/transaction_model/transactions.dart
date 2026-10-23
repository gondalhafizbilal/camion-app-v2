import 'package:camion/core/utils/money_utils.dart';

class Transactions {
  final String id;
  final double amount;
  final String description;
  final DateTime createdAt;
  final String? type;
  final String? currencyCode;

  Transactions({
    required this.id,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.type,
    this.currencyCode,
  });

  factory Transactions.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final amountMap = amountRaw is Map<String, dynamic>
        ? amountRaw
        : const <String, dynamic>{};

    return Transactions(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      amount: parseMoneyValue(amountMap.isNotEmpty ? amountMap : amountRaw),
      description: (json['description'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      type: json['type']?.toString(),
      currencyCode: amountMap['currencyCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'currencyCode': currencyCode,
    };
  }
}
