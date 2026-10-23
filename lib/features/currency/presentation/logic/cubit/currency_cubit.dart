import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/currency/data/models/currency_model.dart';
import 'package:camion/features/currency/data/repository/currency_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'currency_state.dart';

class CurrencyCubit extends Cubit<CurrencyState> {
  CurrencyCubit(this.currencyRepository) : super(CurrencyInitial());

  final CurrencyRepository currencyRepository;

  Currency? _selected;
  Currency? get selectedCurrency => _selected;
  List<Currency> _currencies = [];
  List<Currency> get currencies => _currencies;
  Currency _c(String code, String name) =>
      Currency(code: code, symbol: code, name: name, minorUnit: 2);

  // ignore: unused_element
  List<Currency> _buildStaticCurrencies() => [
    _c('AED', 'UAE Dirham'),
    _c('AFN', 'Afghan Afghani'),
    _c('ALL', 'Albanian Lek'),
    _c('AMD', 'Armenian Dram'),
    _c('ANG', 'Netherlands Antillean Guilder'),
    _c('AOA', 'Angolan Kwanza'),
    _c('ARS', 'Argentine Peso'),
    _c('AUD', 'Australian Dollar'),
    _c('AWG', 'Aruban Florin'),
    _c('AZN', 'Azerbaijani Manat'),
    _c('BAM', 'Bosnia and Herzegovina Mark'),
    _c('BBD', 'Barbados Dollar'),
    _c('BDT', 'Bangladeshi Taka'),
    _c('BGN', 'Bulgarian Lev'),
    _c('BHD', 'Bahraini Dinar'),
    _c('BIF', 'Burundian Franc'),
    _c('BMD', 'Bermudian Dollar'),
    _c('BND', 'Brunei Dollar'),
    _c('BOB', 'Bolivian Boliviano'),
    _c('BRL', 'Brazilian Real'),
    _c('BSD', 'Bahamian Dollar'),
    _c('BTN', 'Bhutanese Ngultrum'),
    _c('BWP', 'Botswana Pula'),
    _c('BYN', 'Belarusian Ruble'),
    _c('BZD', 'Belize Dollar'),
    _c('CAD', 'Canadian Dollar'),
    _c('CDF', 'Congolese Franc'),
    _c('CHF', 'Swiss Franc'),
    _c('CLF', 'Chilean Unidad de Fomento'),
    _c('CLP', 'Chilean Peso'),
    _c('CNH', 'Offshore Chinese Renminbi'),
    _c('CNY', 'Chinese Renminbi'),
    _c('COP', 'Colombian Peso'),
    _c('CRC', 'Costa Rican Colon'),
    _c('CUP', 'Cuban Peso'),
    _c('CVE', 'Cape Verdean Escudo'),
    _c('CZK', 'Czech Koruna'),
    _c('DJF', 'Djiboutian Franc'),
    _c('DKK', 'Danish Krone'),
    _c('DOP', 'Dominican Peso'),
    _c('DZD', 'Algerian Dinar'),
    _c('EGP', 'Egyptian Pound'),
    _c('ERN', 'Eritrean Nakfa'),
    _c('ETB', 'Ethiopian Birr'),
    _c('EUR', 'Euro'),
    _c('FJD', 'Fiji Dollar'),
    _c('FKP', 'Falkland Islands Pound'),
    _c('FOK', 'Faroese Krona'),
    _c('GBP', 'Pound Sterling'),
    _c('GEL', 'Georgian Lari'),
    _c('GGP', 'Guernsey Pound'),
    _c('GHS', 'Ghanaian Cedi'),
    _c('GIP', 'Gibraltar Pound'),
    _c('GMD', 'Gambian Dalasi'),
    _c('GNF', 'Guinean Franc'),
    _c('GTQ', 'Guatemalan Quetzal'),
    _c('GYD', 'Guyanese Dollar'),
    _c('HKD', 'Hong Kong Dollar'),
    _c('HNL', 'Honduran Lempira'),
    _c('HRK', 'Croatian Kuna'),
    _c('HTG', 'Haitian Gourde'),
    _c('HUF', 'Hungarian Forint'),
    _c('IDR', 'Indonesian Rupiah'),
    _c('ILS', 'Israeli New Shekel'),
    _c('IMP', 'Manx Pound'),
    _c('INR', 'Indian Rupee'),
    _c('IQD', 'Iraqi Dinar'),
    _c('IRR', 'Iranian Rial'),
    _c('ISK', 'Icelandic Krona'),
    _c('JEP', 'Jersey Pound'),
    _c('JMD', 'Jamaican Dollar'),
    _c('JOD', 'Jordanian Dinar'),
    _c('JPY', 'Japanese Yen'),
    _c('KES', 'Kenyan Shilling'),
    _c('KGS', 'Kyrgyzstani Som'),
    _c('KHR', 'Cambodian Riel'),
    _c('KID', 'Kiribati Dollar'),
    _c('KMF', 'Comorian Franc'),
    _c('KRW', 'South Korean Won'),
    _c('KWD', 'Kuwaiti Dinar'),
    _c('KYD', 'Cayman Islands Dollar'),
    _c('KZT', 'Kazakhstani Tenge'),
    _c('LAK', 'Lao Kip'),
    _c('LBP', 'Lebanese Pound'),
    _c('LKR', 'Sri Lanka Rupee'),
    _c('LRD', 'Liberian Dollar'),
    _c('LSL', 'Lesotho Loti'),
    _c('LYD', 'Libyan Dinar'),
    _c('MAD', 'Moroccan Dirham'),
    _c('MDL', 'Moldovan Leu'),
    _c('MGA', 'Malagasy Ariary'),
    _c('MKD', 'Macedonian Denar'),
    _c('MMK', 'Burmese Kyat'),
    _c('MNT', 'Mongolian Togrog'),
    _c('MOP', 'Macanese Pataca'),
    _c('MRU', 'Mauritanian Ouguiya'),
    _c('MUR', 'Mauritian Rupee'),
    _c('MVR', 'Maldivian Rufiyaa'),
    _c('MWK', 'Malawian Kwacha'),
    _c('MXN', 'Mexican Peso'),
    _c('MYR', 'Malaysian Ringgit'),
    _c('MZN', 'Mozambican Metical'),
    _c('NAD', 'Namibian Dollar'),
    _c('NGN', 'Nigerian Naira'),
    _c('NIO', 'Nicaraguan Cordoba'),
    _c('NOK', 'Norwegian Krone'),
    _c('NPR', 'Nepalese Rupee'),
    _c('NZD', 'New Zealand Dollar'),
    _c('OMR', 'Omani Rial'),
    _c('PAB', 'Panamanian Balboa'),
    _c('PEN', 'Peruvian Sol'),
    _c('PGK', 'Papua New Guinean Kina'),
    _c('PHP', 'Philippine Peso'),
    _c('PKR', 'Pakistani Rupee'),
    _c('PLN', 'Polish Zloty'),
    _c('PYG', 'Paraguayan Guarani'),
    _c('QAR', 'Qatari Riyal'),
    _c('RON', 'Romanian Leu'),
    _c('RSD', 'Serbian Dinar'),
    _c('RUB', 'Russian Ruble'),
    _c('RWF', 'Rwandan Franc'),
    _c('SAR', 'Saudi Riyal'),
    _c('SBD', 'Solomon Islands Dollar'),
    _c('SCR', 'Seychellois Rupee'),
    _c('SDG', 'Sudanese Pound'),
    _c('SEK', 'Swedish Krona'),
    _c('SGD', 'Singapore Dollar'),
    _c('SHP', 'Saint Helena Pound'),
    _c('SLE', 'Sierra Leonean Leone'),
    _c('SOS', 'Somali Shilling'),
    _c('SRD', 'Surinamese Dollar'),
    _c('SSP', 'South Sudanese Pound'),
    _c('STN', 'Sao Tome and Principe Dobra'),
    _c('SYP', 'Syrian Pound'),
    _c('SZL', 'Eswatini Lilangeni'),
    _c('THB', 'Thai Baht'),
    _c('TJS', 'Tajikistani Somoni'),
    _c('TMT', 'Turkmenistan Manat'),
    _c('TND', 'Tunisian Dinar'),
    _c('TOP', 'Tongan Paanga'),
    _c('TRY', 'Turkish Lira'),
    _c('TTD', 'Trinidad and Tobago Dollar'),
    _c('TVD', 'Tuvaluan Dollar'),
    _c('TWD', 'New Taiwan Dollar'),
    _c('TZS', 'Tanzanian Shilling'),
    _c('UAH', 'Ukrainian Hryvnia'),
    _c('UGX', 'Ugandan Shilling'),
    _c('USD', 'United States Dollar'),
    _c('UYU', 'Uruguayan Peso'),
    _c('UZS', 'Uzbekistani Som'),
    _c('VES', 'Venezuelan Bolivar Soberano'),
    _c('VND', 'Vietnamese Dong'),
    _c('VUV', 'Vanuatu Vatu'),
    _c('WST', 'Samoan Tala'),
    _c('XAF', 'Central African CFA Franc'),
    _c('XCD', 'East Caribbean Dollar'),
    _c('XDR', 'Special Drawing Rights'),
    _c('XOF', 'West African CFA Franc'),
    _c('XPF', 'CFP Franc'),
    _c('YER', 'Yemeni Rial'),
    _c('ZAR', 'South African Rand'),
    _c('ZMW', 'Zambian Kwacha'),
    _c('ZWL', 'Zimbabwean Dollar'),
  ];

