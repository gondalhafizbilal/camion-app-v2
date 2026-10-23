// import 'package:camion/config/widgets/custom_elevated_button.dart';
// import 'package:camion/config/widgets/custom_text_form_field.dart';
// import 'package:camion/core/utils/app_style.dart';
// import 'package:camion/features/auth/presentation/logic/login_cubit/login_cubit.dart';
// import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
// import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
// import 'package:camion/generated/l10n.dart';
// import 'package:camion/routing/app_router.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:camion/core/utils/app_toast.dart';
// import 'package:go_router/go_router.dart';
//
// class LoginForm extends StatefulWidget {
//   const LoginForm({super.key, this.nextPath});
//   final String? nextPath;
//
//   @override
//   State<LoginForm> createState() => _LoginFormState();
// }
//
// class _LoginFormState extends State<LoginForm> {
//   final formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   late final PhoneNumberController _phoneNumberController;
//
//   bool isEmailEnabled = true;
//   bool isPhoneEnabled = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _phoneNumberController = PhoneNumberController();
//
//     // EMAIL LISTENER
//     _emailController.addListener(() {
//       final hasEmail = _emailController.text.trim().isNotEmpty;
//       if (hasEmail && isPhoneEnabled) {
//         setState(() {
//           isPhoneEnabled = false; // disable phone, but DON'T clear -> keep country code
//         });
//       } else if (!hasEmail && !isPhoneEnabled && !_hasUserTypedPhone) {
//         // re-enable phone when email cleared and user hasn't typed a real phone
//         setState(() {
//           isPhoneEnabled = true;
//         });
//       }
//     });
//
//     // PHONE LISTENER
//     _phoneNumberController.addListener(() {
//       final hasPhone = _hasUserTypedPhone;
//       if (hasPhone && isEmailEnabled) {
//         setState(() {
//           isEmailEnabled = false;
//         });
//         _emailController.clear();
//       } else if (!hasPhone && !isEmailEnabled && _emailController.text.isEmpty) {
//         setState(() {
//           isEmailEnabled = true;
//         });
//       }
//     });
//   }
//
//   /// Treat "only country code" as EMPTY
//   bool get _hasUserTypedPhone {
//     final raw = (_phoneNumberController.fullPhoneNumber ?? '');
//     // remove non-digits
//     final digits = raw.replaceAll(RegExp(r'\D'), '');
//     // heuristic: country code alone is usually <= 3 digits
//     return digits.length > 3;
//   }
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _phoneNumberController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: formKey,
//       child: Column(
//         children: [
//           /// EMAIL FIELD
//           Opacity(
//             opacity: isEmailEnabled ? 1.0 : 0.4,
//             child: IgnorePointer(
//               ignoring: !isEmailEnabled,
//               child: CustomTextFormField(
//                 controller: _emailController,
//                 hintText: S.of(context).email,
//                 validator: (value) {
//                   final emailEmpty = value == null || value.trim().isEmpty;
//                   final phoneEntered = _hasUserTypedPhone;
//
//                   if (emailEmpty && !phoneEntered) {
//                     // neither real phone nor email
//                     return S.of(context).please_enter_your_email;
//                   }
//                   return null;
//                 },
//               ),
//             ),
//           ),
//
//           SizedBox(height: 12.h),
//
//           Center(
//             child: Text(
//               'OR',
//               style: AppStyle.styleRegular16(context).copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//
//           SizedBox(height: 12.h),
//
//           /// PHONE FIELD
//           Opacity(
//             opacity: isPhoneEnabled ? 1.0 : 0.4,
//             child: IgnorePointer(
//               ignoring: !isPhoneEnabled,
//               child: CustomPhoneNumberField(
//                 controller: _phoneNumberController,
//                 hintText: S.of(context).phone_Number,
//                 validator: (value) {
//                   final emailEmpty = _emailController.text.trim().isEmpty;
//                   final phoneEntered = _hasUserTypedPhone;
//
//                   if (emailEmpty && !phoneEntered) {
//                     // both empty (country code only is treated as empty)
//                     return S.of(context).please_enter_your_phone_number;
//                   }
//
//                   if (phoneEntered) {
//                     final digits = (_phoneNumberController.fullPhoneNumber ?? '')
//                         .replaceAll(RegExp(r'\D'), '');
//                     if (digits.length < 7) {
//                       return "Invalid Phone Number";
//                     }
//                   }
//
//                   return null;
//                 },
//               ),
//             ),
//           ),
//
//           SizedBox(height: 10.h),
//
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               S.of(context).otp_via_email_info,
//               style: AppStyle.styleRegular14(
//                 context,
//               ).copyWith(color: Colors.grey),
//             ),
//           ),
//
//           SizedBox(height: 20.h),
//
//           BlocConsumer<LoginCubit, LoginState>(
//             listener: (context, state) {
//               if (state is LoginLoaded) {
//                 AppToast.show(
//                   gravity: ToastGravity.TOP,
//                   backgroundColor: Colors.green,
//                   msg: state.message,
//                 );
//                 GoRouter.of(context).push(
//                   AppRouter.confirmPhoneNumberScreen,
//                   extra: widget.nextPath,
//                 );
//               }
//
//               if (state is LoginError) {
//                 AppToast.show(
//                   gravity: ToastGravity.TOP,
//                   backgroundColor: Colors.red,
//                   msg: state.error.message,
//                 );
//               }
//             },
//             builder: (context, state) {
//               return CustomElevatedButton(
//                 child: state is LoginLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                   S.of(context).login,
//                   style: AppStyle.styleRegular15(
//                     context,
//                   ).copyWith(color: Colors.white),
//                 ),
//                 onPressed: () {
//                   if (!formKey.currentState!.validate()) {
//                     return;
//                   }
//
//                   final email = _emailController.text.trim();
//                   final phoneRaw =
//                   (_phoneNumberController.fullPhoneNumber ?? '').trim();
//                   final phoneEntered = _hasUserTypedPhone;
//
//                   // Email has priority, phone only used if email is empty & phone is real
//                   final useEmail = email.isNotEmpty;
//                   final usePhone = !useEmail && phoneEntered;
//
//                   context.read<LoginCubit>().login(
//                     email: useEmail ? email : null,
//                     phone: usePhone ? phoneRaw : null,
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/auth/presentation/logic/login_cubit/login_cubit.dart';
import 'package:camion/features/auth/presentation/logic/guest_auth_cubit/guest_auth_cubit.dart';
import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';

