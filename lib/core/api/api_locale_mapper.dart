class ApiLocaleMapper {
  const ApiLocaleMapper._();

  static String toGraphqlLocale(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'en';
    }
    final base = normalized.split('-').first;
    if (base == 'ar') {
      return 'ar';
    }
    return 'en';
  }
}
