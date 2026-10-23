class Currency {
  final String code;
  final String symbol;
  final String? name;
  final int? minorUnit;
  final String? decimalSeparator;
  final String? thousandSeparator;
  final String? prefix;
  final String? suffix;

  Currency({
    required this.code,
    required this.symbol,
    this.name,
    this.minorUnit,
    this.decimalSeparator,
    this.thousandSeparator,
    this.prefix,
    this.suffix,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    // Be flexible with backend keys
    final code = json['code'] ?? json['currency_code'] ?? json['currencyCode'] ?? '';
    final symbol = json['symbol'] ?? json['currency_symbol'] ?? json['currencySymbol'] ?? '';
    return Currency(
      code: code.toString(),
      symbol: symbol.toString(),
      name: json['name']?.toString(),
      minorUnit: json['minorUnit'] ?? json['currency_minor_unit'],
      decimalSeparator: json['decimalSeparator'] ?? json['currency_decimal_separator'],
      thousandSeparator: json['thousandSeparator'] ?? json['currency_thousand_separator'],
      prefix: json['prefix'] ?? json['currency_prefix'],
      suffix: json['suffix'] ?? json['currency_suffix'],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'symbol': symbol,
        if (name != null) 'name': name,
        if (minorUnit != null) 'minorUnit': minorUnit,
        if (decimalSeparator != null) 'decimalSeparator': decimalSeparator,
        if (thousandSeparator != null) 'thousandSeparator': thousandSeparator,
        if (prefix != null) 'prefix': prefix,
        if (suffix != null) 'suffix': suffix,
      };
}
