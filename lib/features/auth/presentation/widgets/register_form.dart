import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/auth/presentation/logic/register_cubit/register_cubit.dart';
import 'package:camion/features/auth/presentation/widgets/custom_phone_number_controller.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, this.nextPath});

  final String? nextPath;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  late final PhoneNumberController _phoneNumberController;
  String? _selectedVerificationMethod;

  @override
  void initState() {
    super.initState();
    _phoneNumberController = PhoneNumberController();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void dismissKeyboard() {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    String? validatePhoneForCountry(String? value) {
      final raw = (value ?? '').trim();
      if (raw.isEmpty) {
        return S.of(context).please_enter_your_phone_number;
      }

      final isoRaw = _phoneNumberController.selectedCountry.code.trim();
      IsoCode? isoCode;
      try {
        if (isoRaw.isNotEmpty) {
          isoCode = IsoCode.values.byName(isoRaw.toUpperCase());
        }
      } catch (_) {
        isoCode = null;
      }

      if (isoCode != null) {
        try {
          final parsed = PhoneNumber.parse(raw, destinationCountry: isoCode);
          if (parsed.isValid()) {
            return null;
          }
        } catch (_) {
          // fall through to fallback checks
        }
      }

      final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
      final fallbackValid =
          digitsOnly.length >= 7 &&
          digitsOnly.length <= 15 &&
          RegExp(r'^\d+$').hasMatch(digitsOnly);
      if (fallbackValid) {
        return null;
      }

      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      return isArabic
          ? 'رقم الهاتف غير صالح لهذه الدولة'
          : 'Invalid phone number for selected country';
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFormField(
            controller: _fullNameController,
            hintText: S.of(context).full_name,
            maxLines: 1,
            inputFormatters: [
              AppInputFormatters.noEmoji,
              AppInputFormatters.fullNameNoSpecialCharacters,
            ],

            validator: (value) {
              final fullName = value?.trim() ?? '';
              if (fullName.isEmpty) {
                return S.of(context).please_enter_your_name;
              }
              if (!AppInputFormatters.isValidFullName(fullName)) {
                return "Only letters and spaces are allowed";
              }
              return null;
            },
          ),

          SizedBox(height: 10.h),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomPhoneNumberField(
                  controller: _phoneNumberController,
                  hintText: S.of(context).phone_Number,

                  validator: (value) {
                    return validatePhoneForCountry(value);
                  },
                ),
              ),

              // Expanded(child: Image.asset(Assets.imagesFlag)),
            ],
          ),

          SizedBox(height: 10.h),

          CustomTextFormField(
            controller: _emailController,
            hintText: S.of(context).email,
            maxLines: 1,

            validator: (value) {
              if (value == null || value.isEmpty) {
                return S.of(context).please_enter_your_email;
              }
              return null;
            },
          ),

          SizedBox(height: 20.h),

          BlocConsumer<RegisterCubit, RegisterState>(
            listener: (context, state) async {
              if (state is RegisterLoaded) {
                final method = _selectedVerificationMethod;
                if (!context.mounted || method == null) {
                  AppToast.show(
                    gravity: ToastGravity.TOP,
                    backgroundColor: Colors.red,
                    msg: 'Please select a verification method.',
                  );
                  return;
                }

                context.read<RegisterCubit>().sendVerificationOtp(
                  method: method,
                  emailAddress: _emailController.text.trim(),
                  countryCode: _phoneNumberController.countryCode,
                  phoneNumber: _phoneNumberController.phoneNumber.trim(),
                );
              }
              if (state is RegisterOtpSent) {
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.green,
                  msg: 'Verification code sent successfully.',
                );
                if (!context.mounted) return;
                GoRouter.of(context).push(
                  AppRouter.confirmPhoneNumberScreen,
                  extra: widget.nextPath,
                );
              }
              if (state is RegisterError) {
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.red,
                  msg: state.error.message,
                );
              }
            },
            builder: (context, state) {
              return CustomElevatedButton(
                onPressed:
                    state is RegisterLoading || state is RegisterOtpSending
                    ? null
                    : () async {
                        dismissKeyboard();
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        final method = await _showVerificationMethodSheet(
                          context,
                        );
                        if (!context.mounted || method == null) return;
                        _selectedVerificationMethod = method;

                        context.read<RegisterCubit>().register(
                          fullName: _fullNameController.text.trim(),
                          emailAddress: _emailController.text.trim(),
                          countryCode: _phoneNumberController.countryCode,
                          phoneNumber: _phoneNumberController.phoneNumber
                              .trim(),
                          registrationMethod: method,
                        );
                      },
                child: state is RegisterLoading || state is RegisterOtpSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        S.of(context).register,
                        style: AppStyle.styleButtonLabel14Regular(context),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _showVerificationMethodSheet(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                isArabic
                    ? 'اختر طريقة المتابعة للتحقق'
                    : 'Choose verification method',
                style: AppStyle.styleSectionTitle16Medium(
                  context,
                ).copyWith(color: Colors.black),
              ),
              SizedBox(height: 12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(sheetContext).pop('email'),
                title: Text(
                  isArabic
                      ? 'المتابعة عبر البريد الإلكتروني'
                      : 'Continue via Email',
                  style: AppStyle.styleInputField14Regular(
                    context,
                  ).copyWith(color: Colors.black),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(sheetContext).pop('phone'),
                title: Text(
                  isArabic ? 'المتابعة عبر رقم الهاتف' : 'Continue via Phone',
                  style: AppStyle.styleInputField14Regular(
                    context,
                  ).copyWith(color: Colors.black),
                ),
              ),
              SizedBox(height: 6.h),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}
