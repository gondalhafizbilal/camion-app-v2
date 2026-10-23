num? _tryParseToNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString().trim());
}

String formatTwoDecimals(dynamic value, {String fallback = '0.00'}) {
  final parsed = _tryParseToNum(value);
  if (parsed == null) return fallback;
  return parsed.toStringAsFixed(2);
}

String formatTwoDecimalsOrDash(dynamic value) {
  final parsed = _tryParseToNum(value);
  if (parsed == null) return '-';
  return parsed.toStringAsFixed(2);
}
