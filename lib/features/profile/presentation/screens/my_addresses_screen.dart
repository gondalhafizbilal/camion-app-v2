import 'dart:convert';

import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/location_name_localizer.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/auth/utils/country_code_normalizer.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  final _repo = _MyAddressesRepo();

  bool _loading = true;
  bool _saving = false;
  String? _pendingDefaultAddressId;
  String? _pendingDeleteAddressId;
  List<_AddressEntry> _addresses = const [];

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

  String _tr(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);

    try {
      await LocationNameLocalizer.ensureLoaded();
      final payload = await _repo.getAddresses();
      final addresses = payload
          .whereType<Map<String, dynamic>>()
          .map(_AddressEntry.fromMap)
          .where((item) => item.hasMinimumAddress)
          .toList();

      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _loading = false;
        _pendingDefaultAddressId = null;
        _pendingDeleteAddressId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addresses = const [];
        _loading = false;
      });
      _showError(
        _tr(
          'Could not load your addresses right now.',
          'تعذر تحميل عناوينك حالياً.',
        ),
      );
    }
  }

  Future<void> _onAdd() async {
    final result = await context.push<Map<String, dynamic>>(
      AppRouter.addAddress,
    );
    if (result == null || !mounted) return;
    await _loadAddresses();
  }

  Future<void> _onEdit(int index) async {
    final target = _addresses[index];
    final result = await context.push<Map<String, dynamic>>(
      AppRouter.addAddress,
      extra: target.toFormMap(),
    );
    if (result == null || !mounted) return;
    await _loadAddresses();
  }

  Future<void> _onToggleDefault(int index, bool nextValue) async {
    if (_saving) return;

    final target = _addresses[index];
    if (target.id.trim().isEmpty) {
      _showError(
        _tr(
          'Could not update default address right now.',
          'تعذر تحديث العنوان الافتراضي حالياً.',
        ),
      );
      return;
    }
    if (target.isDefault == nextValue) return;
    final mustPromoteAnother = target.isDefault && !nextValue;
    _AddressEntry? fallbackDefault;
    if (mustPromoteAnother) {
      fallbackDefault = _addresses.cast<_AddressEntry?>().firstWhere(
        (address) => address != null && address.id != target.id,
        orElse: () => null,
      );
      if (fallbackDefault == null) {
        _showError(
          _tr(
            'At least one address must remain default.',
            'يجب أن يبقى عنوان واحد افتراضياً على الأقل.',
          ),
        );
        return;
      }
    }

    final previousAddresses = List<_AddressEntry>.from(_addresses);
    final previousPending = _pendingDefaultAddressId;

    setState(() {
      _saving = true;
      _pendingDefaultAddressId = mustPromoteAnother
          ? fallbackDefault?.id
          : target.id;
      if (nextValue) {
        _addresses = _addresses
            .map(
              (address) => address.copyWith(isDefault: address.id == target.id),
            )
            .toList();
      } else {
        _addresses = _addresses
            .map(
              (address) => address.copyWith(
                isDefault: address.id == fallbackDefault?.id,
              ),
            )
            .toList();
      }
    });
    try {
      if (mustPromoteAnother) {
        await _repo.patchAddress(
          id: fallbackDefault!.id,
          payload: const <String, dynamic>{'isDefault': true},
        );
      } else {
        await _repo.patchAddress(
          id: target.id,
          payload: <String, dynamic>{'isDefault': nextValue},
        );
      }
      await _loadAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mustPromoteAnother
                ? _tr(
                    'Another address was set as default automatically.',
                    'تم تعيين عنوان آخر كافتراضي تلقائياً.',
                  )
                : nextValue
                ? _tr(
                    'Default address updated successfully.',
                    'تم تحديث العنوان الافتراضي بنجاح.',
                  )
                : _tr(
                    'Address default removed successfully.',
                    'تمت إزالة العنوان الافتراضي بنجاح.',
                  ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _addresses = previousAddresses;
        _pendingDefaultAddressId = previousPending;
      });
      _showError(
        _friendlyApiError(
          error,
          fallback: _tr(
            'Could not update default address right now.',
            'تعذر تحديث العنوان الافتراضي حالياً.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onDeleteAddress(int index) async {
    if (_saving) return;

    if (_addresses.length <= 1) {
      _showError(
        _tr(
          'You cannot delete your only saved address.',
          'لا يمكنك حذف العنوان الوحيد المحفوظ لديك.',
        ),
      );
      return;
    }

    final target = _addresses[index];
    if (target.isDefault) {
      _showError(
        _tr(
          'Default address cannot be deleted. Please set another address as default first.',
          'لا يمكن حذف العنوان الافتراضي. يرجى تعيين عنوان آخر كافتراضي أولاً.',
        ),
      );
      return;
    }
    if (target.id.trim().isEmpty) {
      _showError(
        _tr('Could not delete address right now.', 'تعذر حذف العنوان حالياً.'),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'حذف العنوان'
                : 'Delete address',
          ),
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'هل أنت متأكد أنك تريد حذف هذا العنوان؟'
                : 'Are you sure you want to delete this address?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'إلغاء'
                    : 'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'حذف'
                    : 'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _pendingDeleteAddressId = target.id;
    });
    try {
      await _repo.deleteAddress(id: target.id);
      await _loadAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تم حذف العنوان بنجاح.'
                : 'Address deleted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(
        _friendlyApiError(
          error,
          fallback: _tr(
            'Could not delete address right now.',
            'تعذر حذف العنوان حالياً.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _pendingDeleteAddressId = null;
        });
      }
    }
  }

  String _friendlyApiError(Object error, {required String fallback}) {
    if (error is DioException) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      final status = error.response?.statusCode;
      if (status != null && status >= 500) {
        return 'Server not responding. Please try again.';
      }
      final data = _asMap(error.response?.data);
      final message =
          data['message']?.toString().trim() ??
          data['error']?.toString().trim() ??
          error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final text = error.toString().trim();
    if (text.startsWith('Exception:')) {
      final message = text.replaceFirst('Exception:', '').trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CustomSliverAppBar(
              appBarHeight: 50.h,
              centerTitle: false,
              leading: GestureDetector(
                onTap: () {
                  AppNavigator.safePop(
                    context,
                    fallbackRoute:
                        '${AppRouter.selectingFromBottomNavBar}?tab=4',
                  );
                },
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.black,
                  size: 24.sp,
                ),
              ),
              title: Text(
                _tr('My Addresses', 'عناويني'),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w500,
                  height: 2,
                ),
              ),
              actions: const [],
              isShoppingCartShown: false,
              isShownActions: false,
              isShownDivider: false,
            ),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            if (_loading)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: const _AddressesShimmerSliver(itemCount: 3),
              )
            else if (_addresses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 48.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _tr('No addresses yet', 'لا توجد عناوين بعد'),
                        style: AppStyle.styleSectionTitle16Medium(
                          context,
                        ).copyWith(color: Colors.black),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _tr(
                          'Add your first address to continue checkout faster.',
                          'أضف عنوانك الأول لإتمام الدفع بشكل أسرع.',
                        ),
                        textAlign: TextAlign.center,
                        style: AppStyle.styleRegular15(
                          context,
                        ).copyWith(color: Colors.black54),
                      ),
                      SizedBox(height: 22.h),
                      SizedBox(
                        width: double.infinity,
                        child: CustomElevatedButton(
                          onPressed: _saving ? () {} : _onAdd,
                          backgroundColor: AppColors.primaryColor,
                          child: Text(
                            _tr('Add Address', 'إضافة عنوان'),
                            style: AppStyle.styleRegular15(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverList.separated(
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return _AddressCard(
                      address: address,
                      saving: _saving,
                      isUpdatingDefault:
                          _pendingDefaultAddressId != null &&
                          _pendingDefaultAddressId == address.id,
                      isDeleting:
                          _pendingDeleteAddressId != null &&
                          _pendingDeleteAddressId == address.id,
                      onEdit: () => _onEdit(index),
                      onDelete: () => _onDeleteAddress(index),
                      onToggleDefault: (value) =>
                          _onToggleDefault(index, value),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomElevatedButton(
                    onPressed: _saving ? () {} : _onAdd,
                    backgroundColor: AppColors.primaryColor,
                    child: Text(
                      _tr('Add Address', 'إضافة عنوان'),
                      style: AppStyle.styleRegular15(
                        context,
                      ).copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressesShimmerSliver extends StatelessWidget {
  const _AddressesShimmerSliver({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => const _AddressCardShimmer(),
    );
  }
}

class _AddressCardShimmer extends StatelessWidget {
  const _AddressCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEFF3),
      highlightColor: const Color(0xFFF9FAFC),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE3E7EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _shimmerBox(height: 16.h, width: 140.w),
                ),
                SizedBox(width: 8.w),
                _shimmerBox(height: 34.h, width: 34.w, radius: 8.r),
                SizedBox(width: 8.w),
                _shimmerBox(height: 34.h, width: 34.w, radius: 8.r),
              ],
            ),
            SizedBox(height: 12.h),
            _shimmerBox(height: 14.h, width: double.infinity),
            SizedBox(height: 8.h),
            _shimmerBox(height: 14.h, width: 210.w),
            SizedBox(height: 10.h),
            _shimmerBox(height: 12.h, width: 180.w),
            SizedBox(height: 12.h),
            Row(
              children: [
                _shimmerBox(height: 18.h, width: 18.h, radius: 9.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: _shimmerBox(height: 12.h, width: 120.w),
                ),
                _shimmerBox(height: 26.h, width: 46.w, radius: 13.r),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    required double width,
    double radius = 6,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onToggleDefault,
    required this.saving,
    this.isUpdatingDefault = false,
    this.isDeleting = false,
  });

  final _AddressEntry address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool>? onToggleDefault;
  final bool saving;
  final bool isUpdatingDefault;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE3E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  address.fullName,
                  style: AppStyle.styleRegular15(
                    context,
                  ).copyWith(color: Colors.black, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 34.w,
                height: 34.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFE3E7EE)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 16.r,
                    onPressed: saving ? null : onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 34.w,
                height: 34.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFE3E7EE)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 16.r,
                    onPressed: (saving || isDeleting) ? null : onDelete,
                    icon: isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            address.localizedPrettyAddress(
              Localizations.localeOf(context).languageCode,
            ),
            style: AppStyle.styleRegular15(
              context,
            ).copyWith(color: Colors.black87, height: 1.35),
          ),
          SizedBox(height: 6.h),
          Text(
            '${isArabic ? 'الهاتف' : 'Phone'}: ${address.countryCode.isEmpty ? '' : '${address.countryCode} '}${address.phoneNumber}'
                .trim(),
            style: AppStyle.styleRegular15(
              context,
            ).copyWith(color: Colors.black54),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                address.isDefault
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: address.isDefault
                    ? AppColors.primaryColor
                    : Colors.black54,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  address.isDefault
                      ? (isArabic ? 'العنوان الافتراضي' : 'Default address')
                      : (isArabic ? 'ليس افتراضياً' : 'Not default'),
                  style: AppStyle.styleRegular15(
                    context,
                  ).copyWith(color: Colors.black87),
                ),
              ),
              if (isUpdatingDefault) ...[
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Switch.adaptive(
                value: address.isDefault,
                activeTrackColor: AppColors.primaryColor.withValues(
                  alpha: 0.45,
                ),
                thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryColor;
                  }
                  return null;
                }),
                onChanged: (saving || isUpdatingDefault)
                    ? null
                    : onToggleDefault,
              ),
              if (address.isDefault)
                Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressEntry {
  static const String _defaultZipCode = '0000';

  const _AddressEntry({
    required this.id,
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

  final String id;
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

  String get prettyAddress {
    final parts = [
      streetAddress,
      apartment,
      city,
      state,
      zipCode,
      country,
    ].where((item) => item.trim().isNotEmpty);
    return parts.join(', ');
  }

  String localizedPrettyAddress(String languageCode) {
    final resolvedCountryCode =
        LocationNameLocalizer.countryCodeFor(country) ?? country;
    final displayCountry = LocationNameLocalizer.countryName(
      country,
      languageCode,
    );
    final displayState = resolvedCountryCode.trim().isEmpty
        ? state
        : LocationNameLocalizer.stateName(
            countryCode: resolvedCountryCode,
            stateCodeOrName: state,
            languageCode: languageCode,
          );
    final resolvedStateCode = resolvedCountryCode.trim().isEmpty
        ? state
        : LocationNameLocalizer.stateCodeFor(
                countryCode: resolvedCountryCode,
                stateCodeOrName: state,
              ) ??
              state;
    final displayCity =
        resolvedCountryCode.trim().isEmpty || resolvedStateCode.trim().isEmpty
        ? city
        : LocationNameLocalizer.cityName(
            countryCode: resolvedCountryCode,
            stateCode: resolvedStateCode,
            cityName: city,
            languageCode: languageCode,
          );

    final parts = [
      streetAddress,
      apartment,
      displayCity,
      displayState,
      zipCode,
      displayCountry,
    ].where((item) => item.trim().isNotEmpty);
    return parts.join(', ');
  }

  _AddressEntry copyWith({bool? isDefault}) {
    return _AddressEntry(
      id: id,
      fullName: fullName,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      apartment: apartment,
      zipCode: _normalizeZipCode(zipCode),
      city: city,
      state: state,
      country: country,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toFormMap() {
    return {
      'id': id,
      'uuid': id,
      'fullName': fullName,
      'countryCode': normalizeCountryCode(countryCode, countryName: country),
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'apartment': apartment,
      'zipCode': _normalizeZipCode(zipCode),
      'city': city,
      'state': state,
      'country': country,
      'address_1': streetAddress,
      'address_2': apartment,
      'postcode': _normalizeZipCode(zipCode),
      'phone': phoneNumber,
      'isDefault': isDefault,
      'is_default': isDefault,
    };
  }

  factory _AddressEntry.fromMap(Map<String, dynamic> map) {
    final shipping = _asMap(map['shipping_address']);
    final source = shipping.isNotEmpty ? shipping : map;

    final fullName =
        _value(source, const ['fullName', 'full_name', 'name']) ??
        _joinNonEmpty([
          _value(source, const ['firstName', 'first_name']),
          _value(source, const ['lastName', 'last_name']),
        ]);

    final country = _value(source, const ['country', 'country_name']) ?? '';
    final rawPhone =
        _value(source, const ['phoneNumber', 'phone', 'phone_number']) ?? '';
    final resolvedCountryCode = normalizeCountryCode(
      _value(source, const ['countryCode', 'country_code']),
      countryName: country,
    );
    final parsedPhone = _splitPhone(
      rawPhone,
      fallbackCountryCode: resolvedCountryCode,
    );

    return _AddressEntry(
      id:
          _value(source, const ['uuid', 'id', 'address_id']) ??
          _value(map, const ['uuid', 'id', 'address_id']) ??
          '',
      fullName: fullName.isEmpty ? 'Address' : fullName,
      countryCode: parsedPhone.countryCode,
      phoneNumber: parsedPhone.number,
      streetAddress:
          _value(source, const [
            'streetAddress',
            'street_address',
            'address_1',
          ]) ??
          '',
      apartment: _value(source, const ['apartment', 'address_2']) ?? '',
      zipCode: _normalizeZipCode(
        _value(source, const [
              'zipCode',
              'zip_code',
              'postcode',
              'postalCode',
            ]) ??
            '',
      ),
      city: _value(source, const ['city', 'city_name']) ?? '',
      state: _value(source, const ['state', 'province']) ?? '',
      country: country,
      isDefault: _toBool(
        source['isDefault'] ??
            source['is_default'] ??
            source['default'] ??
            source['defaultAddress'] ??
            map['isDefault'] ??
            map['is_default'] ??
            map['default'],
      ),
    );
  }
}

class _ParsedPhone {
  const _ParsedPhone({required this.countryCode, required this.number});

  final String countryCode;
  final String number;
}

class _MyAddressesRepo {
  _MyAddressesRepo({Dio? dio}) : _dio = dio ?? sl<Dio>();

  final Dio _dio;

  Future<List<dynamic>> getAddresses() => _getAddressesRest();

  Future<void> createAddress(Map<String, dynamic> payload) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final response = await _dio.post(
      EndPoints.customerAddresses,
      data: payload,
      options: _restOptions(token: token),
    );
    _throwIfRestWriteFailed(
      response,
      fallbackMessage: 'Could not create address right now.',
    );
  }

  Future<void> updateAddress({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final response = await _dio.put(
      '${EndPoints.customerAddresses}/$id',
      data: payload,
      options: _restOptions(token: token),
    );
    _throwIfRestWriteFailed(
      response,
      fallbackMessage: 'Could not update address right now.',
    );
  }

  Future<void> patchAddress({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final response = await _dio.patch(
      '${EndPoints.customerAddresses}/$id',
      data: payload,
      options: _restOptions(token: token),
    );
    _throwIfRestWriteFailed(
      response,
      fallbackMessage: 'Could not update default address right now.',
    );
  }

  Future<void> deleteAddress({required String id}) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final response = await _dio.delete(
      '${EndPoints.customerAddresses}/$id',
      options: _restOptions(token: token),
    );
    _throwIfRestWriteFailed(
      response,
      fallbackMessage: 'Could not delete address right now.',
    );
  }

  Future<List<dynamic>> _getAddressesRest() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final response = await _dio.get(
      EndPoints.customerAddresses,
      options: _restOptions(token: token),
    );
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      if (BackendUnavailableDetector.isBackendUnavailableStatusCode(status) ||
          BackendUnavailableDetector.isBackendUnavailablePayload(
            response.data,
          )) {
        BackendUnavailableNotifier.show();
        throw Exception('Server not responding. Please try again.');
      }
      throw Exception('Could not load your addresses right now.');
    }

    if (response.data is List) {
      return (response.data as List<dynamic>);
    }
    final root = _asMap(response.data);
    final list = _extractAddressList(root);
    return list ?? const [];
  }

  Options _restOptions({dynamic token}) {
    return Options(
      headers: {
        if (token != null && token.toString().trim().isNotEmpty)
          'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );
  }

  List<dynamic>? _extractAddressList(Map<String, dynamic> data) {
    const fields = [
      'getCustomerAddresses',
      'customerAddresses',
      'getAddresses',
      'addresses',
      'results',
      'data',
    ];
    for (final field in fields) {
      final candidate = data[field];
      if (candidate is List) return candidate;
      if (candidate is Map<String, dynamic>) {
        const nestedFields = ['items', 'nodes', 'results', 'data', 'addresses'];
        for (final nestedField in nestedFields) {
          final nestedList = candidate[nestedField];
          if (nestedList is List) return nestedList;
        }
      }
    }
    return null;
  }

  void _throwIfRestWriteFailed(
    Response response, {
    required String fallbackMessage,
  }) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      if (BackendUnavailableDetector.isBackendUnavailableStatusCode(status) ||
          BackendUnavailableDetector.isBackendUnavailablePayload(
            response.data,
          )) {
        BackendUnavailableNotifier.show();
        throw Exception('Server not responding. Please try again.');
      }
      final message = _extractRestErrorMessage(response.data);
      throw Exception(message ?? fallbackMessage);
    }

    final body = _asMap(response.data);
    final successFlag = body['success'] ?? body['ok'];
    if (successFlag is bool && !successFlag) {
      final message = _extractRestErrorMessage(body);
      throw Exception(message ?? fallbackMessage);
    }
    final statusText = body['status']?.toString().trim().toLowerCase();
    if (statusText == 'error' ||
        statusText == 'failed' ||
        statusText == 'fail') {
      final message = _extractRestErrorMessage(body);
      throw Exception(message ?? fallbackMessage);
    }
  }

  String? _extractRestErrorMessage(dynamic data) {
    final body = _asMap(data);
    final direct = body['message']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final error = body['error']?.toString().trim();
    if (error != null && error.isNotEmpty) return error;
    final nestedData = _asMap(body['data']);
    final nested = nestedData['message']?.toString().trim();
    if (nested != null && nested.isNotEmpty) return nested;
    return null;
  }
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw == null) return <String, dynamic>{};
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

String? _value(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final raw = map[key];
    if (raw == null) continue;
    final text = raw.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

String _joinNonEmpty(List<String?> parts) {
  return parts
      .where((item) => item != null && item.trim().isNotEmpty)
      .join(' ')
      .trim();
}

bool _toBool(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final value = raw?.toString().trim().toLowerCase();
  return value == 'true' || value == '1' || value == 'yes';
}

_ParsedPhone _splitPhone(
  String rawPhone, {
  required String fallbackCountryCode,
}) {
  final cleaned = rawPhone.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) {
    return _ParsedPhone(countryCode: fallbackCountryCode, number: '');
  }
  if (!cleaned.startsWith('+')) {
    return _ParsedPhone(countryCode: fallbackCountryCode, number: cleaned);
  }

  final parts = cleaned.split(' ');
  final cc = parts.first.trim();
  if (parts.length > 1) {
    return _ParsedPhone(
      countryCode: cc,
      number: parts.sublist(1).join(' ').trim(),
    );
  }
  return _ParsedPhone(countryCode: cc, number: cleaned);
}
