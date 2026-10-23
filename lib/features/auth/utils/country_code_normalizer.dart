import 'package:camion/features/auth/data/models/countries_model/country_model.dart';

String normalizeCountryCode(String? raw, {String? countryName}) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) {
    return _countryDialByName(countryName) ?? '';
  }

  if (value.startsWith('+')) {
    return value;
  }

  if (RegExp(r'^\d+$').hasMatch(value)) {
    return '+$value';
  }

  final iso = value.toUpperCase();
  final byIso = CountriesData.getCountryByCode(iso);
  if (byIso != null) {
    return byIso.dialCode;
  }

  final byName = _countryDialByName(value);
  if (byName != null) {
    return byName;
  }

  return value;
}

String? _countryDialByName(String? countryName) {
  final name = (countryName ?? '').trim().toLowerCase();
  if (name.isEmpty) return null;

  final byEnglish = CountriesData.countries.where((country) {
    return country.name.trim().toLowerCase() == name;
  });
  if (byEnglish.isNotEmpty) {
    return byEnglish.first.dialCode;
  }

  final byArabic = CountriesData.countriesArabic.where((country) {
    return country.name.trim().toLowerCase() == name;
  });
  if (byArabic.isNotEmpty) {
    return byArabic.first.dialCode;
  }

  return null;
}
