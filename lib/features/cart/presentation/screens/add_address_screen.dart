import 'dart:async';
import 'dart:convert';

import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/location_name_localizer.dart';
import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/features/auth/utils/country_code_normalizer.dart';
import 'package:dio/dio.dart';
import 'package:camion/generated/l10n.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key, this.initialAddress});

  final Map<String, dynamic>? initialAddress;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  static const String _fontFamily = 'Montes';
  static const String _defaultZipCode = '0000';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final PhoneNumberController _phoneNumberController = PhoneNumberController();

  final List<csc.Country> _countries = <csc.Country>[];
  final List<csc.State> _states = <csc.State>[];
  final List<csc.City> _cities = <csc.City>[];

  String? _selectedCountryIso;

  bool _countriesLoading = false;
  bool _statesLoading = false;
  bool _citiesLoading = false;
  bool _isDefaultAddress = false;
  bool _isSubmitting = false;
  bool _isContactPrefilling = false;

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
  String _tr(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    unawaited(sl<AppsFlyerService>().logConversionEvent('address_started'));
    _prefillInitialValues();
    _prefillContactDefaults();
    _loadCountries();
  }

  @override
  void dispose() {
    _streetAddressController.dispose();
    _fullNameController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _apartmentController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _prefillInitialValues() {
    final initial = widget.initialAddress ?? const <String, dynamic>{};
    _fullNameController.text =
        (initial['fullName'] ?? initial['full_name'] ?? '').toString().trim();
    _streetAddressController.text =
        (initial['streetAddress'] ?? initial['address_1'] ?? '').toString();
    _apartmentController.text =
        (initial['apartment'] ?? initial['address_2'] ?? '').toString();
    _zipCodeController.text = _resolvedZipCode(
      (initial['zipCode'] ?? initial['postcode'] ?? '').toString(),
    );
    _cityController.text = (initial['city'] ?? '').toString();
    _stateController.text = (initial['state'] ?? '').toString();
    _countryController.text = (initial['country'] ?? '').toString();
    final initialCountryCode = normalizeCountryCode(
      (initial['countryCode'] ?? initial['country_code'] ?? '').toString(),
      countryName: _countryController.text.trim(),
    );
    final initialPhone = (initial['phoneNumber'] ?? initial['phone'] ?? '')
        .toString()
        .trim();
    _applyPhoneDefaults(phone: initialPhone, countryCode: initialCountryCode);
    _isDefaultAddress =
        _toBool(initial['isDefault']) ||
        _toBool(initial['is_default']) ||
        _toBool(initial['default']);
  }

  String _resolvedZipCode([String? value]) {
    final text = (value ?? _zipCodeController.text).trim();
    return text.isEmpty ? _defaultZipCode : text;
  }

  Future<void> _prefillContactDefaults() async {
    if (_isContactPrefilling) return;
    _isContactPrefilling = true;
    try {
      var localFullName = await _secureOrCachedFirstNonEmpty([
        'userName',
        'fullName',
      ]);
      var localPhoneNumber = await _secureOrCachedFirstNonEmpty([
        'phoneNumber',
        'phone',
      ]);
      var localCountryCode = await _secureOrCachedFirstNonEmpty([
        'countryCode',
        'country_code',
      ]);

      final token = (await sl<SecureCacheHelper>().getData(
        key: 'token',
      ))?.trim();
      if ((localFullName.isEmpty ||
              localPhoneNumber.isEmpty ||
              localCountryCode.isEmpty) &&
          token != null &&
          token.isNotEmpty) {
        final remoteContact = await _fetchCustomerContactDefaults(token);
        localFullName = localFullName.isNotEmpty
            ? localFullName
            : remoteContact.fullName;
        localPhoneNumber = localPhoneNumber.isNotEmpty
            ? localPhoneNumber
            : remoteContact.phoneNumber;
        localCountryCode = localCountryCode.isNotEmpty
            ? localCountryCode
            : remoteContact.countryCode;
      }

      if (!mounted) return;
      setState(() {
        if (_fullNameController.text.trim().isEmpty &&
            localFullName.trim().isNotEmpty) {
          _fullNameController.text = localFullName.trim();
        }
        if (_phoneNumberController.phoneController.text.trim().isEmpty &&
            localPhoneNumber.trim().isNotEmpty) {
          _applyPhoneDefaults(
            phone: localPhoneNumber.trim(),
            countryCode: localCountryCode.trim(),
          );
        }
      });
    } finally {
      _isContactPrefilling = false;
    }
  }

  Future<void> _loadCountries() async {
    if (_countriesLoading) return;
    setState(() => _countriesLoading = true);

    try {
      await LocationNameLocalizer.ensureLoaded();
      final list = await csc.getAllCountries();
      list.sort((a, b) => a.name.compareTo(b.name));
      _countries
        ..clear()
        ..addAll(list);

      await _prefillCountryAndState();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعذر تحميل الدول الآن.'
                : 'Could not load countries right now.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _countriesLoading = false);
    }
  }

  Future<void> _prefillCountryAndState() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final countryText = _countryController.text.trim();
    if (countryText.isEmpty || _countries.isEmpty) return;

    final country = _findCountryByIsoOrName(countryText);
    if (country == null) return;

    _selectedCountryIso = country.isoCode;
    _countryController.text = LocationNameLocalizer.countryName(
      country.isoCode,
      languageCode,
    );
    await _loadStates(country.isoCode);

    final stateText = _stateController.text.trim();
    if (stateText.isEmpty || _states.isEmpty) return;

    final state = _findStateByIsoOrName(stateText);
    if (state == null) return;

    final stateCode = _normalizedStateCode(
      rawStateName: state.name,
      rawStateCode: state.isoCode,
      countryIso: country.isoCode,
    );
    _stateController.text = LocationNameLocalizer.stateName(
      countryCode: country.isoCode,
      stateCodeOrName: stateCode,
      languageCode: languageCode,
    );
    await _loadCities(country.isoCode, state.isoCode);

    final cityText = _cityController.text.trim();
    if (cityText.isEmpty || _cities.isEmpty) return;

    final city = _findCityByName(cityText);
    if (city == null) return;
    _cityController.text = LocationNameLocalizer.cityName(
      countryCode: country.isoCode,
      stateCode: state.isoCode,
      cityName: city.name,
      languageCode: languageCode,
    );
  }

  Future<void> _loadStates(String countryIso) async {
    setState(() => _statesLoading = true);
    try {
      final list = await csc.getStatesOfCountry(countryIso);
      list.sort((a, b) => a.name.compareTo(b.name));
      _states
        ..clear()
        ..addAll(list);
    } catch (_) {
      _states.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعذر تحميل المناطق الآن.'
                : 'Could not load states right now.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _statesLoading = false);
    }
  }

  Future<void> _loadCities(String countryIso, String stateIso) async {
    setState(() => _citiesLoading = true);
    try {
      final list = await csc.getStateCities(countryIso, stateIso);
      list.sort((a, b) => a.name.compareTo(b.name));
      _cities
        ..clear()
        ..addAll(list);
    } catch (_) {
      _cities.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعذر تحميل المدن الآن.'
                : 'Could not load cities right now.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _citiesLoading = false);
    }
  }

  csc.Country? _findCountryByIsoOrName(String value) {
    final query = value.trim();
    if (query.isEmpty) return null;

    final localizedCode = LocationNameLocalizer.countryCodeFor(query);
    if (localizedCode != null) {
      for (final item in _countries) {
        if (item.isoCode.toUpperCase() == localizedCode.toUpperCase()) {
          return item;
        }
      }
    }

    if (_isSaudiAlias(query)) {
      for (final item in _countries) {
        if (item.isoCode.toUpperCase() == 'SA') {
          return item;
        }
      }
    }

    for (final item in _countries) {
      if (item.isoCode.toLowerCase() == query.toLowerCase() ||
          item.name.toLowerCase() == query.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  csc.State? _findStateByIsoOrName(String value) {
    final query = value.trim();
    if (query.isEmpty) return null;

    final localizedCode = LocationNameLocalizer.stateCodeFor(
      countryCode: _selectedCountryIso ?? '',
      stateCodeOrName: query,
    );

    for (final item in _states) {
      final normalizedCode = _normalizedStateCode(
        rawStateName: item.name,
        rawStateCode: item.isoCode,
        countryIso: _selectedCountryIso,
      );
      if (item.isoCode.toLowerCase() == query.toLowerCase() ||
          (localizedCode != null &&
              normalizedCode.toLowerCase() == localizedCode.toLowerCase()) ||
          normalizedCode.toLowerCase() == query.toLowerCase() ||
          item.name.toLowerCase() == query.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  csc.City? _findCityByName(String value) {
    final query = value.trim();
    if (query.isEmpty) return null;

    for (final item in _cities) {
      final english = LocationNameLocalizer.englishCityName(
        countryCode: _selectedCountryIso ?? '',
        stateCode: item.stateCode,
        cityName: query,
      );
      if (item.name.toLowerCase() == query.toLowerCase() ||
          item.name.toLowerCase() == english.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  bool _isSaudiAlias(String value) {
    final query = value.trim().toLowerCase();
    return query == 'sa' ||
        query == 'saudi arabia' ||
        query == 'kingdom of saudi arabia' ||
        query == 'ksa' ||
        query == 'السعودية' ||
        query == 'المملكة العربية السعودية';
  }

  String _normalizedStateCode({
    required String rawStateName,
    required String rawStateCode,
    String? countryIso,
  }) {
    final normalizedCountry = (countryIso ?? '').trim().toUpperCase();
    final normalizedName = rawStateName.trim().toLowerCase();
    final normalizedCode = rawStateCode.trim().toUpperCase();
    if (normalizedCountry == 'SA') {
      if (normalizedName == 'riyadh' ||
          normalizedName == 'ar riyad' ||
          normalizedName == 'ar-riyad' ||
          normalizedCode == 'RI') {
        return 'RI';
      }
    }
    return normalizedCode;
  }

  String _resolvedCountryIso() {
    final selectedIso = (_selectedCountryIso ?? '').trim().toUpperCase();
    if (selectedIso.isNotEmpty) {
      return selectedIso;
    }
    final typedCountry = _countryController.text.trim();
    final foundCountry = _findCountryByIsoOrName(typedCountry);
    if (foundCountry != null) {
      return foundCountry.isoCode.trim().toUpperCase();
    }
    if (_isSaudiAlias(typedCountry)) {
      return 'SA';
    }
    return typedCountry.toUpperCase();
  }

  String _resolvedStateCodeForPayload(String countryIso) {
    final typedState = _stateController.text.trim();
    if (typedState.isEmpty) return '';

    final foundState = _findStateByIsoOrName(typedState);
    if (foundState != null) {
      return _normalizedStateCode(
        rawStateName: foundState.name,
        rawStateCode: foundState.isoCode,
        countryIso: countryIso,
      );
    }

    if (countryIso.toUpperCase() == 'SA') {
      final normalizedTyped = typedState.toLowerCase();
      if (normalizedTyped == 'riyadh' || normalizedTyped == 'ri') {
        return 'RI';
      }
    }

    return typedState;
  }

  String _resolvedCityForPayload(String countryIso, String stateCode) {
    final typedCity = _cityController.text.trim();
    if (typedCity.isEmpty) return '';

    final foundCity = _findCityByName(typedCity);
    if (foundCity != null) return foundCity.name;

    return LocationNameLocalizer.englishCityName(
      countryCode: countryIso,
      stateCode: stateCode,
      cityName: typedCity,
    );
  }

  Future<void> _openCountryPicker() async {
    if (_countriesLoading) return;
    if (_countries.isEmpty) {
      await _loadCountries();
      if (_countries.isEmpty) return;
    }

    final selected = await _openSearchablePicker(
      title: _tr('Select Country', 'اختر الدولة'),
      items: _countries
          .map(
            (country) => _SelectableItem(
              id: country.isoCode,
              label: LocationNameLocalizer.countryName(
                country.isoCode,
                Localizations.localeOf(context).languageCode,
              ),
              searchText:
                  '${country.name} ${LocationNameLocalizer.countryName(country.isoCode, 'ar')} ${country.isoCode}',
            ),
          )
          .toList(growable: false),
    );

    if (selected == null) return;

    setState(() {
      _countryController.text = selected.label;
      _selectedCountryIso = selected.id;
      _stateController.clear();
      _cityController.clear();
      _states.clear();
      _cities.clear();
    });

    await _loadStates(selected.id);
  }

  Future<void> _openStatePicker() async {
    var countryIso = _selectedCountryIso;

    if (countryIso == null || countryIso.trim().isEmpty) {
      final resolved = _findCountryByIsoOrName(_countryController.text);
      if (resolved != null) {
        countryIso = resolved.isoCode;
        _selectedCountryIso = resolved.isoCode;
        _countryController.text = resolved.name;
        await _loadStates(countryIso);
      }
    }

    if (countryIso == null || countryIso.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يرجى اختيار الدولة أولًا.'
                : 'Please select country first.',
          ),
        ),
      );
      return;
    }

    if (_statesLoading) return;
    if (_states.isEmpty) {
      await _loadStates(countryIso);
      if (_states.isEmpty) return;
    }

    final selected = await _openSearchablePicker(
      title: _tr('Select State', 'اختر المنطقة'),
      items: _states
          .map(
            (state) => _SelectableItem(
              id: state.isoCode,
              label: LocationNameLocalizer.stateName(
                countryCode: countryIso!,
                stateCodeOrName: _normalizedStateCode(
                  rawStateName: state.name,
                  rawStateCode: state.isoCode,
                  countryIso: countryIso,
                ),
                languageCode: Localizations.localeOf(context).languageCode,
              ),
              searchText:
                  '${state.name} ${state.isoCode} ${LocationNameLocalizer.stateName(countryCode: countryIso, stateCodeOrName: state.isoCode, languageCode: 'ar')}',
            ),
          )
          .toList(growable: false),
    );

    if (selected == null) return;

    setState(() {
      _stateController.text = selected.label;
      _cityController.clear();
      _cities.clear();
    });

    await _loadCities(countryIso, selected.id);
  }

  Future<void> _openCityPicker() async {
    final countryIso = _resolvedCountryIso();
    final state = _findStateByIsoOrName(_stateController.text);
    final stateIso = state?.isoCode ?? _resolvedStateCodeForPayload(countryIso);

    if (countryIso.trim().isEmpty || stateIso.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يرجى اختيار الدولة والمنطقة أولًا.'
                : 'Please select country and state first.',
          ),
        ),
      );
      return;
    }

    if (_citiesLoading) return;
    if (_cities.isEmpty) {
      await _loadCities(countryIso, stateIso);
      if (_cities.isEmpty) return;
    }

    final selected = await _openSearchablePicker(
      title: _tr('Select City', 'اختر المدينة'),
      items: _cities
          .map(
            (city) => _SelectableItem(
              id: city.name,
              label: LocationNameLocalizer.cityName(
                countryCode: countryIso,
                stateCode: stateIso,
                cityName: city.name,
                languageCode: Localizations.localeOf(context).languageCode,
              ),
              searchText:
                  '${city.name} ${LocationNameLocalizer.cityName(countryCode: countryIso, stateCode: stateIso, cityName: city.name, languageCode: 'ar')}',
            ),
          )
          .toList(growable: false),
    );

    if (selected == null) return;

    setState(() {
      _cityController.text = selected.label;
    });
  }

  Future<_SelectableItem?> _openSearchablePicker({
    required String title,
    required List<_SelectableItem> items,
  }) async {
    if (items.isEmpty) return null;

    List<_SelectableItem> filtered = List<_SelectableItem>.from(items);

    return showModalBottomSheet<_SelectableItem>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      builder: (sheetContext) {
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.8;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: maxSheetHeight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          onChanged: (value) {
                            final q = value.trim().toLowerCase();
                            setModalState(() {
                              if (q.isEmpty) {
                                filtered = List<_SelectableItem>.from(items);
                              } else {
                                filtered = items
                                    .where(
                                      (item) =>
                                          LocationNameLocalizer.containsSearchText(
                                            item.searchText,
                                            q,
                                          ) ||
                                          LocationNameLocalizer.containsSearchText(
                                            item.id,
                                            q,
                                          ),
                                    )
                                    .toList(growable: false);
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'بحث'
                                : 'Search',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24.h,
                                    ),
                                    child: Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'لا توجد نتائج.'
                                          : 'No results found.',
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, index) {
                                    final item = filtered[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontFamily: _fontFamily,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      subtitle: Text(item.id),
                                      onTap: () =>
                                          Navigator.of(sheetContext).pop(item),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyPhoneDefaults({
    required String phone,
    required String countryCode,
  }) {
    final normalizedCountryCode = normalizeCountryCode(
      countryCode,
      countryName: _countryController.text.trim(),
    );
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty && normalizedCountryCode.isEmpty) return;

    if (trimmedPhone.startsWith('+')) {
      _phoneNumberController.fullPhoneNumber = trimmedPhone;
      return;
    }

    if (normalizedCountryCode.isNotEmpty && trimmedPhone.isNotEmpty) {
      _phoneNumberController.fullPhoneNumber =
          '$normalizedCountryCode$trimmedPhone';
      return;
    }

    if (trimmedPhone.isNotEmpty) {
      _phoneNumberController.setPhoneNumber(trimmedPhone.replaceAll('+', ''));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final initial = widget.initialAddress ?? const <String, dynamic>{};

    var localFullName = await _secureOrCachedFirstNonEmpty([
      'userName',
      'fullName',
    ]);
    var localPhoneNumber = await _secureOrCachedFirstNonEmpty([
      'phoneNumber',
      'phone',
    ]);
    var localCountryCode = await _secureOrCachedFirstNonEmpty([
      'countryCode',
      'country_code',
    ]);

    final token = (await sl<SecureCacheHelper>().getData(key: 'token'))?.trim();
    if (token == null || token.isEmpty) {
      _showError(
        _tr(
          'Session expired. Please login again.',
          'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
        ),
      );
      return;
    }

    // If contact defaults are missing locally, resolve them silently from
    // customer profile so add-address can still succeed without extra input.
    if (localFullName.isEmpty ||
        localPhoneNumber.isEmpty ||
        localCountryCode.isEmpty) {
      final remoteContact = await _fetchCustomerContactDefaults(token);
      localFullName = localFullName.isNotEmpty
          ? localFullName
          : remoteContact.fullName;
      localPhoneNumber = localPhoneNumber.isNotEmpty
          ? localPhoneNumber
          : remoteContact.phoneNumber;
      localCountryCode = localCountryCode.isNotEmpty
          ? localCountryCode
          : remoteContact.countryCode;
    }

    final typedFullName = _fullNameController.text.trim();
    final fullName = typedFullName.isNotEmpty
        ? typedFullName
        : localFullName.isNotEmpty
        ? localFullName
        : (initial['fullName'] ?? initial['full_name'] ?? 'Address User')
              .toString()
              .trim();

    final typedPhone = _phoneNumberController.phoneNumber.trim();
    final typedCountryCode = _phoneNumberController.countryCode.trim();
    final phoneNumber = typedPhone.isNotEmpty
        ? typedPhone
        : localPhoneNumber.isNotEmpty
        ? localPhoneNumber
        : (initial['phoneNumber'] ?? initial['phone'] ?? '').toString().trim();

    final rawCountryCode = typedCountryCode.isNotEmpty
        ? typedCountryCode
        : localCountryCode.isNotEmpty
        ? localCountryCode
        : (initial['countryCode'] ?? initial['country_code'] ?? '')
              .toString()
              .trim();
    final countryCode = normalizeCountryCode(
      rawCountryCode,
      countryName: _countryController.text.trim(),
    );

    if (fullName.isEmpty || phoneNumber.isEmpty || countryCode.isEmpty) {
      _showError(
        _tr(
          'Missing required contact defaults. Please login again and refresh profile.',
          'بيانات الاتصال الأساسية مفقودة. يرجى تسجيل الدخول مرة أخرى وتحديث الملف الشخصي.',
        ),
      );
      return;
    }

    final countryIso = _resolvedCountryIso();
    final stateCode = _resolvedStateCodeForPayload(countryIso);

    final requestedDefault = _isDefaultAddress;
    final initialDefault =
        _toBool(initial['isDefault']) ||
        _toBool(initial['is_default']) ||
        _toBool(initial['default']);

    final payload = <String, dynamic>{
      'fullName': fullName,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'streetAddress': _streetAddressController.text.trim(),
      'apartment': _apartmentController.text.trim(),
      'zipCode': _resolvedZipCode(),
      'city': _resolvedCityForPayload(countryIso, stateCode),
      'state': stateCode,
      'country': countryIso,
      // Keep isDefault on create; edit default is handled via dedicated PATCH.
      if ((initial['id'] ?? initial['uuid'] ?? '').toString().trim().isEmpty)
        'isDefault': requestedDefault,
    };

    final addressId = (initial['id'] ?? initial['uuid'] ?? '')
        .toString()
        .trim();
    final isUpdate = addressId.isNotEmpty;

    setState(() => _isSubmitting = true);
    try {
      final dio = sl<Dio>();
      final response = isUpdate
          ? await dio.put(
              '${EndPoints.customerAddresses}/$addressId',
              data: payload,
              options: _restOptions(token),
            )
          : await dio.post(
              EndPoints.customerAddresses,
              data: payload,
              options: _restOptions(token),
            );
      _throwIfWriteFailed(
        response,
        fallback: isUpdate
            ? _tr(
                'Could not update address right now.',
                'تعذر تحديث العنوان حالياً.',
              )
            : _tr(
                'Could not add address right now.',
                'تعذر إضافة العنوان حالياً.',
              ),
      );

      final body = _asMap(response.data);
      Map<String, dynamic> patchBody = const <String, dynamic>{};
      if (isUpdate && requestedDefault != initialDefault) {
        final patchResponse = await dio.patch(
          '${EndPoints.customerAddresses}/$addressId',
          data: <String, dynamic>{'isDefault': requestedDefault},
          options: _restOptions(token),
        );
        _throwIfWriteFailed(
          patchResponse,
          fallback: _tr(
            'Address updated but default preference could not be saved.',
            'تم تحديث العنوان لكن تعذر حفظ تفضيل العنوان الافتراضي.',
          ),
        );
        patchBody = _asMap(patchResponse.data);
      }

      final effectiveBody = patchBody.isNotEmpty ? patchBody : body;
      final resolvedId = (body['uuid'] ?? body['id'] ?? addressId)
          .toString()
          .trim();
      if (!mounted) return;
      unawaited(
        sl<AppsFlyerService>().logConversionEvent(
          'address_completed',
          eventParams: {
            'country': (effectiveBody['country'] ?? payload['country'])
                .toString()
                .trim(),
          },
        ),
      );
      context.pop(<String, dynamic>{
        'id': resolvedId,
        'uuid': resolvedId,
        'fullName': (effectiveBody['fullName'] ?? payload['fullName'])
            .toString()
            .trim(),
        'countryCode': (effectiveBody['countryCode'] ?? payload['countryCode'])
            .toString()
            .trim(),
        'phoneNumber': (effectiveBody['phoneNumber'] ?? payload['phoneNumber'])
            .toString()
            .trim(),
        'streetAddress':
            (effectiveBody['streetAddress'] ?? payload['streetAddress'])
                .toString()
                .trim(),
        'apartment': (effectiveBody['apartment'] ?? payload['apartment'])
            .toString()
            .trim(),
        'zipCode': _resolvedZipCode(
          (effectiveBody['zipCode'] ?? payload['zipCode']).toString(),
        ),
        'city': (effectiveBody['city'] ?? payload['city']).toString().trim(),
        'state': (effectiveBody['state'] ?? payload['state']).toString().trim(),
        'country': (effectiveBody['country'] ?? payload['country'])
            .toString()
            .trim(),
        'phone': (effectiveBody['phoneNumber'] ?? payload['phoneNumber'])
            .toString()
            .trim(),
        'address_1':
            (effectiveBody['streetAddress'] ?? payload['streetAddress'])
                .toString()
                .trim(),
        'address_2': (effectiveBody['apartment'] ?? payload['apartment'])
            .toString()
            .trim(),
        'postcode': _resolvedZipCode(
          (effectiveBody['zipCode'] ?? payload['zipCode']).toString(),
        ),
        'isDefault': _toBool(effectiveBody['isDefault'] ?? requestedDefault),
        'is_default': _toBool(effectiveBody['isDefault'] ?? requestedDefault),
      });
    } catch (error) {
      if (error is DioException &&
          BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      _showError(_friendlyApiError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
  }

  Future<_ContactDefaults> _fetchCustomerContactDefaults(String token) async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get(
        EndPoints.customerSelf,
        options: _restOptions(token),
      );
      final payload = _asMap(response.data);
      final data = _asMap(payload['data']);
      final source = data.isNotEmpty ? data : payload;

      final fullName = (source['fullName'] ?? source['name'] ?? '')
          .toString()
          .trim();
      final phoneNumber = (source['phoneNumber'] ?? source['phone'] ?? '')
          .toString()
          .trim();
      final countryCode = normalizeCountryCode(
        (source['countryCode'] ?? source['country_code'] ?? '').toString(),
      );

      final cache = sl<CacheHelper>();
      if (fullName.isNotEmpty) {
        await sl<SecureCacheHelper>().saveData(
          key: 'userName',
          value: fullName,
        );
        await cache.saveData(key: 'userName', value: fullName);
      }
      if (phoneNumber.isNotEmpty) {
        await sl<SecureCacheHelper>().saveData(
          key: 'phoneNumber',
          value: phoneNumber,
        );
        await cache.saveData(key: 'phoneNumber', value: phoneNumber);
      }
      if (countryCode.isNotEmpty) {
        await sl<SecureCacheHelper>().saveData(
          key: 'countryCode',
          value: countryCode,
        );
        await cache.saveData(key: 'countryCode', value: countryCode);
      }

      return _ContactDefaults(
        fullName: fullName,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
      );
    } catch (_) {
      return const _ContactDefaults();
    }
  }

  Options _restOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );
  }

  void _throwIfWriteFailed(Response response, {required String fallback}) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      if (BackendUnavailableDetector.isBackendUnavailableStatusCode(status) ||
          BackendUnavailableDetector.isBackendUnavailablePayload(
            response.data,
          )) {
        BackendUnavailableNotifier.show();
        throw Exception('Server not responding. Please try again.');
      }
      throw Exception(_extractApiMessage(response.data) ?? fallback);
    }

    final body = _asMap(response.data);
    final successFlag = body['success'] ?? body['ok'];
    final statusText = body['status']?.toString().trim().toLowerCase();
    final failed =
        (successFlag is bool && !successFlag) ||
        statusText == 'error' ||
        statusText == 'failed' ||
        statusText == 'fail';
    if (failed) {
      throw Exception(_extractApiMessage(body) ?? fallback);
    }
  }

  String _friendlyApiError(Object error) {
    if (error is DioException) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      final status = error.response?.statusCode;
      if (status != null && status >= 500) {
        return _tr(
          'Server not responding. Please try again.',
          'الخادم لا يستجيب. يرجى المحاولة مرة أخرى.',
        );
      }
      final message = _extractApiMessage(error.response?.data) ?? error.message;
      if (message != null && message.trim().isNotEmpty) return message.trim();
    }

    final text = error.toString().trim();
    if (text.startsWith('Exception:')) {
      final message = text.replaceFirst('Exception:', '').trim();
      if (message.isNotEmpty) return message;
    }
    return _tr('Could not save address right now.', 'تعذر حفظ العنوان حالياً.');
  }

  String? _extractApiMessage(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final message = raw.trim();
      return message.isEmpty ? null : message;
    }
    if (raw is List) {
      final messages = raw
          .map(_extractApiMessage)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
      return null;
    }

    final body = _asMap(raw);
    final direct = body['message']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final error = body['error']?.toString().trim();
    if (error != null && error.isNotEmpty) return error;

    final nestedDataMessage = _extractApiMessage(body['data']);
    if (nestedDataMessage != null && nestedDataMessage.isNotEmpty) {
      return nestedDataMessage;
    }

    final nestedErrorsMessage = _extractApiMessage(body['errors']);
    if (nestedErrorsMessage != null && nestedErrorsMessage.isNotEmpty) {
      return nestedErrorsMessage;
    }

    final fieldErrors = <String>[];
    body.forEach((key, value) {
      final normalizedKey = key.toLowerCase();
      if (normalizedKey == 'message' ||
          normalizedKey == 'error' ||
          normalizedKey == 'errors' ||
          normalizedKey == 'data' ||
          normalizedKey == 'status' ||
          normalizedKey == 'success' ||
          normalizedKey == 'ok') {
        return;
      }
      final parsed = _extractApiMessage(value);
      if (parsed == null || parsed.trim().isEmpty) return;
      fieldErrors.add(parsed.trim());
    });
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.join('\n');
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String) {
      try {
        return _asMap(jsonDecode(raw));
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  void _showError(String message) {
    if (!mounted) return;
    AppToast.show(
      msg: message.trim().isEmpty
          ? _tr('Could not save address right now.', 'تعذر حفظ العنوان حالياً.')
          : message.trim(),
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
    );
  }

  String? _validateRequiredText(
    String? value, {
    required String emptyMessage,
    int minChars = 2,
    String? minCharsMessage,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return emptyMessage;
    if (text.length < minChars) {
      return minCharsMessage ??
          _tr(
            'Please enter at least $minChars characters',
            'يرجى إدخال $minChars أحرف على الأقل',
          );
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.length < 3) {
      return _tr('Postal code is too short', 'الرمز البريدي قصير جداً');
    }
    if (text.length > 12) {
      return _tr('Postal code is too long', 'الرمز البريدي طويل جداً');
    }
    final valid = RegExp(r'^[A-Za-z0-9\- ]+$').hasMatch(text);
    if (!valid) {
      return _tr(
        'Postal code format is invalid',
        'تنسيق الرمز البريدي غير صالح',
      );
    }
    return null;
  }

  Future<String> _secureOrCachedFirstNonEmpty(List<String> keys) async {
    final secure = sl<SecureCacheHelper>();
    for (final key in keys) {
      final value = (await secure.getData(key: key))?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final cache = sl<CacheHelper>();
    for (final key in keys) {
      final value = cache.getDataString(key: key)?.trim();
      if (value != null && value.isNotEmpty) return value;

      final dynamic raw = cache.getData(key: key);
      if (raw != null) {
        final text = raw.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  TextStyle get _titleStyle => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 20.sp,
    height: 2.0,
    letterSpacing: 0,
    color: Colors.black,
  );

  TextStyle get _descriptionStyle => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12.sp,
    height: 1.5,
    letterSpacing: 0,
    color: const Color(0xFF4B4B4B),
  );

  TextStyle get _headingStyle => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16.sp,
    height: 1.5,
    letterSpacing: 0,
    color: Colors.black,
  );

  Widget _fieldLabel(String text) {
    return Text(text, style: _headingStyle);
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.sp,
        height: 1.5,
        color: const Color(0xFF8F97A6),
      ),
      isDense: true,
      contentPadding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.r),
        borderSide: const BorderSide(color: Color(0xFFE1E1E1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.r),
        borderSide: const BorderSide(color: Color(0xFFE1E1E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.r),
        borderSide: const BorderSide(color: Color(0xFFB7B7B7), width: 1),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.sp,
        height: 1.5,
        color: Colors.black,
      ),
      decoration: _inputDecoration(hint: hint, suffixIcon: suffixIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final initial = widget.initialAddress ?? const <String, dynamic>{};
    final isUpdateMode = (initial['id'] ?? initial['uuid'] ?? '')
        .toString()
        .trim()
        .isNotEmpty;
    final pageTitle = isUpdateMode
        ? _tr('Update Address', 'تحديث العنوان')
        : _tr('Add Address', 'إضافة عنوان');
    final submitLabel = isUpdateMode
        ? _tr('Update Address', 'تحديث العنوان')
        : _tr('Add Address', 'إضافة عنوان');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(
                        Icons.arrow_back,
                        size: 24.sp,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(pageTitle, style: _titleStyle),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _tr(
                    'Add your delivery details to make checkout faster and easier.',
                    'أضف تفاصيل التوصيل لتجعل إتمام الطلب أسرع وأسهل.',
                  ),
                  style: _descriptionStyle,
                ),
                SizedBox(height: 20.h),

                _fieldLabel(_tr('Full Name', 'الاسم الكامل')),
                SizedBox(height: 8.h),
                _textField(
                  controller: _fullNameController,
                  hint: _tr('Enter full name', 'أدخل الاسم الكامل'),
                  inputFormatters: [
                    AppInputFormatters.fullNameNoSpecialCharacters,
                  ],
                  validator: (value) => _validateRequiredText(
                    value,
                    emptyMessage: _tr(
                      'Please enter full name',
                      'يرجى إدخال الاسم الكامل',
                    ),
                    minChars: 2,
                    minCharsMessage: _tr(
                      'Name is too short',
                      'الاسم قصير جداً',
                    ),
                  ),
                ),

                SizedBox(height: 14.h),
                _fieldLabel(_tr('Phone', 'الهاتف')),
                SizedBox(height: 8.h),
                CustomPhoneNumberField(
                  controller: _phoneNumberController,
                  hintText: _tr('Enter phone number', 'أدخل رقم الهاتف'),
                  validator: (_) {
                    if (!_phoneNumberController.isValidPhoneNumber) {
                      return _tr(
                        'Please enter a valid phone number',
                        'يرجى إدخال رقم هاتف صالح',
                      );
                    }
                    return null;
                  },
                ),

                SizedBox(height: 14.h),
                _fieldLabel(_tr('Address', 'العنوان')),
                SizedBox(height: 8.h),
                _textField(
                  controller: _streetAddressController,
                  hint: _tr('Enter street address', 'أدخل عنوان الشارع'),
                  inputFormatters: [AppInputFormatters.noEmoji],
                  validator: (value) => _validateRequiredText(
                    value,
                    emptyMessage: s.please_enter_your_address,
                    minChars: 3,
                    minCharsMessage: _tr(
                      'Address is too short',
                      'العنوان قصير جداً',
                    ),
                  ),
                ),

                SizedBox(height: 14.h),
                _fieldLabel(_tr('Country', 'الدولة')),
                SizedBox(height: 8.h),
                _textField(
                  controller: _countryController,
                  hint: _tr('Select country', 'اختر الدولة'),
                  readOnly: true,
                  onTap: _openCountryPicker,
                  suffixIcon: _countriesLoading
                      ? Padding(
                          padding: EdgeInsets.all(10.r),
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFD72631),
                        ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? _tr('Please select country', 'يرجى اختيار الدولة')
                      : null,
                ),

                SizedBox(height: 14.h),
                _fieldLabel(_tr('State', 'المنطقة')),
                SizedBox(height: 8.h),
                _textField(
                  controller: _stateController,
                  hint: _tr('Select state/province', 'اختر المنطقة/المحافظة'),
                  readOnly: true,
                  onTap: _openStatePicker,
                  suffixIcon: _statesLoading
                      ? Padding(
                          padding: EdgeInsets.all(10.r),
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFD72631),
                        ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? _tr('Please select state', 'يرجى اختيار المنطقة')
                      : null,
                ),

                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(child: _fieldLabel(_tr('City', 'المدينة'))),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _fieldLabel(_tr('Postal Code', 'الرمز البريدي')),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _cityController,
                        hint: _tr('Select city', 'اختر المدينة'),
                        readOnly: true,
                        onTap: _openCityPicker,
                        suffixIcon: _citiesLoading
                            ? Padding(
                                padding: EdgeInsets.all(10.r),
                                child: SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFFD72631),
                              ),
                        validator: (value) => _validateRequiredText(
                          value,
                          emptyMessage: _tr(
                            'Please select city',
                            'يرجى اختيار المدينة',
                          ),
                          minChars: 2,
                          minCharsMessage: _tr(
                            'City is too short',
                            'اسم المدينة قصير جداً',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _textField(
                        controller: _zipCodeController,
                        hint: _tr('Enter postal code', 'أدخل الرمز البريدي'),
                        inputFormatters: [AppInputFormatters.noEmoji],
                        keyboardType: TextInputType.text,
                        validator: _validatePostalCode,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14.h),
                _fieldLabel(_tr('Apartment', 'الشقة')),
                SizedBox(height: 8.h),
                _textField(
                  controller: _apartmentController,
                  hint: _tr(
                    'Enter apartment or unit',
                    'أدخل رقم الشقة أو الوحدة',
                  ),
                  inputFormatters: [AppInputFormatters.noEmoji],
                  validator: (value) => _validateRequiredText(
                    value,
                    emptyMessage: _tr(
                      'Please enter apartment',
                      'يرجى إدخال الشقة',
                    ),
                    minChars: 1,
                  ),
                ),

                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.r),
                    border: Border.all(
                      color: const Color(0xFFE1E1E1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tr('Set as default address', 'تعيين كعنوان افتراضي'),
                          style: _headingStyle,
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDefaultAddress,
                        onChanged: (value) {
                          setState(() => _isDefaultAddress = value);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD72631),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            submitLabel,
                            style: AppStyle.styleRegular15(context).copyWith(
                              color: Colors.white,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableItem {
  const _SelectableItem({
    required this.id,
    required this.label,
    String? searchText,
  }) : searchText = searchText ?? label;

  final String id;
  final String label;
  final String searchText;
}

class _ContactDefaults {
  const _ContactDefaults({
    this.fullName = '',
    this.phoneNumber = '',
    this.countryCode = '',
  });

  final String fullName;
  final String phoneNumber;
  final String countryCode;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value == null) return false;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'y';
}
