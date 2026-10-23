// ignore_for_file: constant_identifier_names

import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter/material.dart';

// Compatibility enums to support existing toast call sites.
enum Toast { LENGTH_SHORT, LENGTH_LONG }

enum ToastGravity { TOP, BOTTOM, CENTER }

enum _ToastType { success, error, info }

class AppToast {
  AppToast._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static DateTime? _lastAuthRedirectAt;
  static bool _isAuthRedirectInProgress = false;

  static Future<bool?> show({
    required String msg,
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.TOP,
    Color? backgroundColor,
    Color textColor = Colors.white,
    double? fontSize,
  }) async {
    final trimmedMessage = msg.trim();
    if (trimmedMessage.isEmpty) return null;

    if (_shouldTreatAsUnauthorizedMessage(trimmedMessage)) {
      _tryRedirectToLoginIfUnauthorizedMessage(trimmedMessage);
      return null;
    }

    final messenger = messengerKey.currentState;
    if (messenger == null) return null;
    final localizedMsg = _resolveLocalizedMessage(
      trimmedMessage,
      messenger.context,
    );

    final type = _resolveType(backgroundColor);
    final config = _styleFor(type);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 10,
          backgroundColor: Colors.transparent,
          duration: toastLength == Toast.LENGTH_LONG
              ? const Duration(seconds: 4)
              : const Duration(seconds: 2),
          margin: gravity == ToastGravity.BOTTOM
              ? const EdgeInsets.fromLTRB(16, 0, 16, 24)
              : const EdgeInsets.fromLTRB(16, 18, 16, 0),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: config.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(config.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localizedMsg,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize ?? 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    return true;
  }

  static String _resolveLocalizedMessage(String message, BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lang != 'ar' && lang != 'en') return message;

    final pair = _toastLocaleMap[message];
    if (pair != null) {
      return lang == 'ar' ? pair.ar : pair.en;
    }

    for (final pattern in _toastPatternMap) {
      final resolved = pattern.resolve(message: message, lang: lang);
      if (resolved != null) return resolved;
    }

    return message;
  }

  static bool _shouldTreatAsUnauthorizedMessage(String message) {
    final text = message.trim().toLowerCase();
    if (text.isEmpty) return false;

    const authSignals = <String>[
      'unauthorized',
      'forbidden',
      'access denied',
      'not authorized',
      'unauthenticated',
      'authentication required',
      'authentication failed',
      'session expired',
      'token expired',
      'invalid token',
      'please login',
      'please log in',
      'login again',
      'log in again',
      'sign in again',
      'login to continue',
      'log in to continue',
      'please sign in',
      'sign in to continue',
    ];

    for (final signal in authSignals) {
      if (text.contains(signal)) {
        return true;
      }
    }
    return false;
  }

  static bool _isOnAuthRoute(String location) {
    if (location.isEmpty) return false;
    return location.startsWith(AppRouter.login) ||
        location.startsWith(AppRouter.register) ||
        location.startsWith(AppRouter.confirmPhoneNumberScreen);
  }

  static void _tryRedirectToLoginIfUnauthorizedMessage(String message) {
    if (!_shouldTreatAsUnauthorizedMessage(message)) return;

    final now = DateTime.now();
    if (_lastAuthRedirectAt != null &&
        now.difference(_lastAuthRedirectAt!) < const Duration(seconds: 2)) {
      return;
    }
    if (_isAuthRedirectInProgress) return;

    final router = RouterGenerator.mainRouting;
    final currentLocation = router.routeInformationProvider.value.uri
        .toString();
    if (_isOnAuthRoute(currentLocation)) {
      return;
    }

    _lastAuthRedirectAt = now;
    _isAuthRedirectInProgress = true;

    Future<void>.microtask(() async {
      try {
        await _clearAuthSessionOnly();

        final nextSource = currentLocation.isEmpty
            ? AppRouter.selectingFromBottomNavBar
            : currentLocation;
        final next = Uri.encodeComponent(nextSource);
        final location = '${AppRouter.login}?next=$next&expired=1';
        router.go(location);
      } catch (_) {
        // Swallow navigation failures; toast remains visible.
      } finally {
        _isAuthRedirectInProgress = false;
      }
    });
  }

  static Future<void> _clearAuthSessionOnly() async {
    if (!sl.isRegistered<SecureCacheHelper>()) return;
    final secure = sl<SecureCacheHelper>();
    final keys = <String>[
      'token',
      'authSessionToken',
      'id',
      'userRole',
      'email',
      'userName',
      'phoneNumber',
      'authLoginMethod',
    ];
    for (final key in keys) {
      await secure.removeData(key: key);
    }
  }

