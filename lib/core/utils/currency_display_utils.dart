import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/money_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String savedCurrencyCode({bool lowercase = false}) {
  final saved = sl<CacheHelper>().getDataString(key: 'currencyCode');
  final normalized = (saved ?? '').trim();
  final fallback = AppDefaults.defaultCurrencyCode;
  final resolved = normalized.isNotEmpty ? normalized : fallback;
  return lowercase ? resolved.toLowerCase() : resolved.toUpperCase();
}

String resolveCurrencyCode(
  Iterable<String?> candidates, {
  bool lowercase = false,
}) {
  for (final candidate in candidates) {
    final normalized = (candidate ?? '').trim();
    if (normalized.isNotEmpty) {
      return lowercase ? normalized.toLowerCase() : normalized.toUpperCase();
    }
  }
  return savedCurrencyCode(lowercase: lowercase);
}

const Map<String, String> _arabicGccCurrencySymbols = {
  'AED': 'د.إ',
  'BHD': 'د.ب',
  'KWD': 'د.ك',
  'OMR': 'ر.ع',
  'QAR': 'ر.ق',
  'SAR': 'ر.س',
};

const Map<String, String> _arabicDigitMap = {
  '0': '٠',
  '1': '١',
  '2': '٢',
  '3': '٣',
  '4': '٤',
  '5': '٥',
  '6': '٦',
  '7': '٧',
  '8': '٨',
  '9': '٩',
};

bool isArabicLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
}

num? parseDisplayNumber(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is Map) return parseMoneyValue(value);
  final normalized = value
      .toString()
      .trim()
      .replaceAll(',', '')
      .replaceAll('٬', '')
      .replaceAll('٫', '.');
  return num.tryParse(normalized);
}

String localizedCurrencyLabel(BuildContext context, String? currencyCode) {
  final code = resolveCurrencyCode([currencyCode]).toUpperCase();
  if (isArabicLocale(context)) {
    return _arabicGccCurrencySymbols[code] ?? code;
  }
  return code;
}

String localizeDigitsForDisplay(BuildContext context, String value) {
  if (!isArabicLocale(context)) return value;
  final buffer = StringBuffer();
  for (final codeUnit in value.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    buffer.write(
      _arabicDigitMap[char] ??
          switch (char) {
            '.' => '٫',
            ',' => '٬',
            _ => char,
          },
    );
  }
  return buffer.toString();
}

String formatLocalizedNumber(
  BuildContext context,
  dynamic value, {
  int? fractionDigits,
  String fallback = '0',
}) {
  final parsed = parseDisplayNumber(value);
  if (parsed == null) return fallback;

  final formatter = NumberFormat.decimalPattern('en');
  if (fractionDigits != null) {
    formatter
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
  }
  return localizeDigitsForDisplay(context, formatter.format(parsed));
}

String formatLocalizedDecimal(
  BuildContext context,
  dynamic value, {
  int fractionDigits = 2,
  String fallback = '0.00',
}) {
  return formatLocalizedNumber(
    context,
    value,
    fractionDigits: fractionDigits,
    fallback: fallback,
  );
}

String formatLocalizedPercent(
  BuildContext context,
  dynamic value, {
  int fractionDigits = 0,
}) {
  return '${formatLocalizedNumber(context, value, fractionDigits: fractionDigits)}%';
}

String formatMoneyForDisplay(
  BuildContext context,
  dynamic amount,
  String? currencyCode, {
  int fractionDigits = 2,
}) {
  final value = formatLocalizedDecimal(
    context,
    amount,
    fractionDigits: fractionDigits,
  );
  final currency = localizedCurrencyLabel(context, currencyCode);
  if (isArabicLocale(context)) {
    return '$value $currency';
  }
  return '$currency $value';
}