  List<Currency> _fallbackGraphqlCurrencies() => <Currency>[
    Currency(code: 'QAR', symbol: 'QAR', name: 'Qatari Riyal', minorUnit: 2),
    Currency(
      code: 'USD',
      symbol: 'USD',
      name: 'United States Dollar',
      minorUnit: 2,
    ),
  ];

  Currency _defaultCurrency() => Currency(
    code: AppDefaults.defaultCurrencyCode,
    symbol: AppDefaults.defaultCurrencySymbol,
    name: 'Qatari Riyal',
    minorUnit: 2,
  );

  Future<void> loadSavedCurrency() async {
    final code = sl<CacheHelper>().getDataString(key: 'currencyCode');
    final symbol = sl<CacheHelper>().getDataString(key: 'currencySymbol');
    if (code != null && code.isNotEmpty) {
      _selected = Currency(code: code, symbol: (symbol ?? code));
    } else {
      _selected = _defaultCurrency();
      await sl<CacheHelper>().saveData(
        key: 'currencyCode',
        value: _selected!.code,
      );
      await sl<CacheHelper>().saveData(
        key: 'currencySymbol',
        value: _selected!.symbol,
      );
    }
    if (!isClosed && _selected != null) emit(CurrencySelected(_selected!));
  }

  Future<void> loadCurrencies() async {
    if (!isClosed) emit(CurrencyLoading());
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final result = await currencyRepository.getCurrenciesGraphql(token: token);

    _currencies = result.fold(
      (_) {
        return _fallbackGraphqlCurrencies();
      },
      (graphqlCurrencies) {
        if (graphqlCurrencies.isEmpty) {
          return _fallbackGraphqlCurrencies();
        }
        return graphqlCurrencies;
      },
    );

    final selectedCode = (_selected?.code ?? AppDefaults.defaultCurrencyCode)
        .toUpperCase();
    final selectedFromList = _currencies.where(
      (currency) => currency.code.toUpperCase() == selectedCode,
    );
    _selected = selectedFromList.isNotEmpty
        ? selectedFromList.first
        : _fallbackGraphqlCurrencies().first;

    if (!isClosed) {
      emit(CurrencyLoaded(_currencies, _selected));
    }
  }

  // Product feeds already come pre-priced for the selected currency.
  double convertFromQAR(num amountQAR, {String? toCode}) {
    return amountQAR.toDouble();
  }

  String convertFromQARToString(
    num amountQAR, {
    String? toCode,
    int? fractionDigits,
  }) {
    final value = convertFromQAR(amountQAR, toCode: toCode);
    final int fd = fractionDigits ?? (_selected?.minorUnit ?? 2);
    return value.toStringAsFixed(fd);
  }

  Future<void> selectCurrency(Currency currency) async {
    _selected = currency;
    await sl<CacheHelper>().saveData(key: 'currencyCode', value: currency.code);
    await sl<CacheHelper>().saveData(
      key: 'currencySymbol',
      value: currency.symbol,
    );
    await sl<CacheHelper>().saveData(
      key: 'currencySelectionSourceV1',
      value: 'manual',
    );
    await sl<CacheHelper>().saveData(key: 'currencyAutoResolvedV1', value: true);

    if (!isClosed) emit(CurrencySelected(currency));
  }
}
