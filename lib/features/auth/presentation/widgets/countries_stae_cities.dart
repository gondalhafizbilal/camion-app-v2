// // country_state_city_widget.dart
// import 'dart:developer';
// import 'package:camion/core/utils/app_colors.dart';
// import 'package:camion/features/auth/data/models/countries_model/shipping/shipping_countries_model.dart';
// import 'package:camion/generated/l10n.dart';
// import 'package:flutter/material.dart';
// import 'package:country_state_city/country_state_city.dart' as csc;
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class CountryStateCityWidget extends StatefulWidget {
//   final TextEditingController countryController;
//   final TextEditingController stateController;
//   final TextEditingController cityController;
//
//   const CountryStateCityWidget({
//     super.key,
//     required this.countryController,
//     required this.stateController,
//     required this.cityController,
//   });
//
//   @override
//   State<CountryStateCityWidget> createState() => _CountryStateCityWidgetState();
// }
//
// class _CountryStateCityWidgetState extends State<CountryStateCityWidget> {
//   String? selectedCountry;
//   String? selectedState;
//   String? selectedCity;
//
//   List<csc.Country> availableCountries = [];
//   List<csc.State> states = [];
//   List<csc.City> cities = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCountries();
//   }
//
//   void _loadCountries() async {
//     List<csc.Country> allCountries = await csc.getAllCountries();
//
//     availableCountries = allCountries.where((country) {
//       return countries.contains(country.isoCode);
//     }).toList();
//
//     availableCountries.sort((a, b) => a.name.compareTo(b.name));
//
//     setState(() {});
//   }
//
//   void _loadStates(String countryCode) async {
//     states = await csc.getStatesOfCountry(countryCode);
//     cities = [];
//     selectedState = null;
//     selectedCity = null;
//     widget.stateController.clear();
//     widget.cityController.clear();
//     setState(() {});
//   }
//
//   void _loadCities(String countryCode, String stateCode) async {
//     cities = await csc.getStateCities(countryCode, stateCode);
//     selectedCity = null;
//     widget.cityController.clear();
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Country Dropdown
//         DropdownButtonFormField<String>(
//           icon: const Icon(Icons.keyboard_arrow_down),
//           value: selectedCountry,
//           decoration: InputDecoration(
//             hintText: _required(S.of(context).country),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: AppColors.primaryColor, width: 2.w),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.red, width: 1.w),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.red, width: 2.w),
//             ),
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: 12.w,
//               vertical: 16.h,
//             ),
//           ),
//           isExpanded: true,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return S.of(context).please_select_your_country;
//             }
//             return null;
//           },
//           onChanged: (value) {
//             setState(() {
//               selectedCountry = value;
//               // widget.countryController.text = availableCountries
//               //     .firstWhere((c) => c.isoCode == value)
//               //     .name;
//               widget.countryController.text = value!;
//
//               log(widget.countryController.text);
//             });
//             if (value != null) {
//               _loadStates(value);
//             }
//           },
//           items: availableCountries.map((country) {
//             return DropdownMenuItem(
//               value: country.isoCode,
//               child: Row(
//                 children: [
//                   Container(
//                     width: 32,
//                     height: 24,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Center(
//                       child: Text(
//                         country.flag,
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(country.name, overflow: TextOverflow.ellipsis),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//
//         SizedBox(height: 10.h),
//
//         // State Dropdown
//         DropdownButtonFormField<String>(
//           icon: const Icon(Icons.keyboard_arrow_down),
//           value: selectedState,
//           decoration: InputDecoration(
//             hintText: _required(S.of(context).state),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: AppColors.primaryColor, width: 2.w),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.red, width: 1.w),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.red, width: 2.w),
//             ),
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: 12.w,
//               vertical: 16.h,
//             ),
//           ),
//           isExpanded: true,
//           validator: (value) {
//             if (selectedCountry != null && (value == null || value.isEmpty)) {
//               return S.of(context).please_enter_your_state;
//             }
//             return null;
//           },
//           onChanged: selectedCountry == null
//               ? null
//               : (value) {
//                   setState(() {
//                     selectedState = value;
//                     // widget.stateController.text = states
//                     //     .firstWhere((s) => s.isoCode == value)
//                     //     .name;
//
//                     widget.stateController.text = value!;
//
//                     log(widget.stateController.text);
//                   });
//                   if (value != null && selectedCountry != null) {
//                     _loadCities(selectedCountry!, value);
//                   }
//                 },
//           items: states.map((state) {
//             return DropdownMenuItem(
//               value: state.isoCode,
//               child: Text(state.name, overflow: TextOverflow.ellipsis),
//             );
//           }).toList(),
//         ),
//
//         SizedBox(height: 10.h),
//
//         // City Dropdown
//         DropdownButtonFormField<String>(
//           icon: const Icon(Icons.keyboard_arrow_down),
//           value: selectedCity,
//           decoration: InputDecoration(
//             hintText: _required(S.of(context).city),
//
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: AppColors.primaryColor, width: 2.w),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.red, width: 1.w),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12.r),
//               borderSide: BorderSide(color: Colors.red, width: 2.w),
//             ),
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: 12.w,
//               vertical: 16.h,
//             ),
//           ),
//           isExpanded: true,
//           validator: (value) {
//             if (selectedState != null && (value == null || value.isEmpty)) {
//               return S.of(context).please_enter_your_city;
//             }
//             return null;
//           },
//           onChanged: selectedState == null
//               ? null
//               : (value) {
//                   setState(() {
//                     selectedCity = value;
//                     widget.cityController.text = value!;
//                   });
//                 },
//           items: cities.map((city) {
//             return DropdownMenuItem(
//               value: city.name,
//               child: Text(city.name, overflow: TextOverflow.ellipsis),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }

