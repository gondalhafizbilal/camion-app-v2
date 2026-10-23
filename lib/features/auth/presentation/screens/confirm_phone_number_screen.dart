import 'dart:async';

import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/features/auth/presentation/logic/verify_cubit/verify_cubit.dart';
import 'package:camion/features/auth/presentation/widgets/auth_background_scaffold.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class _ContactInfo {
  const _ContactInfo({required this.masked, required this.isPhone});

  final String masked;
  final bool isPhone;
}

class ConfirmPhoneNumberScreen extends StatefulWidget {
  const ConfirmPhoneNumberScreen({super.key, this.nextPath});

  final String? nextPath;

  @override
  State<ConfirmPhoneNumberScreen> createState() =>
      _ConfirmPhoneNumberScreenState();
}

class _ConfirmPhoneNumberScreenState extends State<ConfirmPhoneNumberScreen> {
  final TextEditingController _codeController = TextEditingController();
  static const int _resendCooldownSeconds = 60;
  Timer? _resendTimer;
  int _resendRemainingSeconds = _resendCooldownSeconds;

  bool get _isResendCoolingDown => _resendRemainingSeconds > 0;

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    final focusScope = FocusScope.of(context);
    if (focusScope.hasFocus) {
      focusScope.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendRemainingSeconds = _resendCooldownSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendRemainingSeconds <= 1) {
        setState(() {
          _resendRemainingSeconds = 0;
        });
        timer.cancel();
        return;
      }
      setState(() {
        _resendRemainingSeconds -= 1;
      });
    });
  }

  Future<void> _onResendPressed() async {
    if (_isResendCoolingDown) return;
    _startResendCooldown();
    context.read<VerifyCubit>().resend();
  }

  Future<_ContactInfo?> _getContactInfo() async {
    final cache = sl<SecureCacheHelper>();
    final loginMethod = ((await cache.getData(key: 'authLoginMethod')) ?? '')
        .trim()
        .toLowerCase();
    final phone = ((await cache.getData(key: 'phoneNumber')) ?? '').trim();
    final email = ((await cache.getData(key: 'email')) ?? '').trim();

    if (loginMethod == 'email') {
      if (email.isNotEmpty) {
        return _ContactInfo(masked: _maskEmail(email), isPhone: false);
      }
      if (phone.isNotEmpty) {
        return _ContactInfo(masked: _maskPhone(phone), isPhone: true);
      }
    }

    if (loginMethod == 'phone') {
      if (phone.isNotEmpty) {
        return _ContactInfo(masked: _maskPhone(phone), isPhone: true);
      }
      if (email.isNotEmpty) {
        return _ContactInfo(masked: _maskEmail(email), isPhone: false);
      }
    }

    if (phone.isNotEmpty) {
      return _ContactInfo(masked: _maskPhone(phone), isPhone: true);
    }
    if (email.isNotEmpty) {
      return _ContactInfo(masked: _maskEmail(email), isPhone: false);
    }

    return null;
  }

  String _maskPhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.length <= 4) {
      return trimmed;
    }
    final visible = trimmed.substring(trimmed.length - 4);
    return '${'*' * (trimmed.length - 4)}$visible';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) {
      return email;
    }

    final name = parts.first.trim();
    final domain = parts.last;
    if (name.isEmpty) {
      return email;
    }
    if (name.length == 1) {
      return '${name[0]}***@$domain';
    }
    final visibleCount = (name.length / 2).ceil();
    final maskedCount = name.length - visibleCount;
    return '${name.substring(0, visibleCount)}${'*' * maskedCount}@$domain';
  }

  String _titleForContact(BuildContext context, bool isPhone) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'رمز التحقق';
    }
    return 'Verification Code';
  }

  String _subtitleForContact(BuildContext context, bool isPhone) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (isPhone) {
      if (languageCode == 'ar') {
        return 'الرجاء إدخال رمز التحقق المرسل إلى رقم هاتفك';
      }
      return 'Please type the verification code sent to your phone number';
    }
    if (languageCode == 'ar') {
      return 'الرجاء إدخال رمز التحقق المرسل إلى بريدك الإلكتروني';
    }
    return 'Please type the verification code sent to your email';
  }

  bool get _shouldShowDefaultOtpHint {
    final baseUrl = AppConfig.instance.baseUrl.trim();
    final host = Uri.tryParse(baseUrl)?.host.toLowerCase() ?? '';
    if (host.isEmpty) return true;
    return host.contains('dev') ||
        host.contains('staging') ||
        host.contains('localhost') ||
        host.contains('127.0.0.1');
  }

  void _submitCode() {
    _dismissKeyboard();
    final code = _codeController.text.trim();
    if (code.length != 6) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: isArabic
            ? 'يرجى إدخال رمز التحقق المكون من 6 أرقام.'
            : 'Enter the 6-digit verification code.',
      );
      return;
    }
    context.read<VerifyCubit>().verify(code: code);
  }

  Future<void> _handleVerifySuccess(
    BuildContext context,
    VerifyLoaded state,
  ) async {
    final accessToken =
        (await sl<SecureCacheHelper>().getData(key: 'token'))?.trim() ?? '';
    if (accessToken.isEmpty) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Login failed: session token is missing.',
      );
      return;
    }

    final next = widget.nextPath;
    final nextDecoded = next != null ? Uri.decodeComponent(next) : null;
    if (!context.mounted) return;
    if (nextDecoded != null && nextDecoded.isNotEmpty) {
      final decodedUri = Uri.tryParse(nextDecoded);
      final redirectedTab = decodedUri?.queryParameters['tab']?.trim();
      final isCartTabRedirect =
          decodedUri?.path == AppRouter.selectingFromBottomNavBar &&
          redirectedTab == '3';
      if (isCartTabRedirect) {
        CartRefreshNotifier.requestRefresh();
      }

      final router = RouterGenerator.mainRouting;

      // Expected auth flow stack: [previous] -> login -> verify
      if (router.canPop()) router.pop();
      if (router.canPop()) router.pop();

      final currentPath = router.routeInformationProvider.value.uri.toString();
      if (currentPath != nextDecoded) {
        router.go(nextDecoded);
      }
      return;
    }

    context.goNamed(AppRouter.selectingFromBottomNavBar);
  }

  bool _shouldForceRelogin(VerifyError state) {
    final message = state.error.message.trim().toLowerCase();
    final statusCode = state.error.statusCode;
    return statusCode == 401 ||
        message.contains('session has expired') ||
        message.contains('session expired') ||
        message.contains('login again') ||
        message.contains('another device') ||
        message.contains('unauthorized');
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundScaffold(
      resizeToAvoidBottomInset: false,
      child: BlocConsumer<VerifyCubit, VerifyState>(
        listener: (context, state) async {
          if (state is VerifyError) {
            _dismissKeyboard();
            AppToast.show(
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.red,
              msg: state.error.message,
            );
            if (_shouldForceRelogin(state) && context.mounted) {
              final next = Uri.encodeComponent(
                '${AppRouter.confirmPhoneNumberScreen}${widget.nextPath != null ? '?next=${widget.nextPath}' : ''}',
              );
              context.go('${AppRouter.login}?next=$next');
              return;
            }
          }

          if (state is VerifyLoaded) {
            await _handleVerifySuccess(context, state);
          }
        },
        builder: (context, state) {
          final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

          return LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 96.h, 22.w, 64.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<_ContactInfo?>(
                            future: _getContactInfo(),
                            builder: (context, snapshot) {
                              final contact = snapshot.data;
                              final isPhone = contact?.isPhone ?? false;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titleForContact(context, isPhone),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24.sp,
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w500,
                                      height: 40 / 24,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _subtitleForContact(context, isPhone),
                                    style: TextStyle(
                                      color: const Color(0xFF3F3F3F),
                                      fontSize: 12.sp,
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w400,
                                      height: 18 / 12,
                                    ),
                                  ),
                                  if (contact != null) ...[
                                    SizedBox(height: 6.h),
                                    Text(
                                      contact.masked,
                                      style:
                                          AppStyle.styleVerificationContact12Bold(
                                            context,
                                          ).copyWith(fontSize: 15.sp),
                                    ),
                                  ],
                                  SizedBox(height: 12.h),
                                  if (_shouldShowDefaultOtpHint)
                                    Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'في بيئة التطوير، رمز التحقق الافتراضي هو 123456.'
                                          : 'In local and development, the default OTP is 123456.',
                                      style:
                                          AppStyle.styleVerificationBody12Regular(
                                            context,
                                          ).copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 28.h),
                          CustomTextFormField(
                            controller: _codeController,
                            hintText:
                                Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'أدخل رمز التحقق'
                                : 'Enter verification code',
                            autoFocus: true,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) => _submitCode(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            style: AppStyle.styleRegular18(
                              context,
                            ).copyWith(color: Colors.black),
                          ),
                          SizedBox(height: 24.h),
                          SizedBox(
                            width: double.infinity,
                            child: CustomElevatedButton(
                              onPressed: state is VerifyLoading
                                  ? null
                                  : _submitCode,
                              child: state is VerifyLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'إرسال'
                                          : 'Send',
                                      style: AppStyle.styleButtonLabel14Regular(
                                        context,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed:
                                  (state is VerifyLoading ||
                                      _isResendCoolingDown)
                                  ? null
                                  : _onResendPressed,
                              child: Text(
                                _isResendCoolingDown
                                    ? (Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'إعادة إرسال الرمز خلال ${_resendRemainingSeconds}s'
                                          : 'Resend code in ${_resendRemainingSeconds}s')
                                    : (Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'إعادة إرسال الرمز'
                                          : 'Resend code'),
                              ),
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
      ),
    );
  }
}
