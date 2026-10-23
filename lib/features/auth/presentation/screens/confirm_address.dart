/*

import 'dart:convert';
import 'dart:developer';

import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/auth/presentation/logic/send_user_shipping_cubit/send_user_shipping_address_cubit.dart';
import 'package:camion/features/auth/presentation/widgets/countries_stae_cities.dart';
import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';

class ConfirmAddress extends StatefulWidget {
  const ConfirmAddress({super.key});

  @override
  State<ConfirmAddress> createState() => _ConfirmAddressState();
}

String _required(String label) => '$label *';

class _ConfirmAddressState extends State<ConfirmAddress> {
  static const String _defaultPostcode = '0000';

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final PhoneNumberController phoneController = PhoneNumberController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  final TextEditingController shippingFirstNameController =
  TextEditingController();
  final TextEditingController shippingLastNameController =
  TextEditingController();
  final TextEditingController shippingEmailController = TextEditingController();
  final PhoneNumberController shippingPhoneController = PhoneNumberController();
  final TextEditingController shippingAddress1Controller =
  TextEditingController();
  final TextEditingController shippingAddress2Controller =
  TextEditingController();
  final TextEditingController shippingCityController = TextEditingController();
  final TextEditingController shippingStateController = TextEditingController();
  final TextEditingController shippingPostcodeController =
  TextEditingController();
  final TextEditingController shippingCountryController =
  TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Personal info (fallback) flags
  bool _personalInfoLoading = false;
  bool _attemptedPersonalInfo = false;
  String? _personalInfoError;

  @override
  void initState() {
    super.initState();
    // This screen doesn't call /address/me (no cubit here).
    // It should still prefill personal info (name/email/phone) after login.
    _prefillPersonalInfoOnOpen();
  }

  Future<void> _prefillPersonalInfoOnOpen() async {
    // If user navigates here from login, token/id might be written slightly later.
    // We'll try immediately; if missing userId/token it will just fail and user can type.
    await _fetchPersonalInfoIfNeeded();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postcodeController.dispose();
    countryController.dispose();

    shippingFirstNameController.dispose();
    shippingLastNameController.dispose();
    shippingEmailController.dispose();
    shippingPhoneController.dispose();
    shippingAddress1Controller.dispose();
    shippingAddress2Controller.dispose();
    shippingCityController.dispose();
    shippingStateController.dispose();
    shippingPostcodeController.dispose();
    shippingCountryController.dispose();

    super.dispose();
  }

  // -----------------------
  // Helpers (same logic as other screen)
  // -----------------------
  bool _isBlank(String? v) => v == null || v.trim().isEmpty;

  void _setIfBlank(TextEditingController c, String v) {
    if (_isBlank(c.text) && !_isBlank(v)) {
      c.text = v;
    }
  }

  Map<String, String> _splitFullName(String full) {
    final cleaned = full.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return {'first': '', 'last': ''};
    final parts = cleaned.split(' ');
    if (parts.length == 1) return {'first': parts[0], 'last': ''};
    return {'first': parts.first, 'last': parts.sublist(1).join(' ')};
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Split +E164 into dial + national.
  Map<String, String> _splitE164(String rawPhone) {
    final p = rawPhone.trim();
    final match = RegExp(r'^\+(\d{1,3})(\d+)$').firstMatch(p);
    if (match == null) {
      return {'dial': '', 'national': _onlyDigits(p)};
    }
    return {'dial': '+${match.group(1)}', 'national': match.group(2) ?? ''};
  }

  /// Normalize phone:
  /// - keep digits/+,
  /// - 00xxxx -> +xxxx
  /// - 92xxxx (no +) -> +92xxxx
  /// - 0xxxx (local pk) -> +92xxxx
  String _normalizePhone(String raw) {
    var p = raw.trim();
    if (p.isEmpty) return '';
    p = p.replaceAll(RegExp(r'[^\d\+]'), '');
    if (p.startsWith('00')) p = '+${p.substring(2)}';
    if (!p.startsWith('+') && p.startsWith('92')) p = '+$p';
    if (!p.startsWith('+') && p.startsWith('0') && p.length >= 10) {
      p = '+92${p.substring(1)}';
    }
    return p;
  }

  String _resolvedPostcode(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? '0000' : text;
  }

  String _resolvedPostcode(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? _defaultPostcode : text;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return <String, dynamic>{};

    if (v is Map<String, dynamic>) return v;

    if (v is Map) {
      return v.map((key, value) => MapEntry(key.toString(), value));
    }

    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
        return <String, dynamic>{'__decoded__': decoded};
      } catch (_) {
        return <String, dynamic>{'__raw__': v};
      }
    }

    return <String, dynamic>{'__raw__': v};
  }

  String _safeSnippet(dynamic v, {int max = 600}) {
    try {
      final s = (v is String) ? v : jsonEncode(v);
      return s.length > max ? '${s.substring(0, max)}…' : s;
    } catch (_) {
      return v.toString();
    }
  }

  void _notifyBackendUnavailableIfNeeded(Object error) {
    if (error is DioException &&
        BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
      BackendUnavailableNotifier.show();
    }
  }

  /// Applies phone so UI shows it:
  /// - phoneController.text (visible)
  /// - fullPhoneNumber (stored)
  /// - attempt dialCode update (best-effort)
  void _applyPhoneToField(PhoneNumberController controller, String e164) {
    final normalized = _normalizePhone(e164);
    final parts = _splitE164(normalized);
    final dial = (parts['dial'] ?? '').trim();
    final national = (parts['national'] ?? '').trim();

    controller.phoneController.text = national;
    controller.fullPhoneNumber = normalized;

    // Best-effort: update dial code text shown on prefix
    if (dial.isNotEmpty) {
      try {
        (controller.selectedCountry as dynamic).dialCode = dial;
      } catch (_) {}
    }

    controller.refresh();

    appLog(
      'Phone applied => dial="$dial", national="$national", full="$normalized"',
    );
  }

  // -----------------------
  // Personal info API prefill (/users/{id})
  // Fills ONLY: fullName/email/phone (both billing & shipping personal fields)
  // -----------------------
  Future<void> _fetchPersonalInfoIfNeeded() async {
    if (_attemptedPersonalInfo) return;
    _attemptedPersonalInfo = true;

    setState(() {
      _personalInfoLoading = true;
      _personalInfoError = null;
    });

    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');
      final userId = await sl<SecureCacheHelper>().getData(key: 'id');

      appLog('--- CONFIRM ADDRESS: PERSONAL PREFILL starting ---');
      appLog('userId: $userId');

      if (userId == null || userId.toString().trim().isEmpty) {
        throw Exception('Prefill aborted: userId is null/empty');
      }

      final headers = <String, dynamic>{
        if (token != null && token.toString().isNotEmpty)
          'Authorization': 'Bearer $token',

        if (guestId != null && guestId.toString().isNotEmpty)
          'x-guest-id': guestId,
      };

      final url = '${EndPoints.baseUrl}/users/$userId';
      appLog('GET: $url');
      appLog('headers keys: ${headers.keys.toList()}');

      final dio = sl<Dio>();
      final res = await dio.get(
        url,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
        ),
      );

      appLog('statusCode: ${res.statusCode}');
      appLog('res.data runtimeType: ${res.data.runtimeType}');
      appLog('res.data snippet: ${_safeSnippet(res.data)}');

      final root = _asMap(res.data);
      final dataObj = root.containsKey('data') ? _asMap(root['data']) : root;

      final fullName = (dataObj['fullName'] ??
          dataObj['full_name'] ??
          dataObj['name'] ??
          '')
          .toString()
          .trim();

      String firstName = (dataObj['first_name'] ?? '').toString().trim();
      String lastName = (dataObj['last_name'] ?? '').toString().trim();

      if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
        final split = _splitFullName(fullName);
        firstName = (split['first'] ?? '').trim();
        lastName = (split['last'] ?? '').trim();
      }

      final email = (dataObj['email'] ?? '').toString().trim();

      final phoneRaw =
      (dataObj['phone'] ?? dataObj['mobile'] ?? '').toString().trim();
      final phone = _normalizePhone(phoneRaw);

      appLog(
        'Parsed => fullName="$fullName" first="$firstName" last="$lastName" email="$email" phone="$phone"',
      );

      // Fill billing personal (only if blank)
      _setIfBlank(firstNameController, firstName);
      _setIfBlank(lastNameController, lastName);
      _setIfBlank(emailController, email);

      // Fill shipping personal (only if blank)
      _setIfBlank(shippingFirstNameController, firstName);
      _setIfBlank(shippingLastNameController, lastName);
      _setIfBlank(shippingEmailController, email);

      // Phones: ensure field shows number
      if (phone.isNotEmpty) {
        if (_isBlank(phoneController.phoneController.text)) {
          _applyPhoneToField(phoneController, phone);
        }
        if (_isBlank(shippingPhoneController.phoneController.text)) {
          _applyPhoneToField(shippingPhoneController, phone);
        }
      }

      setState(() => _personalInfoLoading = false);
      appLog('--- CONFIRM ADDRESS: PERSONAL PREFILL success ---');
    } catch (e, st) {
      appLog('--- CONFIRM ADDRESS: PERSONAL PREFILL error ---');
      appLog('Prefill error: $e', stackTrace: st);
      setState(() {
        _personalInfoLoading = false;
        _personalInfoError = e.toString();
      });
    }
  }

  String? selectedCountry;
  String? selectedCity;
  String? selectedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          CustomSliverAppBar(
            actions: const [],
            appBarHeight: 50.h,
            isShownDivider: true,
            title: Text(
              S.of(context).address_confirmation,
              style: AppStyle.styleRegular18(context)
                  .copyWith(color: Colors.black),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_personalInfoLoading) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Loading personal info...',
                            style: AppStyle.styleRegular14(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_personalInfoError != null) ...[
                      Text(
                        'Couldn\'t load personal info automatically. Please enter it manually.',
                        style: AppStyle.styleRegular14(context)
                            .copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(height: 15.h),
                    Text(
                      S.of(context).personal_information,
                      style: AppStyle.styleRegular16(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 15.h),

                    CustomTextFormField(
                      hintText: _required(S.of(context).first_name),
                      controller: firstNameController,
                          inputFormatters: [AppInputFormatters.fullNameNoSpecialCharacters],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_first_name;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      hintText: _required(S.of(context).last_name),
                      controller: lastNameController,
                          inputFormatters: [AppInputFormatters.fullNameNoSpecialCharacters],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_last_name;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      hintText: _required(S.of(context).email),
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_email;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomPhoneNumberField(
                      controller: phoneController,
                      hintText: _required(S.of(context).phone_Number),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_phone_number;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      hintText: _required(S.of(context).address_1),
                      controller: address1Controller,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_address;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      hintText: _required(S.of(context).address_2),
                      controller: address2Controller,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_address;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CountryStateCityWidget(
                      cityController: cityController,
                      stateController: stateController,
                      countryController: countryController,
                    ),
                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      hintText: S.of(context).postal_code,
                      controller: postcodeController,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (_) => null,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      S.of(context).shipping_address,
                      style: AppStyle.styleRegular16(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),

                    const SizedBox(height: 15),

                    CustomTextFormField(
                      hintText: _required(S.of(context).first_name),
                      controller: shippingFirstNameController,
                          inputFormatters: [AppInputFormatters.fullNameNoSpecialCharacters],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_first_name;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    CustomTextFormField(
                      hintText: _required(S.of(context).last_name),
                      controller: shippingLastNameController,
                          inputFormatters: [AppInputFormatters.fullNameNoSpecialCharacters],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_last_name;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      hintText: _required(S.of(context).email),
                      controller: shippingEmailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_email;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomPhoneNumberField(
                      controller: shippingPhoneController,
                      hintText: _required(S.of(context).phone_Number),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_phone_number;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),
                    CustomTextFormField(
                      hintText: _required(S.of(context).address_1),
                      controller: shippingAddress1Controller,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_address;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),
                    CustomTextFormField(
                      hintText: _required(S.of(context).address_2),
                      controller: shippingAddress2Controller,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_address;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    CountryStateCityWidget(
                      cityController: shippingCityController,
                      stateController: shippingStateController,
                      countryController: shippingCountryController,
                    ),

                    const SizedBox(height: 24),

                    BlocConsumer<SendUserShippingAddressCubit,
                        SendUserShippingAddressState>(
                      listener: (context, state) {
                        if (state is SendUserShippingAddressError) {
                          AppToast.show(
                            msg: state.error.message,
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                        }

                        if (state is SendUserShippingAddressLoaded) {
                          AppToast.show(
                            msg: S
                                .of(context)
                                .Shipping_address_added_successfully,
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                          );

                          GoRouter.of(context)
                              .goNamed(AppRouter.selectingFromBottomNavBar);
                        }
                      },
                      builder: (context, state) {
                        return CustomElevatedButton(
                          onPressed: state is SendUserShippingAddressLoading
                              ? () {}
                              : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            // ✅ FIX: use shipping controllers for shipping fields
                            context
                                .read<SendUserShippingAddressCubit>()
                                .sendUserShippingAddress(
                              // billing
                              firstName: firstNameController.text,
                              lastName: lastNameController.text,
                              email: emailController.text,
                              phone: phoneController.fullPhoneNumber,
                              address1: address1Controller.text,
                              address2: address2Controller.text,
                              city: cityController.text,
                              state: stateController.text,
                              postcode: _resolvedPostcode(postcodeController),
                              country: countryController.text,

                              // shipping
                              shippingFirstName:
                              shippingFirstNameController.text,
                              shippingLastName:
                              shippingLastNameController.text,
                              shippingEmail:
                              shippingEmailController.text,
                              shippingPhone: shippingPhoneController
                                  .fullPhoneNumber,
                              shippingAddress1:
                              shippingAddress1Controller.text,
                              shippingAddress2:
                              shippingAddress2Controller.text,
                              shippingCity: shippingCityController.text,
                              shippingState:
                              shippingStateController.text,
                              shippingPostcode:
                              _resolvedPostcode(shippingPostcodeController),
                              shippingCountry:
                              shippingCountryController.text,
                            );
                          },
                          child: state is SendUserShippingAddressLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : Text(
                            S.of(context).save,
                            style: AppStyle.styleRegular15(context)
                                .copyWith(color: Colors.white),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20.h),

                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/

// confirm_address.dart
import 'dart:convert';

import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/features/auth/presentation/widgets/countries_stae_cities.dart';
import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/features/cart/presentation/widgets/cart_sliver_app_bar.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';

class ConfirmAddress extends StatefulWidget {
  const ConfirmAddress({super.key});

  @override
  State<ConfirmAddress> createState() => _ConfirmAddressState();
}

class _ConfirmAddressState extends State<ConfirmAddress> {
  // -------------------------
  // Singular fields only
  // -------------------------
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final PhoneNumberController phoneController = PhoneNumberController();

  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loadingPrefill = false;
  bool _attemptedAddressMe = false;
  bool _attemptedUserFallback = false;
  String? _prefillError;

  @override
  void initState() {
    super.initState();
    _prefillOnOpen();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    address1Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postcodeController.dispose();
    countryController.dispose();

    super.dispose();
  }

  // -----------------------
  // Helpers
  // -----------------------
  String _required(String label) => '$label *';

  bool _isBlank(String? v) => v == null || v.trim().isEmpty;

  void _setIfBlank(TextEditingController c, String v) {
    if (_isBlank(c.text) && !_isBlank(v)) {
      c.text = v;
    }
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Split +E164 into dial + national.
  Map<String, String> _splitE164(String rawPhone) {
    final p = rawPhone.trim();
    final match = RegExp(r'^\+(\d{1,3})(\d+)$').firstMatch(p);
    if (match == null) {
      return {'dial': '', 'national': _onlyDigits(p)};
    }
    return {'dial': '+${match.group(1)}', 'national': match.group(2) ?? ''};
  }

  /// Normalize phone:
  /// - keep digits/+,
  /// - 00xxxx -> +xxxx
  /// - 92xxxx (no +) -> +92xxxx
  /// - 0xxxx (local pk) -> +92xxxx
  String _normalizePhone(String raw) {
    var p = raw.trim();
    if (p.isEmpty) return '';
    p = p.replaceAll(RegExp(r'[^\d\+]'), '');
    if (p.startsWith('00')) p = '+${p.substring(2)}';
    if (!p.startsWith('+') && p.startsWith('92')) p = '+$p';
    if (!p.startsWith('+') && p.startsWith('0') && p.length >= 10) {
      p = '+92${p.substring(1)}';
    }
    return p;
  }

  String _resolvedPostcode(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? '0000' : text;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return <String, dynamic>{};

    if (v is Map<String, dynamic>) return v;

    if (v is Map) {
      return v.map((key, value) => MapEntry(key.toString(), value));
    }

    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
        return <String, dynamic>{'__decoded__': decoded};
      } catch (_) {
        return <String, dynamic>{'__raw__': v};
      }
    }

    return <String, dynamic>{'__raw__': v};
  }

  String _safeSnippet(dynamic v, {int max = 600}) {
    try {
      final s = (v is String) ? v : jsonEncode(v);
      return s.length > max ? '${s.substring(0, max)}…' : s;
    } catch (_) {
      return v.toString();
    }
  }

  void _notifyBackendUnavailableIfNeeded(Object error) {
    if (error is DioException &&
        BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
      BackendUnavailableNotifier.show();
    }
  }

  /// Applies phone so UI shows it:
  /// - phoneController.text (visible)
  /// - fullPhoneNumber (stored)
  /// - attempt dialCode update (best-effort)
  void _applyPhoneToField(PhoneNumberController controller, String e164) {
    final normalized = _normalizePhone(e164);
    final parts = _splitE164(normalized);
    final dial = (parts['dial'] ?? '').trim();
    final national = (parts['national'] ?? '').trim();

    controller.phoneController.text = national;
    controller.fullPhoneNumber = normalized;

    if (dial.isNotEmpty) {
      try {
        (controller.selectedCountry as dynamic).dialCode = dial;
      } catch (_) {}
    }

    controller.refresh();

    appLog(
      'Phone applied => dial="$dial", national="$national", full="$normalized"',
    );
  }

  // -----------------------
  // Prefill Strategy (Singular)
  //
  // 1) Try GET /users/address/me (fills ALL fields)
  // 2) If personal fields still empty -> fallback GET /users/{id} for personal only
  // -----------------------
  Future<void> _prefillOnOpen() async {
    await _fetchAddressMePrefill();

    final personalStillEmpty =
        _isBlank(firstNameController.text) &&
        _isBlank(lastNameController.text) &&
        _isBlank(emailController.text) &&
        _isBlank(phoneController.phoneController.text);

    if (personalStillEmpty) {
      await _fetchUserPersonalFallback();
    }
  }

  Future<void> _fetchAddressMePrefill() async {
    if (_attemptedAddressMe) return;
    _attemptedAddressMe = true;

    setState(() {
      _loadingPrefill = true;
      _prefillError = null;
    });

    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');

      final headers = <String, dynamic>{
        if (token != null && token.toString().isNotEmpty)
          'Authorization': 'Bearer $token',
        if (guestId != null && guestId.toString().isNotEmpty)
          'x-guest-id': guestId,
      };

      final url = '${EndPoints.baseUrl}/users/address/me';
      appLog('GET: $url');
      appLog('headers keys: ${headers.keys.toList()}');

      final dio = sl<Dio>();
      final res = await dio.get(
        url,
        options: Options(headers: headers, responseType: ResponseType.plain),
      );

      appLog('statusCode: ${res.statusCode}');
      appLog('res.data runtimeType: ${res.data.runtimeType}');
      appLog('res.data snippet: ${_safeSnippet(res.data)}');

      final root = _asMap(res.data);
      final dataObj = root.containsKey('data') ? _asMap(root['data']) : root;

      final first = (dataObj['first_name'] ?? '').toString().trim();
      final last = (dataObj['last_name'] ?? '').toString().trim();
      final email = (dataObj['email'] ?? '').toString().trim();
      final phone = _normalizePhone((dataObj['phone'] ?? '').toString().trim());

      final address1 = (dataObj['address_1'] ?? '').toString().trim();
      final city = (dataObj['city'] ?? '').toString().trim();
      final state = (dataObj['state'] ?? '').toString().trim();
      final country = (dataObj['country'] ?? '').toString().trim();
      final postcode = (dataObj['postcode'] ?? '').toString().trim();

      // Personal
      _setIfBlank(firstNameController, first);
      _setIfBlank(lastNameController, last);
      _setIfBlank(emailController, email);
      if (phone.isNotEmpty && _isBlank(phoneController.phoneController.text)) {
        _applyPhoneToField(phoneController, phone);
      }

      // Shipping address (singular)
      _setIfBlank(address1Controller, address1);
      _setIfBlank(cityController, city);
      _setIfBlank(stateController, state);
      _setIfBlank(countryController, country);
      _setIfBlank(postcodeController, postcode.isEmpty ? '0000' : postcode);

      setState(() => _loadingPrefill = false);
    } catch (e, st) {
      appLog('Address/me prefill error: $e', stackTrace: st);
      _notifyBackendUnavailableIfNeeded(e);
      setState(() {
        _loadingPrefill = false;
        _prefillError = e.toString();
      });
    }
  }

  Future<void> _fetchUserPersonalFallback() async {
    if (_attemptedUserFallback) return;
    _attemptedUserFallback = true;

    setState(() {
      _loadingPrefill = true;
      _prefillError = null;
    });

    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');
      final userId = await sl<SecureCacheHelper>().getData(key: 'id');

      if (userId == null || userId.toString().trim().isEmpty) {
        throw Exception('Fallback aborted: userId is null/empty');
      }

      final headers = <String, dynamic>{
        if (token != null && token.toString().isNotEmpty)
          'Authorization': 'Bearer $token',
        if (guestId != null && guestId.toString().isNotEmpty)
          'x-guest-id': guestId,
      };

      final url = '${EndPoints.baseUrl}/users/$userId';
      appLog('GET: $url');

      final dio = sl<Dio>();
      final res = await dio.get(
        url,
        options: Options(headers: headers, responseType: ResponseType.plain),
      );

      final root = _asMap(res.data);
      final dataObj = root.containsKey('data') ? _asMap(root['data']) : root;

      final fullName =
          (dataObj['fullName'] ?? dataObj['full_name'] ?? dataObj['name'] ?? '')
              .toString()
              .trim();

      String first = (dataObj['first_name'] ?? '').toString().trim();
      String last = (dataObj['last_name'] ?? '').toString().trim();

      if (first.isEmpty && last.isEmpty && fullName.isNotEmpty) {
        final cleaned = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
        final parts = cleaned.split(' ');
        first = parts.isNotEmpty ? parts.first : '';
        last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final email = (dataObj['email'] ?? '').toString().trim();
      final phone = _normalizePhone(
        (dataObj['phone'] ?? dataObj['mobile'] ?? '').toString().trim(),
      );

      _setIfBlank(firstNameController, first);
      _setIfBlank(lastNameController, last);
      _setIfBlank(emailController, email);
      if (phone.isNotEmpty && _isBlank(phoneController.phoneController.text)) {
        _applyPhoneToField(phoneController, phone);
      }

      setState(() => _loadingPrefill = false);
    } catch (e, st) {
      appLog('User fallback prefill error: $e', stackTrace: st);
      _notifyBackendUnavailableIfNeeded(e);
      setState(() {
        _loadingPrefill = false;
        _prefillError = e.toString();
      });
    }
  }

  // -----------------------
  // Payload for address/update (ONLY allowed 9 fields)
  // -----------------------
  Map<String, dynamic> _buildUpdatePayload() {
    return {
      "first_name": firstNameController.text.trim(),
      "last_name": lastNameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.fullPhoneNumber.trim(),
      "address_1": address1Controller.text.trim(),
      "city": cityController.text.trim(),
      "state": stateController.text.trim(),
      "country": countryController.text.trim(),
      "postcode": _resolvedPostcode(postcodeController),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          CartSliverAppBar(title: S.of(context).address_confirmation),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingPrefill) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Loading address...',
                            style: AppStyle.styleRegular14(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_prefillError != null) ...[
                      Text(
                        'Couldn\'t load saved address automatically. Please enter it manually.',
                        style: AppStyle.styleRegular14(
                          context,
                        ).copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(height: 15.h),
                    Text(
                      S.of(context).personal_information,
                      style: AppStyle.styleRegular16(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 15.h),

                    CustomTextFormField(
                      hintText: _required(S.of(context).first_name),
                      controller: firstNameController,
                      inputFormatters: [
                        AppInputFormatters.fullNameNoSpecialCharacters,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_first_name;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      hintText: _required(S.of(context).last_name),
                      controller: lastNameController,
                      inputFormatters: [
                        AppInputFormatters.fullNameNoSpecialCharacters,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_last_name;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      hintText: _required(S.of(context).email),
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_email;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    CustomPhoneNumberField(
                      controller: phoneController,
                      hintText: _required(S.of(context).phone_Number),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_phone_number;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    Text(
                      S.of(context).shipping_address,
                      style: AppStyle.styleRegular16(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 15),

                    CustomTextFormField(
                      hintText: _required(S.of(context).address_1),
                      controller: address1Controller,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).please_enter_your_address;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    CountryStateCityWidget(
                      cityController: cityController,
                      stateController: stateController,
                      countryController: countryController,
                    ),
                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      hintText: S.of(context).postal_code,
                      controller: postcodeController,
                      inputFormatters: [AppInputFormatters.noEmoji],
                      validator: (_) => null,
                    ),

                    const SizedBox(height: 24),

                    BlocConsumer<UserAddressCubit, UserAddressState>(
                      listener: (context, state) {
                        if (state is UserAddressError) {
                          AppToast.show(
                            msg: state.message,
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                        }

                        if (state is UserAddressSaved) {
                          AppToast.show(
                            msg: S
                                .of(context)
                                .Shipping_address_added_successfully,
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                          );
                          GoRouter.of(
                            context,
                          ).goNamed(AppRouter.selectingFromBottomNavBar);
                        }
                      },
                      builder: (context, state) {
                        return CustomElevatedButton(
                          onPressed: state is UserAddressSaving
                              ? () {}
                              : () {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final payload = _buildUpdatePayload();

                                  context
                                      .read<UserAddressCubit>()
                                      .updateAddress(payload);
                                },
                          child: state is UserAddressSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  S.of(context).save,
                                  style: AppStyle.styleRegular15(
                                    context,
                                  ).copyWith(color: Colors.white),
                                ),
                        );
                      },
                    ),

                    SizedBox(height: 20.h),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

abstract class UserAddressState {}

class UserAddressInitial extends UserAddressState {}

class UserAddressSaving extends UserAddressState {}

class UserAddressSaved extends UserAddressState {}

class UserAddressError extends UserAddressState {
  final String message;
  UserAddressError(this.message);
}

class UserAddressCubit extends Cubit<UserAddressState> {
  final UserAddressRepo repo;

  UserAddressCubit(this.repo) : super(UserAddressInitial());

  Future<void> updateAddress(Map<String, dynamic> payload) async {
    emit(UserAddressSaving());
    try {
      await repo.updateAddress(payload);
      emit(UserAddressSaved());
    } catch (e) {
      if (e is DioException &&
          BackendUnavailableDetector.isBackendUnavailableDioException(e)) {
        BackendUnavailableNotifier.show();
      }
      emit(UserAddressError(e.toString()));
    }
  }
}

// user_address_repo.dar
class UserAddressRepo {
  final Dio dio;
  UserAddressRepo({Dio? dio}) : dio = dio ?? sl<Dio>();

  /// ✅ Send ONLY these fields (address/update accepts only these):
  /// first_name, last_name, email, phone, address_1, city, state, country, postcode
  Future<void> updateAddress(Map<String, dynamic> payload) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');

    final headers = <String, dynamic>{
      if (token != null && token.toString().isNotEmpty)
        'Authorization': 'Bearer $token',
      if (guestId != null && guestId.toString().isNotEmpty)
        'x-guest-id': guestId,
      'Content-Type': 'application/json',
    };

    // 🔁 Put your actual update endpoint here:
    final url = '${EndPoints.baseUrl}/users/address/update';

    Response res;
    try {
      res = await dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(headers: headers, responseType: ResponseType.plain),
      );
    } on DioException catch (error) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      rethrow;
    }

    if (res.statusCode == null ||
        (res.statusCode! < 200 || res.statusCode! >= 300)) {
      if (BackendUnavailableDetector.isBackendUnavailableStatusCode(
            res.statusCode,
          ) ||
          BackendUnavailableDetector.isBackendUnavailablePayload(res.data)) {
        BackendUnavailableNotifier.show();
      }
      throw Exception('Address update failed: ${res.statusCode} ${res.data}');
    }
  }
}
