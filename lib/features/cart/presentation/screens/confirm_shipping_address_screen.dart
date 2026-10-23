import 'dart:async';
import 'dart:convert';

import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/features/cart/presentation/widgets/checkout_flow_widgets.dart';
import 'package:camion/features/cart/presentation/widgets/checkout_method_logo.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/features/profile/data/models/get_user_model/user_model.dart';
import 'package:camion/features/profile/presentation/logic/cubit/get_user_cubit/get_user_cubit.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ConfirmShippingAddressScreen extends StatefulWidget {
  const ConfirmShippingAddressScreen({super.key, this.checkoutPayload});

  final Map<String, dynamic>? checkoutPayload;

  @override
  State<ConfirmShippingAddressScreen> createState() =>
      _ConfirmShippingAddressScreenState();
}

class _ConfirmShippingAddressScreenState
    extends State<ConfirmShippingAddressScreen> {
  static const int _fullNameMaxLength = 80;
  static const int _emailMaxLength = 254;
  static const int _phoneMaxLength = 15;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final PhoneNumberController phoneController = PhoneNumberController();

  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  bool _showAddNewAddress = false;
  bool _didBootstrap = false;
  String _lastSyncedFullName = '';
  String _lastSyncedEmail = '';
  String _lastSyncedCountryCode = '';
  String _lastSyncedPhoneNumber = '';

  CheckoutAddressOption? _selectedAddress;
  CheckoutShippingMethodOption? _selectedShippingMethod;

  AddressMeModel? _addressData;
  Map<String, dynamic>? _pendingNextPayload;
  bool _isOrderPreviewLoading = false;
  double? _previewShippingCost;
  _CheckoutAddressPaymentOption? _selectedPaymentMethod;
  late final List<_CheckoutAddressPaymentOption> _paymentMethods;

  bool _hasAnySavedAddress() =>
      (_addressData?.customerAddresses.isNotEmpty ?? false);

  bool _hasDefaultSavedAddress() =>
      _addressData?.customerAddresses.any((entry) => entry.isDefault) ?? false;

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

  String _tr(String en, String ar) => _isArabic ? ar : en;

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _showAddressRequiredMessage() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    AppToast.show(
      msg: isArabic
          ? 'الرجاء إضافة عنوان قبل المتابعة إلى الدفع.'
          : 'Please add an address before continuing to checkout.',
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  void initState() {
    super.initState();
    _paymentMethods = const <_CheckoutAddressPaymentOption>[
      _CheckoutAddressPaymentOption(id: 'mastercard', title: 'Master Card'),
      _CheckoutAddressPaymentOption(id: 'visa', title: 'Visa Card'),
      _CheckoutAddressPaymentOption(id: 'amex', title: 'American Express Card'),
      _CheckoutAddressPaymentOption(id: 'apple_pay', title: 'Apple Pay'),
      _CheckoutAddressPaymentOption(id: 'google_pay', title: 'Google Pay'),
      _CheckoutAddressPaymentOption(
        id: 'cod',
        title: 'Cash On Delivery',
        isDisabled: true,
      ),
    ];
    _selectedPaymentMethod = _resolveInitialPaymentMethod();
    _prefillFromLocalSaved();
    context.read<GetUserAddressCubit>().getUserAddress();
    context.read<GetUserCubit>().getUserById();
  }

  _CheckoutAddressPaymentOption? _resolveInitialPaymentMethod() {
    final raw = widget.checkoutPayload?['selectedPaymentMethod'];
    final selectedId = raw is Map
        ? (raw['id'] ?? '').toString().trim().toLowerCase()
        : '';
    if (selectedId.isEmpty) return null;
    return _paymentMethods.firstWhere(
      (method) => method.id == selectedId && !method.isDisabled,
      orElse: () => _CheckoutAddressPaymentOption.empty,
    );
  }

  List<String> _payloadCartItemUuids() {
    final raw = widget.checkoutPayload?['cartItemUuids'];
    if (raw is List) {
      return raw
          .map((uuid) => uuid.toString().trim())
          .where((uuid) => uuid.isNotEmpty)
          .toList();
    }
    final single = widget.checkoutPayload?['cartItemUuid']?.toString().trim();
    if (single != null && single.isNotEmpty) return <String>[single];
    return const <String>[];
  }

  Future<void> _loadOrderPreviewShipping({
    AddressMeModel? latestAddressModel,
  }) async {
    if (_isOrderPreviewLoading) return;

    if (latestAddressModel != null) {
      _addressData = latestAddressModel;
    }

    // Only fetch preview when a default address exists.
    if (!_hasDefaultSavedAddress()) {
      if (mounted && _previewShippingCost != null) {
        setState(() {
          _previewShippingCost = null;
          _isOrderPreviewLoading = false;
        });
      } else {
        _previewShippingCost = null;
      }
      return;
    }

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.trim().isEmpty) {
      return;
    }
    final couponCode =
        (widget.checkoutPayload?['appliedCouponCode']?.toString() ??
                widget.checkoutPayload?['couponCode']?.toString() ??
                '')
            .trim();
    if (!mounted) return;
    setState(() => _isOrderPreviewLoading = true);

    final result = await sl<OrderStatusRepository>().getOrderPreview(
      token: token,
      couponCode: couponCode.isEmpty ? null : couponCode,
      cartItemUuids: _payloadCartItemUuids(),
    );
    if (!mounted) return;

    result.fold(
      (_) {
        setState(() => _isOrderPreviewLoading = false);
      },
      (preview) {
        final shipping = preview.summary.shippingCost;
        setState(() {
          _previewShippingCost = shipping;
          _isOrderPreviewLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    address1Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postcodeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  TextStyle _sectionHeadingStyle() {
    return TextStyle(
      fontFamily: 'Montes',
      fontWeight: FontWeight.w400,
      fontSize: 20.sp,
      height: 24 / 20,
      color: Colors.black,
    );
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  void _setIfBlank(TextEditingController controller, String? value) {
    if (_isBlank(controller.text) && !_isBlank(value)) {
      controller.text = value!.trim();
    }
  }

  Map<String, String> _splitFullName(String fullName) {
    final cleaned = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return {'first': '', 'last': ''};
    final parts = cleaned.split(' ');
    if (parts.length == 1) return {'first': parts.first, 'last': ''};
    return {'first': parts.first, 'last': parts.sublist(1).join(' ')};
  }

  String _combineName(String firstName, String lastName) {
    return [
      firstName.trim(),
      lastName.trim(),
    ].where((item) => item.isNotEmpty).join(' ').trim();
  }

  String _normalizePhone(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[^\d\+]'), '');
    if (phone.isEmpty) return '';
    if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
    if (!phone.startsWith('+') && phone.startsWith('92')) phone = '+$phone';
    if (!phone.startsWith('+') && phone.startsWith('0') && phone.length >= 10) {
      phone = '+92${phone.substring(1)}';
    }
    return phone;
  }

  void _applyPhoneToField(PhoneNumberController controller, String? value) {
    final phone = _normalizePhone(value ?? '');
    if (phone.isEmpty) return;
    controller.fullPhoneNumber = phone;
    controller.refresh();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  void _prefillFromLocalSaved() {
    final cache = sl<CacheHelper>();
    _setIfBlank(
      fullNameController,
      cache.getDataString(key: 'checkoutFullName') ??
          cache.getDataString(key: 'userName'),
    );
    _setIfBlank(
      emailController,
      cache.getDataString(key: 'checkoutEmail') ??
          cache.getDataString(key: 'email'),
    );

    final savedPhone = cache.getDataString(key: 'checkoutPhone');
    if (_isBlank(phoneController.phoneController.text) &&
        !_isBlank(savedPhone)) {
      _applyPhoneToField(phoneController, savedPhone);
    }

    _setIfBlank(
      address1Controller,
      cache.getDataString(key: 'checkoutAddress1'),
    );
    _setIfBlank(cityController, cache.getDataString(key: 'checkoutCity'));
    _setIfBlank(stateController, cache.getDataString(key: 'checkoutState'));
    final savedPostcode = cache.getDataString(key: 'checkoutPostcode');
    _setIfBlank(
      postcodeController,
      (savedPostcode == null || savedPostcode.trim().isEmpty)
          ? '0000'
          : savedPostcode,
    );
    _setIfBlank(countryController, cache.getDataString(key: 'checkoutCountry'));
  }

  Future<void> _saveCheckoutDraftLocally(
    CheckoutAddress shippingAddress,
  ) async {
    final cache = sl<CacheHelper>();
    await cache.saveData(
      key: 'checkoutFullName',
      value: fullNameController.text.trim(),
    );
    await cache.saveData(
      key: 'checkoutEmail',
      value: emailController.text.trim(),
    );
    await cache.saveData(
      key: 'checkoutPhone',
      value: phoneController.fullPhoneNumber.trim(),
    );
    await cache.saveData(
      key: 'checkoutAddress1',
      value: shippingAddress.address1,
    );
    await cache.saveData(key: 'checkoutCity', value: shippingAddress.city);
    await cache.saveData(key: 'checkoutState', value: shippingAddress.state);
    await cache.saveData(
      key: 'checkoutPostcode',
      value: shippingAddress.postcode,
    );
    await cache.saveData(
      key: 'checkoutCountry',
      value: shippingAddress.country,
    );
  }

  Future<void> _updatePersonalProfileIfChanged() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phoneNumber = phoneController.phoneNumber.trim();
    final countryCode = phoneController.countryCode.trim();
    if (fullName.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty ||
        countryCode.isEmpty) {
      return;
    }

    final fullNameChanged = fullName != _lastSyncedFullName;
    final emailChanged = email != _lastSyncedEmail;
    final phoneChanged =
        countryCode != _lastSyncedCountryCode ||
        phoneNumber != _lastSyncedPhoneNumber;
    if (!fullNameChanged && !emailChanged && !phoneChanged) return;

    final token = (await sl<SecureCacheHelper>().getData(key: 'token'))?.trim();
    if (token == null || token.isEmpty) return;

    try {
      if (fullNameChanged || phoneChanged || emailChanged) {
        final data = <String, dynamic>{
          'fullName': fullName,
          'emailAddress': email,
          'countryCode': countryCode,
          'phoneNumber': phoneNumber,
        };

        await sl<Dio>().put(
          EndPoints.customerSelf,
          data: data,
          options: Options(
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            responseType: ResponseType.json,
          ),
        );
      }

      final normalizedFullPhone = phoneController.fullPhoneNumber.trim();
      final secureCache = sl<SecureCacheHelper>();
      final cache = sl<CacheHelper>();

      if (fullNameChanged) {
        await secureCache.saveData(key: 'userName', value: fullName);
        await cache.saveData(key: 'userName', value: fullName);
        _lastSyncedFullName = fullName;
      }
      if (emailChanged) {
        await secureCache.saveData(key: 'email', value: email);
        await cache.saveData(key: 'email', value: email);
        _lastSyncedEmail = email;
      }
      if (phoneChanged) {
        await secureCache.saveData(
          key: 'phoneNumber',
          value: normalizedFullPhone,
        );
        await secureCache.saveData(key: 'countryCode', value: countryCode);
        await cache.saveData(key: 'phoneNumber', value: normalizedFullPhone);
        await cache.saveData(key: 'countryCode', value: countryCode);
        _lastSyncedCountryCode = countryCode;
        _lastSyncedPhoneNumber = phoneNumber;
      }
    } catch (_) {
      // Keep checkout flow uninterrupted; explicit save/continue still works.
    }
  }

  void _applyProfileUser(GetUserModel user) {
    _setIfBlank(fullNameController, user.fullName);
    _setIfBlank(emailController, user.email);
    if (_isBlank(phoneController.phoneController.text)) {
      _applyPhoneToField(phoneController, user.phone);
    }
    if (user.fullName.trim().isNotEmpty) {
      _lastSyncedFullName = user.fullName.trim();
    }
    if (user.email.trim().isNotEmpty) {
      _lastSyncedEmail = user.email.trim();
    }
    final profilePhone = _normalizePhone(user.phone);
    final splitPhone = _splitPhoneAndCode(
      profilePhone,
      fallbackCountryCode: phoneController.countryCode.trim().isNotEmpty
          ? phoneController.countryCode.trim()
          : '+92',
    );
    if (splitPhone.phoneNumber.trim().isNotEmpty) {
      _lastSyncedCountryCode = splitPhone.countryCode.trim();
      _lastSyncedPhoneNumber = splitPhone.phoneNumber.trim();
    }
  }

  void _bootstrapFromAddress(AddressMeModel model) {
    _addressData = model;

    _setIfBlank(
      fullNameController,
      _combineName(model.firstName ?? '', model.lastName ?? ''),
    );
    _setIfBlank(emailController, model.email);
    if (_isBlank(phoneController.phoneController.text)) {
      _applyPhoneToField(phoneController, model.phone);
    }
    if (_lastSyncedFullName.isEmpty) {
      _lastSyncedFullName = _combineName(
        model.firstName ?? '',
        model.lastName ?? '',
      ).trim();
    }
    if (_lastSyncedEmail.isEmpty) {
      _lastSyncedEmail = (model.email ?? '').trim();
    }
    if (_lastSyncedPhoneNumber.isEmpty) {
      final splitPhone = _splitPhoneAndCode(
        _normalizePhone(model.phone ?? ''),
        fallbackCountryCode: phoneController.countryCode.trim().isNotEmpty
            ? phoneController.countryCode.trim()
            : '+92',
      );
      _lastSyncedCountryCode = splitPhone.countryCode.trim();
      _lastSyncedPhoneNumber = splitPhone.phoneNumber.trim();
    }

    final addresses = _buildAddressOptions(model);
    final methods = _buildShippingMethods(model);

    if (!_didBootstrap) {
      _didBootstrap = true;
      if (addresses.isNotEmpty) {
        _selectedAddress = addresses.firstWhere(
          (option) => option.isPrimary,
          orElse: () => addresses.first,
        );
        _fillAddressForm(_selectedAddress!);
      }
      if (methods.isNotEmpty) {
        _selectedShippingMethod = methods.firstWhere(
          (method) => method.isPrimary,
          orElse: () => methods.first,
        );
      }
    } else {
      if (_selectedAddress != null) {
        final match = addresses.where(
          (option) => option.id == _selectedAddress!.id,
        );
        if (match.isNotEmpty) {
          _selectedAddress = match.first;
          _fillAddressForm(_selectedAddress!);
        } else if (addresses.isNotEmpty) {
          _selectedAddress = addresses.firstWhere(
            (option) => option.isPrimary,
            orElse: () => addresses.first,
          );
          _fillAddressForm(_selectedAddress!);
        } else {
          _selectedAddress = null;
        }
      } else if (addresses.isNotEmpty) {
        _selectedAddress = addresses.firstWhere(
          (option) => option.isPrimary,
          orElse: () => addresses.first,
        );
        _fillAddressForm(_selectedAddress!);
      }
      if (_selectedShippingMethod != null) {
        final match = methods.where(
          (method) => method.id == _selectedShippingMethod!.id,
        );
        if (match.isNotEmpty) {
          _selectedShippingMethod = match.first;
        } else if (methods.isNotEmpty) {
          _selectedShippingMethod = methods.firstWhere(
            (method) => method.isPrimary,
            orElse: () => methods.first,
          );
        }
      }
    }
  }

  List<CheckoutAddressOption> _buildAddressOptions(AddressMeModel model) {
    final options = <CheckoutAddressOption>[];

    for (final entry in model.customerAddresses) {
      if (!entry.isDefault) continue;
      final nameParts = _splitFullName(entry.fullName);
      final normalizedPhone = [
        entry.countryCode.trim(),
        entry.phoneNumber.trim(),
      ].where((item) => item.isNotEmpty).join(' ').trim();

      options.add(
        CheckoutAddressOption(
          id: entry.uuid.isEmpty ? entry.streetAddress : entry.uuid,
          label: entry.isDefault
              ? _tr('Default address', 'العنوان الافتراضي')
              : _tr('Saved address', 'العنوان المحفوظ'),
          isPrimary: entry.isDefault,
          address: CheckoutAddress.fromPersonal(
            firstName: nameParts['first'],
            lastName: nameParts['last'],
            email: model.email,
            phone: normalizedPhone,
            address1: entry.streetAddress,
            address2: entry.apartment,
            city: entry.city,
            state: entry.state,
            postcode: entry.zipCode,
            country: entry.country,
          ),
        ),
      );
    }

    return options;
  }

  List<CheckoutShippingMethodOption> _buildShippingMethods(
    AddressMeModel model,
  ) {
    final payload = widget.checkoutPayload ?? const <String, dynamic>{};
    final previewShipping = _previewShippingCost;
    final payloadShipping = _toDouble(payload['shipping']);
    final modelShipping = model.shippingOption?.cost ?? 0;
    final resolvedShippingCost =
        previewShipping ??
        (payloadShipping > 0 ? payloadShipping : modelShipping);
    final serverTitle = model.shippingOption?.title.trim() ?? '';
    final fallbackTitle = _isArabic
        ? '4PX خدمة التوصيل'
        : '4PX Delivery Service';
    final shippingTitle = serverTitle.isNotEmpty ? serverTitle : fallbackTitle;

    return <CheckoutShippingMethodOption>[
      CheckoutShippingMethodOption(
        id: '4x-delivery-service',
        title: shippingTitle,
        cost: resolvedShippingCost,
        isPrimary: true,
      ),
    ];
  }

  void _fillAddressForm(CheckoutAddressOption option) {
    address1Controller.text = option.address.address1;
    cityController.text = option.address.city;
    stateController.text = option.address.state;
    postcodeController.text = option.address.postcode;
    countryController.text = option.address.country;
  }

  Future<void> _openAddAddressScreen() async {
    final result = await GoRouter.of(
      context,
    ).push<Map<String, dynamic>>(AppRouter.addAddress);

    if (!mounted) return;
    await context.read<GetUserAddressCubit>().getUserAddress();
    if (result == null) return;

    final isDefaultAddress =
        _toBool(result['isDefault']) ||
        _toBool(result['is_default']) ||
        _toBool(result['default']);

    final customOption = CheckoutAddressOption(
      id: (result['id'] ?? result['uuid'] ?? 'custom-address').toString(),
      label: isDefaultAddress
          ? _tr('Default address', 'العنوان الافتراضي')
          : _tr('Saved address', 'العنوان المحفوظ'),
      isPrimary: isDefaultAddress,
      address: CheckoutAddress.fromPersonal(
        firstName: _splitFullName(fullNameController.text)['first'],
        lastName: _splitFullName(fullNameController.text)['last'],
        email: emailController.text.trim(),
        phone: phoneController.fullPhoneNumber.trim(),
        address1: (result['streetAddress'] ?? result['address_1'] ?? '')
            .toString(),
        address2: (result['apartment'] ?? result['address_2'] ?? '').toString(),
        city: (result['city'] ?? '').toString(),
        state: (result['state'] ?? '').toString(),
        postcode: (result['zipCode'] ?? result['postcode'] ?? '').toString(),
        country: (result['country'] ?? '').toString(),
      ),
    );

    if (!isDefaultAddress) {
      setState(() {
        _showAddNewAddress = false;
        _selectedAddress = customOption;
        _fillAddressForm(customOption);
      });
      return;
    }

    setState(() {
      _showAddNewAddress = false;
      _selectedAddress = customOption;
      _fillAddressForm(customOption);
    });
  }

  Future<void> _openSelectAddressFlow({required bool hasSavedAddresses}) async {
    if (hasSavedAddresses) {
      await GoRouter.of(context).push(AppRouter.myAddresses);
      if (!mounted) return;
      await context.read<GetUserAddressCubit>().getUserAddress();
      return;
    }
    await _openAddAddressScreen();
  }

  CheckoutAddress _manualAddress() {
    final names = _splitFullName(fullNameController.text);
    return CheckoutAddress(
      firstName: names['first'] ?? '',
      lastName: names['last'] ?? '',
      email: emailController.text.trim(),
      phone: phoneController.fullPhoneNumber.trim(),
      address1: address1Controller.text.trim(),
      address2: '',
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      postcode: postcodeController.text.trim(),
      country: countryController.text.trim(),
    );
  }

  Future<void> _continue({required bool hasSavedAddresses}) async {
    final hasSelectedAddress =
        _selectedAddress?.address.hasUsableAddress == true;
    if (!hasSavedAddresses && !hasSelectedAddress) {
      await _openSelectAddressFlow(hasSavedAddresses: false);
      return;
    }
    if (!_hasAnySavedAddress()) {
      _showAddressRequiredMessage();
      await _openSelectAddressFlow(hasSavedAddresses: false);
      return;
    }
    if (!_hasDefaultSavedAddress()) {
      await _openSelectAddressFlow(hasSavedAddresses: true);
      return;
    }
    await _saveAndRoute();
  }

  Future<void> _saveAndRoute() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedAddress = _showAddNewAddress
        ? _manualAddress()
        : _selectedAddress?.address;
    if (selectedAddress == null || !selectedAddress.hasUsableAddress) {
      AppToast.show(
        msg: S.of(context).please_select_or_add_shipping_address,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final shippingMethod = _selectedShippingMethod;
    if (shippingMethod == null) {
      AppToast.show(
        msg: S.of(context).please_select_shipping_method,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final paymentMethod = _selectedPaymentMethod;
    if (paymentMethod == null || paymentMethod.id.isEmpty) {
      AppToast.show(
        msg: _tr(
          'Please select a payment method.',
          'الرجاء اختيار طريقة الدفع.',
        ),
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final subTotal = _toDouble(widget.checkoutPayload?['subTotal']);
    final itemsDiscount = _toDouble(widget.checkoutPayload?['itemsDiscount']);
    final couponDiscount = _toDouble(widget.checkoutPayload?['couponDiscount']);
    final discountTotal = _toDouble(widget.checkoutPayload?['discountTotal']);

    _pendingNextPayload = <String, dynamic>{
      ...?widget.checkoutPayload,
      'shipping': shippingMethod.cost,
      'total': (subTotal + shippingMethod.cost - itemsDiscount - couponDiscount)
          .clamp(0, double.infinity),
      'selectedShippingAddress': selectedAddress.toJson(),
      'selectedShippingMethod': shippingMethod.toJson(),
      'selectedPaymentMethod': paymentMethod.toJson(),
      'discountTotal': discountTotal,
    };

    await _saveCheckoutDraftLocally(selectedAddress);
    if (!mounted) return;
    final nextPayload = _pendingNextPayload;
    if (nextPayload != null) {
      unawaited(
        sl<AppsFlyerService>().logConversionEvent(
          'add_shipping_info',
          eventParams: {
            'shipping_method': shippingMethod.id,
            'payment_method': paymentMethod.id,
            'cart_value': nextPayload['total'] ?? 0,
            if ((nextPayload['couponCode'] ?? '').toString().trim().isNotEmpty)
              'coupon': nextPayload['couponCode'].toString().trim(),
          },
        ),
      );
      unawaited(
        sl<AppsFlyerService>().logConversionEvent(
          'add_payment_info',
          eventParams: {
            'payment_method': paymentMethod.id,
            'shipping_method': shippingMethod.id,
            'cart_value': nextPayload['total'] ?? 0,
          },
        ),
      );
      GoRouter.of(context).push(AppRouter.confirmPayment, extra: nextPayload);
    } else {
      GoRouter.of(context).pop();
    }
  }

  void _handleStepTap(int step) {
    if (step == 0) return;
    if (!_hasAnySavedAddress()) {
      _showAddressRequiredMessage();
      _openSelectAddressFlow(hasSavedAddresses: false);
      return;
    }
    if (!_hasDefaultSavedAddress()) {
      _openSelectAddressFlow(hasSavedAddresses: true);
      return;
    }
    _saveAndRoute();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final personalInfoState = context.watch<GetUserCubit>().state;
    final isPersonalInfoLoading =
        personalInfoState is GetUserInitial ||
        personalInfoState is GetUserLoading;
    final personalInfoError = personalInfoState is GetUserError
        ? personalInfoState.error.message
        : null;
    final addresses = _addressData == null
        ? <CheckoutAddressOption>[]
        : _buildAddressOptions(_addressData!);
    final hasSavedAddresses = _hasAnySavedAddress();
    final primaryCtaText = hasSavedAddresses ? s.continuee : s.add_new_address;
    final shippingMethods = _addressData == null
        ? _buildShippingMethods(const AddressMeModel())
        : _buildShippingMethods(_addressData!);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: BlocListener<GetUserCubit, GetUserState>(
          listener: (context, state) {
            if (state is GetUserLoaded) {
              _applyProfileUser(state.user);
            }
          },
          child: BlocConsumer<GetUserAddressCubit, GetUserAddressState>(
            listener: (context, state) {
              if (state is GetUserAddressSuccess) {
                _bootstrapFromAddress(state.data);
                _loadOrderPreviewShipping(latestAddressModel: state.data);
              }
            },
            builder: (context, addressState) {
              if (addressState is GetUserAddressSuccess) {
                _bootstrapFromAddress(addressState.data);
              }
              final isAddressLoading = addressState is GetUserAddressLoading;

              return BlocConsumer<
                SendUserShippingAddressCubit,
                SendUserShippingAddressState
              >(
                listener: (context, state) {
                  if (state is SendUserShippingAddressError) {
                    AppToast.show(
                      msg: state.error.toString(),
                      gravity: ToastGravity.TOP,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }

                  if (state is SendUserShippingAddressLoaded) {
                    AppToast.show(
                      msg: s.checkout_details_saved_successfully,
                      gravity: ToastGravity.TOP,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                    );

                    final nextPayload = _pendingNextPayload;
                    if (nextPayload != null) {
                      GoRouter.of(
                        context,
                      ).push(AppRouter.confirmPayment, extra: nextPayload);
                    } else {
                      GoRouter.of(context).pop();
                    }
                  }
                },
                builder: (context, saveState) {
                  final isSaving = saveState is SendUserShippingAddressLoading;

                  return Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverToBoxAdapter(child: SizedBox(height: 45.h)),
                            const CheckoutHeader(),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16.w,
                                  22.h,
                                  16.w,
                                  12.h,
                                ),
                                child: CheckoutStepper(
                                  currentStep: 0,
                                  onStepTap: _handleStepTap,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Form(
                                key: _formKey,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (isAddressLoading) ...[
                                        SizedBox(height: 8.h),
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              s.loading_saved_checkout_data,
                                              style: AppStyle.styleRegular15(
                                                context,
                                              ).copyWith(color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16.h),
                                      ],
                                      if (personalInfoError != null) ...[
                                        Text(
                                          s.could_not_auto_populate_personal_details,
                                          style: AppStyle.styleRegular15(
                                            context,
                                          ).copyWith(color: Colors.red),
                                        ),
                                        SizedBox(height: 14.h),
                                      ],
                                      Text(
                                        s.personal_information,
                                        style: _sectionHeadingStyle(),
                                      ),
                                      SizedBox(height: 22.h),
                                      if (isPersonalInfoLoading)
                                        const _PersonalInfoShimmer()
                                      else ...[
                                        _FieldLabel(s.full_name),
                                        SizedBox(height: 8.h),
                                        CustomTextFormField(
                                          controller: fullNameController,
                                          maxLines: 1,
                                          maxLength: _fullNameMaxLength,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) async {
                                            _dismissKeyboard();
                                            await _updatePersonalProfileIfChanged();
                                          },
                                          hintText:
                                              Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'مثال: أحمد محمد'
                                              : 'eg. Jack Daniels',
                                          inputFormatters: [
                                            AppInputFormatters
                                                .fullNameNoSpecialCharacters,
                                            LengthLimitingTextInputFormatter(
                                              _fullNameMaxLength,
                                            ),
                                          ],
                                          validator: (value) => _isBlank(value)
                                              ? 'Please enter your full name'
                                              : null,
                                        ),
                                        SizedBox(height: 18.h),
                                        _FieldLabel(s.email_address),
                                        SizedBox(height: 8.h),
                                        CustomTextFormField(
                                          controller: emailController,
                                          maxLines: 1,
                                          maxLength: _emailMaxLength,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) async {
                                            _dismissKeyboard();
                                            await _updatePersonalProfileIfChanged();
                                          },
                                          hintText:
                                              Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'مثال: ahmed@gmail.com'
                                              : 'eg. jack.daniels@gmail.com',
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(
                                              RegExp(r'\s'),
                                            ),
                                            LengthLimitingTextInputFormatter(
                                              _emailMaxLength,
                                            ),
                                          ],
                                          validator: (value) => _isBlank(value)
                                              ? s.please_enter_your_email
                                              : null,
                                        ),
                                        SizedBox(height: 18.h),
                                        _FieldLabel(s.phone_Number),
                                        SizedBox(height: 8.h),
                                        CustomPhoneNumberField(
                                          controller: phoneController,
                                          hintText: '12345678910',
                                          maxLength: _phoneMaxLength,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              _phoneMaxLength,
                                            ),
                                          ],
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) async {
                                            _dismissKeyboard();
                                            await _updatePersonalProfileIfChanged();
                                          },
                                          validator: (value) => _isBlank(value)
                                              ? s.please_enter_your_phone_number
                                              : null,
                                        ),
                                      ],
                                      SizedBox(height: 34.h),
                                      Text(
                                        s.shipping_address,
                                        style: _sectionHeadingStyle(),
                                      ),
                                      SizedBox(height: 18.h),
                                      if (addresses.isNotEmpty)
                                        ...addresses.map(
                                          (option) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 12.h,
                                            ),
                                            child: _SelectableAddressCard(
                                              option: option,
                                              isSelected:
                                                  !_showAddNewAddress &&
                                                  _selectedAddress?.id ==
                                                      option.id,
                                              onTap: () {
                                                setState(() {
                                                  _showAddNewAddress = false;
                                                  _selectedAddress = option;
                                                  _fillAddressForm(option);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      OutlinedButton(
                                        onPressed: () => _openSelectAddressFlow(
                                          hasSavedAddresses: hasSavedAddresses,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: Size(
                                            double.infinity,
                                            50.h,
                                          ),
                                          side: BorderSide(
                                            color: _showAddNewAddress
                                                ? AppColors.primaryColor
                                                : Colors.grey.shade300,
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'اختر عنوانًا'
                                              : 'Select address',
                                          style: AppStyle.styleRegular15(
                                            context,
                                          ).copyWith(color: Colors.black),
                                        ),
                                      ),
                                      SizedBox(height: 34.h),
                                      Text(
                                        s.shipping_method,
                                        style: _sectionHeadingStyle(),
                                      ),
                                      if (_isOrderPreviewLoading) ...[
                                        SizedBox(height: 8.h),
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Fetching shipping fee from order preview...',
                                              style: AppStyle.styleRegular12(
                                                context,
                                              ).copyWith(color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ],
                                      SizedBox(height: 18.h),
                                      ...shippingMethods.map(
                                        (method) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 12.h,
                                          ),
                                          child: _ShippingMethodCard(
                                            method: method,
                                            isSelected:
                                                _selectedShippingMethod?.id ==
                                                method.id,
                                            onTap: () {
                                              setState(() {
                                                _selectedShippingMethod =
                                                    method;
                                              });
                                              unawaited(
                                                sl<AppsFlyerService>()
                                                    .logConversionEvent(
                                                      'add_shipping_info',
                                                      eventParams: {
                                                        'shipping_method':
                                                            method.id,
                                                        'cart_value':
                                                            widget
                                                                .checkoutPayload?['total'] ??
                                                            0,
                                                      },
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 22.h),
                                      Text(
                                        s.payment_method,
                                        style: _sectionHeadingStyle(),
                                      ),
                                      SizedBox(height: 18.h),
                                      ..._paymentMethods.map(
                                        (method) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 12.h,
                                          ),
                                          child: _AddressPaymentMethodCard(
                                            method: method,
                                            isSelected:
                                                _selectedPaymentMethod?.id ==
                                                method.id,
                                            onTap: () {
                                              if (method.isDisabled) {
                                                unawaited(
                                                  sl<AppsFlyerService>()
                                                      .logConversionEvent(
                                                        'cod_interest_click',
                                                        eventParams: {
                                                          'source':
                                                              'confirm_shipping_address',
                                                        },
                                                      ),
                                                );
                                                return;
                                              }

                                              setState(() {
                                                _selectedPaymentMethod = method;
                                              });
                                              unawaited(
                                                sl<AppsFlyerService>()
                                                    .logConversionEvent(
                                                      'payment_method_selected',
                                                      eventParams: {
                                                        'payment_method':
                                                            method.id,
                                                        'cart_value':
                                                            widget
                                                                .checkoutPayload?['total'] ??
                                                            0,
                                                      },
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 28.h),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
                        color: AppColors.primaryColor,
                        child: CustomElevatedButton(
                          onPressed: isSaving
                              ? () {}
                              : () => _continue(
                                  hasSavedAddresses: hasSavedAddresses,
                                ),
                          backgroundColor: AppColors.primaryColor,
                          elevation: 0,
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  primaryCtaText,
                                  style: AppStyle.styleRegular15(context)
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppStyle.styleRegular15(
        context,
      ).copyWith(color: Colors.black, fontSize: 16.sp),
    );
  }
}

class _PersonalInfoShimmer extends StatelessWidget {
  const _PersonalInfoShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9E9E9),
      highlightColor: const Color(0xFFF7F7F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerLabel(),
          SizedBox(height: 8.h),
          _shimmerField(),
          SizedBox(height: 18.h),
          _shimmerLabel(),
          SizedBox(height: 8.h),
          _shimmerField(),
          SizedBox(height: 18.h),
          _shimmerLabel(),
          SizedBox(height: 8.h),
          _shimmerField(),
        ],
      ),
    );
  }

  Widget _shimmerLabel() {
    return Container(
      width: 110.w,
      height: 14.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }

  Widget _shimmerField() {
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }
}

class _SelectableAddressCard extends StatelessWidget {
  const _SelectableAddressCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final CheckoutAddressOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: AppStyle.styleRegular15(
                context,
              ).copyWith(color: Colors.black87),
            ),
            SizedBox(height: 10.h),
            Text(
              option.address.primaryLine,
              style: AppStyle.styleRegular15(
                context,
              ).copyWith(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            if (option.address.secondaryLine.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                option.address.secondaryLine,
                style: AppStyle.styleRegular15(
                  context,
                ).copyWith(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShippingMethodCard extends StatelessWidget {
  const _ShippingMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final CheckoutShippingMethodOption method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        height: 40.h,
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            CheckoutMethodLogoBox(
              id: method.id,
              title: method.title,
              type: CheckoutMethodLogoType.shipping,
              width: 52.w,
              height: 24.h,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                method.title,
                style: AppStyle.styleRegular15(
                  context,
                ).copyWith(color: Colors.black, fontSize: 16.sp),
              ),
            ),
            Text(
              _formatCost(method.cost),
              style: AppStyle.styleRegular15(
                context,
              ).copyWith(color: Colors.black54, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost == cost.roundToDouble()) {
      return '${cost.toStringAsFixed(0)}.00';
    }
    return cost.toStringAsFixed(2);
  }
}

class _AddressPaymentMethodCard extends StatelessWidget {
  const _AddressPaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final _CheckoutAddressPaymentOption method;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = method.isDisabled;
    final title = method.id == 'cod'
        ? S.of(context).cash_on_delivery
        : method.title;
    final titleColor = disabled ? Colors.black54 : Colors.black;
    final borderColor = disabled
        ? Colors.grey.shade300
        : isSelected
        ? AppColors.primaryColor
        : Colors.grey.shade300;
    final backgroundColor = disabled
        ? Colors.grey.shade50
        : isSelected
        ? AppColors.primaryColor.withAlpha(15)
        : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        height: 56.h,
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: borderColor,
            width: isSelected && !disabled ? 1.2 : 1,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.7 : 1,
          child: Row(
            children: [
              CheckoutMethodLogoBox(
                id: method.id,
                title: method.title,
                type: CheckoutMethodLogoType.payment,
                width: 64.w,
                height: 34.h,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: AppStyle.styleRegular15(
                      context,
                    ).copyWith(color: titleColor, fontSize: 16.sp),
                    children: [
                      if (disabled)
                        TextSpan(
                          text: ' (${S.of(context).coming_soon})',
                          style: AppStyle.styleRegular15(context).copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: Directionality.of(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutAddressPaymentOption {
  const _CheckoutAddressPaymentOption({
    required this.id,
    required this.title,
    this.isDisabled = false,
  });

  static const empty = _CheckoutAddressPaymentOption(id: '', title: '');

  final String id;
  final String title;
  final bool isDisabled;

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'title': title};

  String get badgeLabel {
    switch (id) {
      case 'mastercard':
        return 'MC';
      case 'visa':
        return 'VISA';
      case 'amex':
        return 'AMEX';
      case 'apple_pay':
        return 'Apple';
      case 'google_pay':
        return 'G Pay';
      default:
        return 'CARD';
    }
  }

  Color get badgeColor {
    switch (id) {
      case 'visa':
        return const Color(0xFF1D3C8F);
      case 'amex':
        return const Color(0xFF2D6FC3);
      case 'mastercard':
        return const Color(0xFFE4572E);
      default:
        return Colors.black;
    }
  }
}

class CheckoutAddressOption {
  const CheckoutAddressOption({
    required this.id,
    required this.label,
    required this.address,
    this.isPrimary = false,
  });

  final String id;
  final String label;
  final CheckoutAddress address;
  final bool isPrimary;
}

class CheckoutShippingMethodOption {
  const CheckoutShippingMethodOption({
    required this.id,
    required this.title,
    required this.cost,
    this.isPrimary = false,
  });

  final String id;
  final String title;
  final double cost;
  final bool isPrimary;

  String get shortLabel {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final parts = words
        .take(2)
        .map((word) => word.characters.first.toUpperCase());
    final label = parts.join();
    return label.isEmpty ? 'CM' : label;
  }

  Map<String, dynamic> toJson() {
    return {'method_id': id, 'title': title, 'cost': cost.toStringAsFixed(2)};
  }
}

class CheckoutAddress {
  static const String _defaultPostcode = '0000';

  const CheckoutAddress({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  const CheckoutAddress.empty()
    : firstName = '',
      lastName = '',
      email = '',
      phone = '',
      address1 = '',
      address2 = '',
      city = '',
      state = '',
      postcode = _defaultPostcode,
      country = '';

  factory CheckoutAddress.fromPersonal({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    String? country,
  }) {
    return CheckoutAddress(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      email: email ?? '',
      phone: phone ?? '',
      address1: address1 ?? '',
      address2: address2 ?? '',
      city: city ?? '',
      state: state ?? '',
      postcode: _normalizePostcode(postcode ?? ''),
      country: country ?? '',
    );
  }

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  static String _normalizePostcode(String value) {
    final text = value.trim();
    return text.isEmpty ? _defaultPostcode : text;
  }

  bool get hasUsableAddress =>
      address1.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      country.trim().isNotEmpty;

  String get primaryLine {
    final parts = [address1, address2].where((item) => item.trim().isNotEmpty);
    return parts.isEmpty ? 'Address' : parts.join(', ');
  }

  String get secondaryLine {
    final parts = [
      city,
      state,
      postcode,
      country,
    ].where((item) => item.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': _normalizePostcode(postcode),
      'country': country,
    };
  }
}

class ShippingOptionData {
  const ShippingOptionData({
    required this.methodId,
    required this.title,
    required this.cost,
  });

  final String methodId;
  final String title;
  final double cost;

  factory ShippingOptionData.fromJson(Map<String, dynamic> json) {
    return ShippingOptionData(
      methodId: (json['method_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['method_title'] ?? '').toString(),
      cost: _ShippingOptionParsing.toDouble(json['cost']),
    );
  }
}

abstract class _ShippingOptionParsing {
  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class AddressMeModel {
  const AddressMeModel({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.country,
    this.postcode,
    this.shippingAddress = const CheckoutAddress.empty(),
    this.shippingOption,
    this.customerAddresses = const [],
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;
  final CheckoutAddress shippingAddress;
  final ShippingOptionData? shippingOption;
  final List<CustomerAddressData> customerAddresses;

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory AddressMeModel.fromJson(dynamic raw) {
    final map = _safeRoot(raw);
    final shippingAddressMap = _safeRoot(map['shipping_address']);
    final shippingOptionMap = _safeRoot(map['shipping_option']);

    return AddressMeModel(
      firstName: _string(map['first_name']),
      lastName: _string(map['last_name']),
      email: _string(map['email']),
      phone: _string(map['phone']),
      address1: _string(map['address_1']),
      address2: _string(map['address_2']),
      city: _string(map['city']),
      state: _string(map['state']),
      country: _string(map['country']),
      postcode: _string(map['postcode']),
      shippingAddress: shippingAddressMap.isEmpty
          ? const CheckoutAddress.empty()
          : CheckoutAddress.fromPersonal(
              firstName: _string(shippingAddressMap['first_name']),
              lastName: _string(shippingAddressMap['last_name']),
              email: _string(shippingAddressMap['email']),
              phone: _string(shippingAddressMap['phone']),
              address1: _string(shippingAddressMap['address_1']),
              address2: _string(shippingAddressMap['address_2']),
              city: _string(shippingAddressMap['city']),
              state: _string(shippingAddressMap['state']),
              postcode: _string(shippingAddressMap['postcode']),
              country: _string(shippingAddressMap['country']),
            ),
      shippingOption: shippingOptionMap.isEmpty
          ? null
          : ShippingOptionData.fromJson(shippingOptionMap),
    );
  }

  factory AddressMeModel.fromCustomerAddresses(dynamic raw) {
    final rawList = _extractAddressList(raw);
    final addresses = rawList
        .map((item) => CustomerAddressData.fromJson(_safeRoot(item)))
        .where((item) => item.hasMinimumAddress)
        .toList(growable: false);

    return AddressMeModel(customerAddresses: addresses);
  }

  static List<dynamic> _extractAddressList(dynamic raw) {
    if (raw is List) return raw;
    final map = _safeRoot(raw);
    const keys = ['data', 'results', 'addresses', 'items', 'nodes'];
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return const [];
  }

  static Map<String, dynamic> _safeRoot(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String) {
      try {
        return _safeRoot(jsonDecode(raw));
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }
}

class CustomerAddressData {
  static const String _defaultZipCode = '0000';

  const CustomerAddressData({
    required this.uuid,
    required this.fullName,
    required this.countryCode,
    required this.phoneNumber,
    required this.streetAddress,
    required this.apartment,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.country,
    required this.isDefault,
  });

  final String uuid;
  final String fullName;
  final String countryCode;
  final String phoneNumber;
  final String streetAddress;
  final String apartment;
  final String zipCode;
  final String city;
  final String state;
  final String country;
  final bool isDefault;

  static String _normalizeZipCode(String value) {
    final text = value.trim();
    return text.isEmpty ? _defaultZipCode : text;
  }

  bool get hasMinimumAddress =>
      streetAddress.trim().isNotEmpty ||
      city.trim().isNotEmpty ||
      state.trim().isNotEmpty ||
      country.trim().isNotEmpty;

  factory CustomerAddressData.fromJson(Map<String, dynamic> map) {
    final rawPhone = (map['phoneNumber'] ?? map['phone'] ?? '')
        .toString()
        .trim();
    final declaredCode = (map['countryCode'] ?? map['country_code'] ?? '')
        .toString()
        .trim();
    final split = _splitPhoneAndCode(
      rawPhone,
      fallbackCountryCode: declaredCode,
    );

    return CustomerAddressData(
      uuid: (map['uuid'] ?? map['id'] ?? '').toString().trim(),
      fullName: (map['fullName'] ?? map['full_name'] ?? 'Address User')
          .toString()
          .trim(),
      countryCode: split.countryCode,
      phoneNumber: split.phoneNumber,
      streetAddress: (map['streetAddress'] ?? map['address_1'] ?? '')
          .toString()
          .trim(),
      apartment: (map['apartment'] ?? map['address_2'] ?? '').toString().trim(),
      zipCode: _normalizeZipCode(
        (map['zipCode'] ?? map['postcode'] ?? '').toString(),
      ),
      city: (map['city'] ?? '').toString().trim(),
      state: (map['state'] ?? '').toString().trim(),
      country: (map['country'] ?? '').toString().trim(),
      isDefault: _toBool(
        map['isDefault'] ?? map['is_default'] ?? map['default'] ?? false,
      ),
    );
  }
}

abstract class GetUserAddressState {}

class GetUserAddressInitial extends GetUserAddressState {}

class GetUserAddressLoading extends GetUserAddressState {}

class GetUserAddressSuccess extends GetUserAddressState {
  GetUserAddressSuccess(this.data);

  final AddressMeModel data;
}

class GetUserAddressError extends GetUserAddressState {
  GetUserAddressError(this.error);

  final dynamic error;
}

class GetUserAddressCubit extends Cubit<GetUserAddressState> {
  GetUserAddressCubit(this.repo) : super(GetUserAddressInitial());

  final GetUserAddressRepo repo;

  Future<void> getUserAddress() async {
    emit(GetUserAddressLoading());
    try {
      emit(GetUserAddressSuccess(await repo.getAddressMe()));
    } catch (error) {
      emit(GetUserAddressError(error));
    }
  }
}

class GetUserAddressRepo {
  GetUserAddressRepo({Dio? dio}) : dio = dio ?? sl<Dio>();

  final Dio dio;

  Future<AddressMeModel> getAddressMe() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');

    Response res;
    try {
      res = await dio.get(
        EndPoints.customerAddresses,
        options: Options(
          headers: {
            if (!_isValueBlank(token)) 'Authorization': 'Bearer $token',
            if (!_isValueBlank(guestId)) 'x-guest-id': guestId,
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );
    } on DioException catch (error) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      rethrow;
    }

    final statusCode = res.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      if (BackendUnavailableDetector.isBackendUnavailableStatusCode(
            statusCode,
          ) ||
          BackendUnavailableDetector.isBackendUnavailablePayload(res.data)) {
        BackendUnavailableNotifier.show();
        throw Exception('Server not responding. Please try again.');
      }
      throw Exception('Could not load your addresses right now.');
    }
    return AddressMeModel.fromCustomerAddresses(res.data);
  }

  bool _isValueBlank(dynamic value) =>
      value == null || value.toString().trim().isEmpty;
}

abstract class SendUserShippingAddressState {}

class SendUserShippingAddressInitial extends SendUserShippingAddressState {}

class SendUserShippingAddressLoading extends SendUserShippingAddressState {}

class SendUserShippingAddressLoaded extends SendUserShippingAddressState {}

class SendUserShippingAddressError extends SendUserShippingAddressState {
  SendUserShippingAddressError(this.error);

  final dynamic error;
}

class SendUserShippingAddressCubit extends Cubit<SendUserShippingAddressState> {
  SendUserShippingAddressCubit(this.repo)
    : super(SendUserShippingAddressInitial());

  final SendUserShippingAddressRepo repo;

  Future<void> updateAddress(Map<String, dynamic> payload) async {
    emit(SendUserShippingAddressLoading());
    try {
      await repo.updateAddress(payload);
      emit(SendUserShippingAddressLoaded());
    } catch (error) {
      emit(SendUserShippingAddressError(error));
    }
  }
}

class SendUserShippingAddressRepo {
  SendUserShippingAddressRepo({Dio? dio}) : dio = dio ?? sl<Dio>();

  final Dio dio;

  Future<void> updateAddress(Map<String, dynamic> payload) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final guestId = await sl<SecureCacheHelper>().getData(key: 'x-guest-id');

    Response res;
    try {
      res = await dio.post(
        '${EndPoints.baseUrl}/users/address/update',
        data: jsonEncode(payload),
        options: Options(
          headers: {
            if (!_isValueBlank(token)) 'Authorization': 'Bearer $token',
            if (!_isValueBlank(guestId)) 'x-guest-id': guestId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (error) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      rethrow;
    }

    final statusCode = res.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      if (BackendUnavailableDetector.isBackendUnavailableStatusCode(
            statusCode,
          ) ||
          BackendUnavailableDetector.isBackendUnavailablePayload(res.data)) {
        BackendUnavailableNotifier.show();
        throw Exception('Server not responding. Please try again.');
      }
      throw Exception(_extractApiMessage(res.data) ?? 'Address update failed.');
    }

    final body = _safeBody(res.data);
    final successFlag = body['success'] ?? body['ok'];
    final statusText = body['status']?.toString().trim().toLowerCase();
    final notSuccessful =
        (successFlag is bool && !successFlag) ||
        statusText == 'error' ||
        statusText == 'failed' ||
        statusText == 'fail';
    if (notSuccessful) {
      throw Exception(_extractApiMessage(body) ?? 'Address update failed.');
    }
  }

  bool _isValueBlank(dynamic value) =>
      value == null || value.toString().trim().isEmpty;

  Map<String, dynamic> _safeBody(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return _safeBody(decoded);
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  String? _extractApiMessage(dynamic raw) {
    final body = _safeBody(raw);
    final direct = body['message']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final error = body['error']?.toString().trim();
    if (error != null && error.isNotEmpty) return error;
    final nested = _safeBody(body['data'])['message']?.toString().trim();
    if (nested != null && nested.isNotEmpty) return nested;
    return null;
  }
}

class _ParsedPhonePieces {
  const _ParsedPhonePieces({
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;
}

_ParsedPhonePieces _splitPhoneAndCode(
  String rawPhone, {
  required String fallbackCountryCode,
}) {
  final cleaned = rawPhone.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) {
    return _ParsedPhonePieces(
      countryCode: fallbackCountryCode,
      phoneNumber: '',
    );
  }
  if (!cleaned.startsWith('+')) {
    return _ParsedPhonePieces(
      countryCode: fallbackCountryCode,
      phoneNumber: cleaned,
    );
  }
  final parts = cleaned.split(' ');
  final code = parts.first.trim();
  if (parts.length > 1) {
    return _ParsedPhonePieces(
      countryCode: code,
      phoneNumber: parts.sublist(1).join(' ').trim(),
    );
  }
  return _ParsedPhonePieces(countryCode: code, phoneNumber: cleaned);
}

bool _toBool(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final value = raw?.toString().trim().toLowerCase();
  return value == 'true' || value == '1' || value == 'yes';
}