  static _ToastType _resolveType(Color? backgroundColor) {
    if (backgroundColor == null) return _ToastType.info;

    final value = backgroundColor.toARGB32();
    final redSet = {
      Colors.red.toARGB32(),
      Colors.redAccent.toARGB32(),
      AppColors.warningRed.toARGB32(),
      AppColors.alertRed.toARGB32(),
      AppColors.primaryColor.toARGB32(),
    };
    final greenSet = {
      Colors.green.toARGB32(),
      Colors.greenAccent.toARGB32(),
      AppColors.green.toARGB32(),
      AppColors.deepGreen.toARGB32(),
      AppColors.natureGreen.toARGB32(),
    };

    if (redSet.contains(value)) return _ToastType.error;
    if (greenSet.contains(value)) return _ToastType.success;
    return _ToastType.info;
  }

  static _ToastStyle _styleFor(_ToastType type) {
    switch (type) {
      case _ToastType.success:
        return const _ToastStyle(
          background: AppColors.primaryColor,
          border: Color(0xFF9F1719),
          icon: Icons.check_circle_rounded,
        );
      case _ToastType.error:
        return const _ToastStyle(
          background: Color(0xFF8E191B),
          border: Color(0xFFE16B6D),
          icon: Icons.error_rounded,
        );
      case _ToastType.info:
        return const _ToastStyle(
          background: Color(0xFF2A2A2A),
          border: AppColors.primaryColor,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _ToastLocalePair {
  const _ToastLocalePair({required this.en, required this.ar});

  final String en;
  final String ar;
}

class _ToastPatternPair {
  const _ToastPatternPair({
    required this.enRegex,
    required this.arRegex,
    required this.enBuilder,
    required this.arBuilder,
  });

  final RegExp enRegex;
  final RegExp arRegex;
  final String Function(RegExpMatch match) enBuilder;
  final String Function(RegExpMatch match) arBuilder;

  String? resolve({required String message, required String lang}) {
    if (lang == 'ar') {
      final match = enRegex.firstMatch(message);
      if (match != null) return arBuilder(match);
      return null;
    }

    final match = arRegex.firstMatch(message);
    if (match != null) return enBuilder(match);
    return null;
  }
}

const Map<String, _ToastLocalePair> _toastLocaleMap = {
  'Successful payment': _ToastLocalePair(
    en: 'Successful payment',
    ar: 'تم الدفع بنجاح',
  ),
  'Payment failed': _ToastLocalePair(en: 'Payment failed', ar: 'فشل الدفع'),
  'Please login first.': _ToastLocalePair(
    en: 'Please login first.',
    ar: 'يرجى تسجيل الدخول أولاً.',
  ),
  'Login to continue': _ToastLocalePair(
    en: 'Login to continue',
    ar: 'سجل الدخول للمتابعة',
  ),
  'Please enter coupon code.': _ToastLocalePair(
    en: 'Please enter coupon code.',
    ar: 'يرجى إدخال رمز القسيمة.',
  ),
  'Coupon applied successfully.': _ToastLocalePair(
    en: 'Coupon applied successfully.',
    ar: 'تم تطبيق القسيمة بنجاح.',
  ),
  'Your cart is empty.': _ToastLocalePair(
    en: 'Your cart is empty.',
    ar: 'سلة التسوق فارغة.',
  ),
  'Logged in with Google successfully.': _ToastLocalePair(
    en: 'Logged in with Google successfully.',
    ar: 'تم تسجيل الدخول عبر Google بنجاح.',
  ),
  'Logged in with Facebook successfully.': _ToastLocalePair(
    en: 'Logged in with Facebook successfully.',
    ar: 'تم تسجيل الدخول عبر Facebook بنجاح.',
  ),
  'Logged in with Apple successfully.': _ToastLocalePair(
    en: 'Logged in with Apple successfully.',
    ar: 'تم تسجيل الدخول عبر Apple بنجاح.',
  ),
  'Verification code sent successfully.': _ToastLocalePair(
    en: 'Verification code sent successfully.',
    ar: 'تم إرسال رمز التحقق بنجاح.',
  ),
  'Login failed: session token is missing.': _ToastLocalePair(
    en: 'Login failed: session token is missing.',
    ar: 'فشل تسجيل الدخول: رمز الجلسة مفقود.',
  ),
  'Please select a verification method.': _ToastLocalePair(
    en: 'Please select a verification method.',
    ar: 'يرجى اختيار طريقة التحقق.',
  ),
  'Guest login failed: access token is missing.': _ToastLocalePair(
    en: 'Guest login failed: access token is missing.',
    ar: 'فشل دخول الضيف: رمز الوصول مفقود.',
  ),
  'Guest login failed: session was not saved.': _ToastLocalePair(
    en: 'Guest login failed: session was not saved.',
    ar: 'فشل دخول الضيف: لم يتم حفظ الجلسة.',
  ),
  'Guest session started successfully.': _ToastLocalePair(
    en: 'Guest session started successfully.',
    ar: 'تم بدء جلسة الضيف بنجاح.',
  ),
  'Removed from wishlist': _ToastLocalePair(
    en: 'Removed from wishlist',
    ar: 'تمت الإزالة من المفضلة',
  ),
  'Added to wishlist': _ToastLocalePair(
    en: 'Added to wishlist',
    ar: 'تمت الإضافة إلى المفضلة',
  ),
  'Please allow camera/photos access in iOS Settings.': _ToastLocalePair(
    en: 'Please allow camera/photos access in iOS Settings.',
    ar: 'يرجى السماح بالوصول للكاميرا/الصور من إعدادات iOS.',
  ),
  'Unable to open media picker right now. Please try again.': _ToastLocalePair(
    en: 'Unable to open media picker right now. Please try again.',
    ar: 'تعذر فتح اختيار الوسائط الآن. يرجى المحاولة مرة أخرى.',
  ),
  'Please allow photos access in iOS Settings.': _ToastLocalePair(
    en: 'Please allow photos access in iOS Settings.',
    ar: 'يرجى السماح بالوصول للصور من إعدادات iOS.',
  ),
  'Unable to open gallery right now. Please try again.': _ToastLocalePair(
    en: 'Unable to open gallery right now. Please try again.',
    ar: 'تعذر فتح المعرض الآن. يرجى المحاولة مرة أخرى.',
  ),
  'Logout successful': _ToastLocalePair(
    en: 'Logout successful',
    ar: 'تم تسجيل الخروج بنجاح',
  ),
  'Unable to identify product for cart. Please retry.': _ToastLocalePair(
    en: 'Unable to identify product for cart. Please retry.',
    ar: 'تعذر تحديد المنتج للسلة. يرجى المحاولة مرة أخرى.',
  ),
  'Please select a valid variant.': _ToastLocalePair(
    en: 'Please select a valid variant.',
    ar: 'يرجى اختيار متغير صالح.',
  ),
  'تم نسخ النص - يمكنك لصقه في أي تطبيق': _ToastLocalePair(
    en: 'Text copied - you can paste it in any app',
    ar: 'تم نسخ النص - يمكنك لصقه في أي تطبيق',
  ),
  'Text copied - you can paste it in any app': _ToastLocalePair(
    en: 'Text copied - you can paste it in any app',
    ar: 'تم نسخ النص - يمكنك لصقه في أي تطبيق',
  ),
  'Order ID copied': _ToastLocalePair(
    en: 'Order ID copied',
    ar: 'تم نسخ رقم الطلب',
  ),
};

final List<_ToastPatternPair> _toastPatternMap = [
  _ToastPatternPair(
    enRegex: RegExp(r'^Google sign-in failed\. (.+)$'),
    arRegex: RegExp(r'^فشل تسجيل الدخول عبر Google\. (.+)$'),
    enBuilder: (m) => 'Google sign-in failed. ${m.group(1)!}',
    arBuilder: (m) => 'فشل تسجيل الدخول عبر Google. ${m.group(1)!}',
  ),
  _ToastPatternPair(
    enRegex: RegExp(r'^Facebook sign-in failed\. (.+)$'),
    arRegex: RegExp(r'^فشل تسجيل الدخول عبر Facebook\. (.+)$'),
    enBuilder: (m) => 'Facebook sign-in failed. ${m.group(1)!}',
    arBuilder: (m) => 'فشل تسجيل الدخول عبر Facebook. ${m.group(1)!}',
  ),
  _ToastPatternPair(
    enRegex: RegExp(r'^Apple sign-in failed\. (.+)$'),
    arRegex: RegExp(r'^فشل تسجيل الدخول عبر Apple\. (.+)$'),
    enBuilder: (m) => 'Apple sign-in failed. ${m.group(1)!}',
    arBuilder: (m) => 'فشل تسجيل الدخول عبر Apple. ${m.group(1)!}',
  ),
  _ToastPatternPair(
    enRegex: RegExp(
      r'^(.+) with this social account is not active yet\. Please use Google, email, or phone for now\.$',
    ),
    arRegex: RegExp(
      r'^التسجيل عبر هذا الحساب الاجتماعي غير مفعّل حالياً لـ (.+)\. يرجى استخدام Google أو البريد الإلكتروني أو الهاتف حالياً\.$',
    ),
    enBuilder: (m) =>
        '${m.group(1)!} with this social account is not active yet. Please use Google, email, or phone for now.',
    arBuilder: (m) =>
        'التسجيل عبر هذا الحساب الاجتماعي غير مفعّل حالياً لـ ${m.group(1)!}. يرجى استخدام Google أو البريد الإلكتروني أو الهاتف حالياً.',
  ),
  _ToastPatternPair(
    enRegex: RegExp(r'^Please select: (.+)$'),
    arRegex: RegExp(r'^يرجى الاختيار: (.+)$'),
    enBuilder: (m) => 'Please select: ${m.group(1)!}',
    arBuilder: (m) => 'يرجى الاختيار: ${m.group(1)!}',
  ),
  _ToastPatternPair(
    enRegex: RegExp(r'^Only (\d+) item\(s\) available\.$'),
    arRegex: RegExp(r'^المتوفر فقط (\d+) قطعة\.$'),
    enBuilder: (m) => 'Only ${m.group(1)!} item(s) available.',
    arBuilder: (m) => 'المتوفر فقط ${m.group(1)!} قطعة.',
  ),
];

class _ToastStyle {
  const _ToastStyle({
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color border;
  final IconData icon;
}