// 🔽 cache imports
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    this.nextPath,
    this.requiresGuestBootstrapOnLogin = false,
  });
  final String? nextPath;
  final bool requiresGuestBootstrapOnLogin;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  late final PhoneNumberController _phoneNumberController;

  // ✅ Focus tracking (for "touched" behavior)
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  bool isEmailEnabled = true;
  bool isPhoneEnabled = true;
  bool _isPreparingGuestSession = false;

  @override
  void initState() {
    super.initState();
    _phoneNumberController = PhoneNumberController();

    // ✅ Focus listeners -> update helper on touch
    _emailFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _phoneFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // EMAIL LISTENER
    _emailController.addListener(() {
      final hasEmail = _emailController.text.trim().isNotEmpty;

      if (hasEmail && isPhoneEnabled) {
        setState(() {
          isPhoneEnabled = false; // keep country code
        });
      } else if (!hasEmail && !isPhoneEnabled && !_hasUserTypedPhone) {
        setState(() {
          isPhoneEnabled = true;
        });
      } else {
        setState(() {}); // update helper text live
      }
    });

    // PHONE LISTENER
    _phoneNumberController.addListener(() {
      final hasPhone = _hasUserTypedPhone;

      if (hasPhone && isEmailEnabled) {
        setState(() {
          isEmailEnabled = false;
        });
        _emailController.clear();
      } else if (!hasPhone &&
          !isEmailEnabled &&
          _emailController.text.isEmpty) {
        setState(() {
          isEmailEnabled = true;
        });
      } else {
        setState(() {}); // update helper text live
      }
    });
  }

  /// Treat "only country code" as EMPTY
  bool get _hasUserTypedPhone {
    final raw = _phoneNumberController.fullPhoneNumber;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 3; // country code only usually <= 3
  }

  String _orLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? 'أو'
        : 'Or';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneNumberController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          /// EMAIL FIELD
          Opacity(
            opacity: isEmailEnabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !isEmailEnabled,
              child: Focus(
                focusNode: _emailFocusNode,
                onFocusChange: (_) => setState(() {}),
                child: CustomTextFormField(
                  controller: _emailController,
                  hintText: S.of(context).email,
                  maxLines: 1,
                  validator: (value) {
                    final emailEmpty = value == null || value.trim().isEmpty;
                    final phoneEntered = _hasUserTypedPhone;
                    if (emailEmpty && !phoneEntered) {
                      return S.of(context).please_enter_your_email;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          Center(
            child: Text(
              _orLabel(context),
              style: AppStyle.styleRegular16(context).copyWith(
                fontStyle: FontStyle.normal,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          /// PHONE FIELD
          Opacity(
            opacity: isPhoneEnabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !isPhoneEnabled,
              child: Focus(
                focusNode: _phoneFocusNode,
                onFocusChange: (_) => setState(() {}),
                child: CustomPhoneNumberField(
                  controller: _phoneNumberController,
                  hintText: S.of(context).phone_Number,
                  validator: (value) {
                    final emailEmpty = _emailController.text.trim().isEmpty;
                    final phoneEntered = _hasUserTypedPhone;

                    if (emailEmpty && !phoneEntered) {
                      return S.of(context).please_enter_your_phone_number;
                    }

                    if (phoneEntered) {
                      final digits = _phoneNumberController.fullPhoneNumber
                          .replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7) return "Invalid Phone Number";
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          BlocConsumer<LoginCubit, LoginState>(
            listener: (context, state) async {
              if (state is LoginLoaded) {
                debugPrint(
                  '[AUTH][LOGIN] Session token received. Showing verification-success toast and navigating to OTP screen.',
                );
                final cache = sl<SecureCacheHelper>();
                final email = _emailController.text.trim();
                final phone = _phoneNumberController.phoneNumber.trim();
                final countryCode = _phoneNumberController.countryCode;
                final phoneEntered = _hasUserTypedPhone;

                if (email.isNotEmpty) {
                  await Future.wait([
                    cache.saveData(key: 'email', value: email),
                    cache.saveData(key: 'phoneNumber', value: ''),
                    cache.saveData(key: 'countryCode', value: ''),
                    cache.saveData(key: 'authLoginMethod', value: 'email'),
                  ]);
                } else if (phoneEntered) {
                  await Future.wait([
                    cache.saveData(key: 'phoneNumber', value: phone),
                    cache.saveData(key: 'countryCode', value: countryCode),
                    cache.saveData(key: 'email', value: ''),
                    cache.saveData(key: 'authLoginMethod', value: 'phone'),
                  ]);
                }

                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.green,
                  msg: 'Verification code sent successfully.',
                );

                if (!context.mounted) return;
                debugPrint(
                  '[AUTH][LOGIN] Navigating to confirmPhoneNumberScreen nextPath=${widget.nextPath ?? ''}',
                );
                GoRouter.of(context).push(
                  AppRouter.confirmPhoneNumberScreen,
                  extra: widget.nextPath,
                );
              }

              if (state is LoginError) {
                debugPrint(
                  '[AUTH][LOGIN] Login error before OTP screen: ${state.error.message}',
                );
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.red,
                  msg: state.error.message,
                );
              }
            },
            builder: (context, state) {
              final isLoginLoading = state is LoginLoading;
              final isBusy = isLoginLoading || _isPreparingGuestSession;
              return CustomElevatedButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        final guestAuthCubit = context.read<GuestAuthCubit>();
                        final loginCubit = context.read<LoginCubit>();
                        FocusManager.instance.primaryFocus?.unfocus();
                        if (!formKey.currentState!.validate()) return;

                        if (widget.requiresGuestBootstrapOnLogin) {
                          final cache = sl<SecureCacheHelper>();
                          final guestUUID =
                              (await cache.getData(key: 'guestUUID'))?.trim() ??
                              '';
                          final guestId =
                              (await cache.getData(key: 'guestId'))?.trim() ??
                              '';
                          final hasGuestIdentity =
                              guestUUID.isNotEmpty || guestId.isNotEmpty;
                          if (!hasGuestIdentity) {
                            if (!mounted) return;
                            setState(() => _isPreparingGuestSession = true);
                            final prepared = await guestAuthCubit.registerGuest(
                              silent: true,
                              forceRefresh: false,
                            );
                            if (!mounted) return;
                            setState(() => _isPreparingGuestSession = false);
                            if (!prepared) {
                              AppToast.show(
                                gravity: ToastGravity.TOP,
                                backgroundColor: Colors.red,
                                msg:
                                    'Unable to start a background guest session. Please try again.',
                              );
                              return;
                            }
                          }
                        }

                        final email = _emailController.text.trim();
                        final phoneNumber = _phoneNumberController.phoneNumber
                            .trim();
                        final countryCode = _phoneNumberController.countryCode;
                        final phoneEntered = _hasUserTypedPhone;

                        final useEmail = email.isNotEmpty;
                        final usePhone = !useEmail && phoneEntered;

                        loginCubit.login(
                          emailAddress: useEmail ? email : null,
                          countryCode: usePhone ? countryCode : null,
                          phoneNumber: usePhone ? phoneNumber : null,
                        );
                      },
                child: isBusy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        S.of(context).login,
                        style: AppStyle.styleButtonLabel14Regular(context),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
