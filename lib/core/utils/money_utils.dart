double parseMoneyValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(
          value.trim().replaceAll(',', ''),
        ) ??
        0;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final amount = _toDouble(map['amount']);
    final minorAmount = _toDouble(map['minorAmount']);
    if (map.containsKey('minorAmount')) {
      return amount + (minorAmount / 100);
    }
    return amount;
  }
  return double.tryParse(value.toString()) ?? 0;
}

String? parseMoneyCurrencyCode(dynamic value) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final code = map['currencyCode']?.toString().trim() ?? '';
    if (code.isNotEmpty) return code;
    final currency = map['currency']?.toString().trim() ?? '';
    if (currency.isNotEmpty) return currency;
  }
  return null;
}

Map<String, dynamic> buildMoneyMap({
  required num amount,
  num? minorAmount,
  String? currencyCode,
}) {
  final result = <String, dynamic>{
    'amount': amount,
  };
  if (minorAmount != null) {
    result['minorAmount'] = minorAmount;
  }
  if (currencyCode != null && currencyCode.trim().isNotEmpty) {
    result['currencyCode'] = currencyCode.trim();
  }
  return result;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