// country_state_city_widget.dart
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/location_name_localizer.dart';
import 'package:camion/features/auth/data/models/countries_model/shipping/shipping_countries_model.dart';
import 'package:camion/generated/l10n.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CountryStateCityWidget extends StatefulWidget {
  /// countryController can be:
  /// - ISO code: "QA", "PK"
  /// - Full name: "Qatar", "Pakistan"
  final TextEditingController countryController;

  /// stateController can be:
  /// - ISO code: "DA"
  /// - Full name: "Doha"
  /// (depends on your backend / saved format)
  final TextEditingController stateController;

  /// cityController is expected to be city name
  final TextEditingController cityController;

  const CountryStateCityWidget({
    super.key,
    required this.countryController,
    required this.stateController,
    required this.cityController,
  });

  @override
  State<CountryStateCityWidget> createState() => _CountryStateCityWidgetState();
}

String _required(String label) => '$label *';

class _CountryStateCityWidgetState extends State<CountryStateCityWidget> {
  String? selectedCountry; // isoCode
  String? selectedState; // isoCode
  String? selectedCity; // city.name

  List<csc.Country> availableCountries = [];
  List<csc.State> states = [];
  List<csc.City> cities = [];

  bool _countriesLoaded = false;
  bool _isPrefilling = false;
  bool _userTouched = false;

  bool _isBlank(String? v) => v == null || v.trim().isEmpty;

  String _norm(String v) => v.trim().toLowerCase();
  String get _languageCode =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  // ----------------------------
  // Finders that accept ISO OR name
  // ----------------------------

  csc.Country? _findCountryByIsoOrName(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;

    // ISO match (QA/PK/etc)
    final byIso = availableCountries.where((c) => c.isoCode == v).toList();
    if (byIso.isNotEmpty) return byIso.first;

    // Name match (Qatar/Pakistan) - case insensitive
    final n = _norm(v);
    final byName = availableCountries.where((c) => _norm(c.name) == n).toList();
    if (byName.isNotEmpty) return byName.first;

    // Sometimes backend sends "QATAR" / "PAKISTAN" etc (handled by norm)
    return null;
  }

  csc.State? _findStateByIsoOrName(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;

    // ISO match
    final byIso = states.where((s) => s.isoCode == v).toList();
    if (byIso.isNotEmpty) return byIso.first;

    // Name match
    final n = _norm(v);
    final byName = states.where((s) => _norm(s.name) == n).toList();
    if (byName.isNotEmpty) return byName.first;

    return null;
  }

  csc.City? _findCityByName(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;

    final n = _norm(v);
    final byName = cities.where((c) => _norm(c.name) == n).toList();
    if (byName.isNotEmpty) return byName.first;

    return null;
  }

