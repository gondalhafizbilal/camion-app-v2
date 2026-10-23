import 'dart:convert';

import 'package:flutter/services.dart';

class LocationNameLocalizer {
  LocationNameLocalizer._();

  static const String _assetPath =
      'assets/location_data/location_names_en_ar.json';

  static bool _loaded = false;
  static final Map<String, _LocalizedName> _countriesByCode = {};
  static final Map<String, String> _countryCodeByName = {};
  static final Map<String, _LocalizedName> _statesByKey = {};
  static final Map<String, String> _stateCodeByNameKey = {};
  static final Map<String, _LocalizedName> _citiesByKey = {};
  static final Map<String, String> _cityEnByNameKey = {};

  static Future<void> ensureLoaded() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;

    for (final row in (data['countries'] as List<dynamic>)) {
      final values = row as List<dynamic>;
      final code = _value(values, 0).toUpperCase();
      final en = _value(values, 1);
      final ar = _value(values, 2);
      if (code.isEmpty) continue;
      _countriesByCode[code] = _LocalizedName(en: en, ar: ar);
      _countryCodeByName[_normalize(en)] = code;
      _countryCodeByName[_normalize(ar)] = code;
    }

    for (final row in (data['states'] as List<dynamic>)) {
      final values = row as List<dynamic>;
      final countryCode = _value(values, 0).toUpperCase();
      final stateCode = _value(values, 1);
      final en = _value(values, 2);
      final ar = _value(values, 3);
      if (countryCode.isEmpty || stateCode.isEmpty) continue;
      final key = _stateKey(countryCode, stateCode);
      _statesByKey[key] = _LocalizedName(en: en, ar: ar);
      _stateCodeByNameKey[_nameKey(countryCode, en)] = stateCode;
      _stateCodeByNameKey[_nameKey(countryCode, ar)] = stateCode;
    }

    for (final row in (data['cities'] as List<dynamic>)) {
      final values = row as List<dynamic>;
      final countryCode = _value(values, 0).toUpperCase();
      final stateCode = _value(values, 1);
      final en = _value(values, 2);
      final ar = _value(values, 3);
      if (countryCode.isEmpty || stateCode.isEmpty || en.isEmpty) continue;
      final key = _cityKey(countryCode, stateCode, en);
      _citiesByKey[key] = _LocalizedName(en: en, ar: ar);
      _cityEnByNameKey[_cityNameKey(countryCode, stateCode, en)] = en;
      _cityEnByNameKey[_cityNameKey(countryCode, stateCode, ar)] = en;
    }

    _loaded = true;
  }

  static String countryName(String value, String languageCode) {
    final code = countryCodeFor(value);
    final name = code == null ? null : _countriesByCode[code];
    return name?.forLanguage(languageCode) ?? value;
  }

  static String? countryCodeFor(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final upper = text.toUpperCase();
    if (_countriesByCode.containsKey(upper)) return upper;
    return _countryCodeByName[_normalize(text)];
  }

  static String stateName({
    required String countryCode,
    required String stateCodeOrName,
    required String languageCode,
  }) {
    final code = stateCodeFor(
      countryCode: countryCode,
      stateCodeOrName: stateCodeOrName,
    );
    final name = code == null
        ? null
        : _statesByKey[_stateKey(countryCode, code)];
    return name?.forLanguage(languageCode) ?? stateCodeOrName;
  }

  static String? stateCodeFor({
    required String countryCode,
    required String stateCodeOrName,
  }) {
    final text = stateCodeOrName.trim();
    if (text.isEmpty) return null;
    final directKey = _stateKey(countryCode, text);
    if (_statesByKey.containsKey(directKey)) return text;
    return _stateCodeByNameKey[_nameKey(countryCode, text)];
  }

  static String cityName({
    required String countryCode,
    required String stateCode,
    required String cityName,
    required String languageCode,
  }) {
    final english = englishCityName(
      countryCode: countryCode,
      stateCode: stateCode,
      cityName: cityName,
    );
    final name = _citiesByKey[_cityKey(countryCode, stateCode, english)];
    return name?.forLanguage(languageCode) ?? cityName;
  }

  static String englishCityName({
    required String countryCode,
    required String stateCode,
    required String cityName,
  }) {
    final text = cityName.trim();
    if (text.isEmpty) return '';
    return _cityEnByNameKey[_cityNameKey(countryCode, stateCode, text)] ?? text;
  }

  static bool matches({
    required String query,
    required String code,
    required String english,
    required String arabic,
  }) {
    final q = _normalize(query);
    if (q.isEmpty) return true;
    return _normalize(code).contains(q) ||
        _normalize(english).contains(q) ||
        _normalize(arabic).contains(q);
  }

  static bool containsSearchText(String text, String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;
    return _normalize(text).contains(q);
  }

  static String _value(List<dynamic> values, int index) {
    if (index >= values.length) return '';
    return (values[index] ?? '').toString().trim();
  }

  static String _stateKey(String countryCode, String stateCode) =>
      '${countryCode.trim().toUpperCase()}|${stateCode.trim().toLowerCase()}';

  static String _cityKey(String countryCode, String stateCode, String name) =>
      '${countryCode.trim().toUpperCase()}|${stateCode.trim().toLowerCase()}|${_normalize(name)}';

  static String _nameKey(String countryCode, String name) =>
      '${countryCode.trim().toUpperCase()}|${_normalize(name)}';

  static String _cityNameKey(
    String countryCode,
    String stateCode,
    String name,
  ) =>
      '${countryCode.trim().toUpperCase()}|${stateCode.trim().toLowerCase()}|${_normalize(name)}';

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'\s+'), ' ');
}

class _LocalizedName {
  const _LocalizedName({required this.en, required this.ar});

  final String en;
  final String ar;

  String forLanguage(String languageCode) {
    return languageCode.toLowerCase().startsWith('ar') && ar.trim().isNotEmpty
        ? ar
        : en;
  }
}