  // ----------------------------
  // Lifecycle
  // ----------------------------

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    await LocationNameLocalizer.ensureLoaded();
    final allCountries = await csc.getAllCountries();

    availableCountries = allCountries.where((country) {
      return countries.contains(country.isoCode);
    }).toList();

    availableCountries.sort((a, b) => a.name.compareTo(b.name));

    _countriesLoaded = true;

    await _tryPrefillFromControllers();

    if (mounted) setState(() {});
  }

  Future<void> _loadStates(
    String countryCode, {
    bool clearSelection = true,
  }) async {
    final loadedStates = await csc.getStatesOfCountry(countryCode);

    states = loadedStates;
    cities = [];

    if (clearSelection) {
      selectedState = null;
      selectedCity = null;
      widget.stateController.clear();
      widget.cityController.clear();
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadCities(
    String countryCode,
    String stateCode, {
    bool clearSelection = true,
  }) async {
    final loadedCities = await csc.getStateCities(countryCode, stateCode);

    cities = loadedCities;

    if (clearSelection) {
      selectedCity = null;
      widget.cityController.clear();
    }

    if (mounted) setState(() {});
  }

  /// ✅ Prefill from controller values:
  /// - Accept ISO code or full names for country/state.
  /// - City matches by name.
  Future<void> _tryPrefillFromControllers() async {
    if (_userTouched) return;
    if (!_countriesLoaded) return;

    final rawCountry = widget.countryController.text;
    final rawState = widget.stateController.text;
    final rawCity = widget.cityController.text;

    if (_isBlank(rawCountry) && _isBlank(rawState) && _isBlank(rawCity)) {
      return;
    }

    _isPrefilling = true;

    // ---- Country (ISO or Name)
    final countryObj = _findCountryByIsoOrName(rawCountry);
    if (countryObj != null) {
      selectedCountry = countryObj.isoCode;

      // Keep controller consistent: store ISO code (QA/PK) always
      widget.countryController.text = countryObj.isoCode;

      await _loadStates(countryObj.isoCode, clearSelection: false);

      // ---- State (ISO or Name)
      final stateObj = _findStateByIsoOrName(rawState);
      if (stateObj != null) {
        selectedState = stateObj.isoCode;

        // Keep controller consistent: store ISO code always
        widget.stateController.text = stateObj.isoCode;

        await _loadCities(
          countryObj.isoCode,
          stateObj.isoCode,
          clearSelection: false,
        );

        // ---- City (Name)
        final cityObj = _findCityByName(rawCity);
        if (cityObj != null) {
          selectedCity = cityObj.name;
          widget.cityController.text = cityObj.name;
        }
      } else {
        // If state missing but city exists, user can still select manually.
        // Do nothing else.
      }
    }

    _isPrefilling = false;

    if (mounted) setState(() {});
  }

  void _markUserTouched() {
    if (_isPrefilling) return;
    _userTouched = true;
  }

  String _selectedCountryName() {
    final fromState = selectedCountry ?? '';
    if (fromState.isNotEmpty) {
      final country = _findCountryByIsoOrName(fromState);
      if (country != null) {
        return LocationNameLocalizer.countryName(
          country.isoCode,
          _languageCode,
        );
      }
    }

    final fromController = widget.countryController.text.trim();
    if (fromController.isNotEmpty) {
      final country = _findCountryByIsoOrName(fromController);
      if (country != null) {
        return LocationNameLocalizer.countryName(
          country.isoCode,
          _languageCode,
        );
      }
    }
    return '';
  }

  String _selectedStateName() {
    final fromState = selectedState ?? '';
    if (fromState.isNotEmpty) {
      final stateObj = _findStateByIsoOrName(fromState);
      if (stateObj != null && selectedCountry != null) {
        return LocationNameLocalizer.stateName(
          countryCode: selectedCountry!,
          stateCodeOrName: stateObj.isoCode,
          languageCode: _languageCode,
        );
      }
    }

    final fromController = widget.stateController.text.trim();
    if (fromController.isNotEmpty) {
      final stateObj = _findStateByIsoOrName(fromController);
      if (stateObj != null && selectedCountry != null) {
        return LocationNameLocalizer.stateName(
          countryCode: selectedCountry!,
          stateCodeOrName: stateObj.isoCode,
          languageCode: _languageCode,
        );
      }
    }
    return '';
  }

  String _selectedCityName() {
    final fromState = selectedCity ?? '';
    final city = fromState.isNotEmpty ? fromState : widget.cityController.text;
    if (selectedCountry == null || selectedState == null) return city.trim();
    return LocationNameLocalizer.cityName(
      countryCode: selectedCountry!,
      stateCode: selectedState!,
      cityName: city.trim(),
      languageCode: _languageCode,
    );
  }

  Future<void> _showCountryPicker() async {
    if (availableCountries.isEmpty) return;

    List<csc.Country> filteredCountries = List<csc.Country>.from(
      availableCountries,
    );

    final pickedCountry = await showModalBottomSheet<csc.Country>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCountries(String query) {
              final q = query.trim().toLowerCase();
              setModalState(() {
                if (q.isEmpty) {
                  filteredCountries = List<csc.Country>.from(
                    availableCountries,
                  );
                } else {
                  filteredCountries = availableCountries.where((country) {
                    return LocationNameLocalizer.matches(
                      query: q,
                      code: country.isoCode,
                      english: country.name,
                      arabic: LocationNameLocalizer.countryName(
                        country.isoCode,
                        'ar',
                      ),
                    );
                  }).toList();
                }
              });
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Text(
                          S.of(context).choose_country,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
                    child: TextField(
                      onChanged: filterCountries,
                      decoration: InputDecoration(
                        hintText: S.of(context).search_for_countries,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 1.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCountries.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          onTap: () => Navigator.pop(context, country),
                          leading: Text(
                            country.flag,
                            style: TextStyle(fontSize: 20.sp),
                          ),
                          title: Text(
                            LocationNameLocalizer.countryName(
                              country.isoCode,
                              Localizations.localeOf(context).languageCode,
                            ),
                          ),
                          trailing: Text(country.isoCode),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (pickedCountry == null) return;

    _markUserTouched();
    setState(() {
      selectedCountry = pickedCountry.isoCode;
      widget.countryController.text = pickedCountry.isoCode;
    });

    await _loadStates(pickedCountry.isoCode, clearSelection: true);
  }

  Future<void> _showStatePicker() async {
    if (selectedCountry == null || states.isEmpty) return;

    List<csc.State> filteredStates = List<csc.State>.from(states);

    final pickedState = await showModalBottomSheet<csc.State>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isArabic =
                Localizations.localeOf(context).languageCode == 'ar';
            void filterStates(String query) {
              final q = query.trim().toLowerCase();
              setModalState(() {
                if (q.isEmpty) {
                  filteredStates = List<csc.State>.from(states);
                } else {
                  filteredStates = states.where((state) {
                    return LocationNameLocalizer.matches(
                      query: q,
                      code: state.isoCode,
                      english: state.name,
                      arabic: LocationNameLocalizer.stateName(
                        countryCode: selectedCountry ?? '',
                        stateCodeOrName: state.isoCode,
                        languageCode: 'ar',
                      ),
                    );
                  }).toList();
                }
              });
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Text(
                          isArabic
                              ? 'اختر ${S.of(context).state}'
                              : 'Choose ${S.of(context).state}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
                    child: TextField(
                      onChanged: filterStates,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'ابحث عن ${S.of(context).state}'
                            : '${S.of(context).search} for ${S.of(context).state}',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 1.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredStates.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final stateObj = filteredStates[index];
                        return ListTile(
                          onTap: () => Navigator.pop(context, stateObj),
                          title: Text(
                            LocationNameLocalizer.stateName(
                              countryCode: selectedCountry ?? '',
                              stateCodeOrName: stateObj.isoCode,
                              languageCode: Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                          ),
                          trailing: Text(stateObj.isoCode),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (pickedState == null) return;

    _markUserTouched();
    setState(() {
      selectedState = pickedState.isoCode;
      widget.stateController.text = pickedState.isoCode;
      selectedCity = null;
      widget.cityController.clear();
    });

    if (selectedCountry != null) {
      await _loadCities(
        selectedCountry!,
        pickedState.isoCode,
        clearSelection: true,
      );
    }
  }

  Future<void> _showCityPicker() async {
    if (selectedState == null || cities.isEmpty) return;

    List<csc.City> filteredCities = List<csc.City>.from(cities);

    final pickedCity = await showModalBottomSheet<csc.City>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isArabic =
                Localizations.localeOf(context).languageCode == 'ar';
            void filterCities(String query) {
              final q = query.trim().toLowerCase();
              setModalState(() {
                if (q.isEmpty) {
                  filteredCities = List<csc.City>.from(cities);
                } else {
                  filteredCities = cities.where((city) {
                    return LocationNameLocalizer.matches(
                      query: q,
                      code: '',
                      english: city.name,
                      arabic: LocationNameLocalizer.cityName(
                        countryCode: selectedCountry ?? '',
                        stateCode: selectedState ?? '',
                        cityName: city.name,
                        languageCode: 'ar',
                      ),
                    );
                  }).toList();
                }
              });
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Text(
                          isArabic
                              ? 'اختر ${S.of(context).city}'
                              : 'Choose ${S.of(context).city}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
                    child: TextField(
                      onChanged: filterCities,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'ابحث عن ${S.of(context).city}'
                            : '${S.of(context).search} for ${S.of(context).city}',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 1.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCities.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return ListTile(
                          onTap: () => Navigator.pop(context, city),
                          title: Text(
                            LocationNameLocalizer.cityName(
                              countryCode: selectedCountry ?? '',
                              stateCode: selectedState ?? '',
                              cityName: city.name,
                              languageCode: Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (pickedCity == null) return;

    _markUserTouched();
    setState(() {
      selectedCity = pickedCity.name;
      widget.cityController.text = pickedCity.name;
    });
  }

  @override
  void didUpdateWidget(covariant CountryStateCityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If parent updates controller values later (API arrives after build)
    if (!_userTouched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryPrefillFromControllers();
      });
    }
  }

  // ----------------------------
  // UI
  // ----------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Country searchable dropdown
        FormField<String>(
          initialValue: selectedCountry ?? widget.countryController.text,
          validator: (_) {
            final value = selectedCountry ?? widget.countryController.text;
            if (value.trim().isEmpty) {
              return S.of(context).please_select_your_country;
            }
            return null;
          },
          builder: (field) {
            final displayCountry = _selectedCountryName();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _showCountryPicker,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: _required(S.of(context).country),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.w,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 2.w,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.red, width: 1.w),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.red, width: 2.w),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                      suffixIcon: const Icon(Icons.keyboard_arrow_down),
                      errorText: field.errorText,
                    ),
                    child: Text(
                      displayCountry,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: displayCountry.isEmpty
                            ? Colors.transparent
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        SizedBox(height: 10.h),

        FormField<String>(
          initialValue: selectedState ?? widget.stateController.text,
          validator: (_) {
            final value = selectedState ?? widget.stateController.text;
            if (selectedCountry != null && value.trim().isEmpty) {
              return S.of(context).please_enter_your_state;
            }
            return null;
          },
          builder: (field) {
            final displayState = _selectedStateName();
            final enabled = selectedCountry != null && states.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: enabled
                      ? () async {
                          await _showStatePicker();
                          field.didChange(selectedState ?? '');
                          appLog('State ISO: ${widget.stateController.text}');
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: _required(S.of(context).state),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.w,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 2.w,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.red, width: 1.w),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.red, width: 2.w),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                      suffixIcon: const Icon(Icons.keyboard_arrow_down),
                      errorText: field.errorText,
                    ),
                    child: Text(
                      displayState,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: displayState.isEmpty
                            ? Colors.transparent
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        SizedBox(height: 10.h),

        FormField<String>(
          initialValue: selectedCity ?? widget.cityController.text,
          validator: (_) {
            final value = selectedCity ?? widget.cityController.text;
            if (selectedState != null && value.trim().isEmpty) {
              return S.of(context).please_enter_your_city;
            }
            return null;
          },
          builder: (field) {
            final displayCity = _selectedCityName();
            final enabled = selectedState != null && cities.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: enabled
                      ? () async {
                          await _showCityPicker();
                          field.didChange(selectedCity ?? '');
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: _required(S.of(context).city),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.w,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 2.w,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.red, width: 1.w),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.red, width: 2.w),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                      suffixIcon: const Icon(Icons.keyboard_arrow_down),
                      errorText: field.errorText,
                    ),
                    child: Text(
                      displayCity,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: displayCity.isEmpty
                            ? Colors.transparent
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
