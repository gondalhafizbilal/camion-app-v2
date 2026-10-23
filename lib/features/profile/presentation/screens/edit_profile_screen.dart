// import 'package:camion/config/widgets/custom_elevated_button.dart';
// import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
// import 'package:camion/config/widgets/custom_text_form_field.dart';
// import 'package:camion/core/utils/app_colors.dart';
// import 'package:camion/core/utils/app_images.dart';
// import 'package:camion/core/utils/app_style.dart';
// import 'package:camion/core/utils/navigation_utils.dart';
// import 'package:camion/features/profile/presentation/logic/cubit/update_user_cubit/update_user_cubit.dart';
// import 'package:camion/features/profile/presentation/screens/my_info.dart';
// import 'package:camion/generated/l10n.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:camion/core/utils/app_toast.dart';
// import 'package:go_router/go_router.dart';
//
// class EditInfoScreen extends StatefulWidget {
//   const EditInfoScreen({
//     super.key,
//     required this.fullName,
//     required this.phone,
//     required this.email,
//   });
//   final String fullName;
//   final String phone;
//   final String email;
//   @override
//   State<EditInfoScreen> createState() => _EditInfoScreenState();
// }
//
// class _EditInfoScreenState extends State<EditInfoScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//
//   late String currentFullName;
//   late String currentPhone;
//   late String currentEmail;
//
//   @override
//   void initState() {
//     currentFullName = widget.fullName;
//     currentPhone = widget.phone;
//     currentEmail = widget.email;
//
//     nameController.text = currentFullName;
//     phoneController.text = currentPhone;
//     emailController.text = currentEmail;
//     super.initState();
//   }
//
//   bool isEnabled = false;
//
//   void checkIfValuesChanged() {
//     bool hasChanged =
//         (nameController.text.isNotEmpty &&
//             nameController.text != currentFullName) ||
//         (emailController.text.isNotEmpty &&
//             emailController.text != currentEmail) ||
//         (phoneController.text.isNotEmpty &&
//             phoneController.text != currentPhone);
//
//     setState(() {
//       isEnabled = hasChanged;
//     });
//   }
//
//   @override
//   void dispose() {
//     nameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       resizeToAvoidBottomInset: false,
//       body: CustomScrollView(
//         slivers: [
//           SliverToBoxAdapter(child: SizedBox(height: 15.h)),
//           CustomSliverAppBar(
//             appBarHeight: 50.h,
//             title: Text(
//                S.of(context).edit_profile,
//               style: AppStyle.styleRegular18(
//                 context,
//               ).copyWith(color: AppColors.black, fontWeight: FontWeight.w500),
//             ),
//             isShownDivider: true,
//             leading: GestureDetector(
//               onTap: () {
//                 AppNavigator.safePop(context);
//               },
//               child: Icon(
//                 Icons.arrow_back,
//                 color: AppColors.black,
//                 size: 24.sp,
//               ),
//             ),
//             actions: [
//               Padding(
//                 padding: EdgeInsets.only(right: 10.w),
//                 child: SvgPicture.asset(
//                   width: 26.w,
//                   height: 26.h,
//                   Assets.imagesIconsActiveEditInfo,
//                 ),
//               ),
//             ],
//           ),
//           SliverToBoxAdapter(child: SizedBox(height: 25.h)),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(height: 20.h),
//                   SizedBox(height: 20.h),
//
//                   Row(
//                     children: [
//                       Text(
//                          S.of(context).full_name,
//                         style: AppStyle.styleRegular16(
//                           context,
//                         ).copyWith(color: Colors.black),
//                       ),
//                       SizedBox(width: 15.w),
//                       SvgPicture.asset(Assets.imagesIconsEditInfo),
//                     ],
//                   ),
//                   SizedBox(height: 8.h),
//
//                   CustomTextFormField(
//                     hintText:  S.of(context).full_name,
//                     controller: nameController,
//                     onChanged: (value) {
//                       checkIfValuesChanged();
//                     },
//                   ),
//
//                   SizedBox(height: 20.h),
//
//                   Row(
//                     children: [
//                       Text(
//                          S.of(context).email,
//                         style: AppStyle.styleRegular16(
//                           context,
//                         ).copyWith(color: Colors.black),
//                       ),
//                       SizedBox(width: 15.w),
//                       SvgPicture.asset(Assets.imagesIconsEditInfo),
//                     ],
//                   ),
//                   SizedBox(height: 8.h),
//
//                   CustomTextFormField(
//                     hintText:  S.of(context).email,
//                     controller: emailController,
//                     onChanged: (value) {
//                       checkIfValuesChanged();
//                     },
//                   ),
//
//                   SizedBox(height: 20.h),
//
//                   Row(
//                     children: [
//                       Text(
//                          S.of(context).phone_Number,
//                         style: AppStyle.styleRegular16(
//                           context,
//                         ).copyWith(color: Colors.black),
//                       ),
//                       SizedBox(width: 15.w),
//                       SvgPicture.asset(Assets.imagesIconsEditInfo),
//                     ],
//                   ),
//                   SizedBox(height: 8.h),
//
//                   CustomTextFormField(
//                     hintText:  S.of(context).phone_Number,
//                     controller: phoneController,
//                     onChanged: (value) {
//                       checkIfValuesChanged();
//                     },
//                   ),
//
//                   SizedBox(height: 30.h),
//
//                   BlocConsumer<UpdateUserCubit, UpdateUserState>(
//                     listener: (context, state) {
//                       if (state is UpdateUserLoaded) {
//                         currentFullName = nameController.text;
//                         currentEmail = emailController.text;
//                         currentPhone = phoneController.text;
//
//                         setState(() {
//                           isEnabled = false;
//                         });
//
//                         AppToast.show(
//                           gravity: ToastGravity.TOP,
//                           backgroundColor: Colors.green,
//                           msg: S.of(context).profile_updated_successfully,
//                         );
//                         MyInfoScreen.profileKey.currentState!.refreshGetUser();
//                       }
//                       if (state is UpdateUserError) {
//                         AppToast.show(
//                           gravity: ToastGravity.TOP,
//                           backgroundColor: Colors.red,
//                           msg: state.error.message,
//                         );
//                       }
//                     },
//                     builder: (context, state) {
//                       return CustomElevatedButton(
//                         backgroundColor: isEnabled
//                             ? AppColors.primaryColor
//                             : Colors.grey,
//                         onPressed: isEnabled
//                             ? () {
//                                 context.read<UpdateUserCubit>().updateUser(
//                                   data: {
//                                     "fullName": nameController.text,
//                                     "email": emailController.text,
//                                     "phone": phoneController.text,
//                                   },
//                                 );
//                               }
//                             : () {},
//                         child: state is UpdateUserLoading
//                             ? const CircularProgressIndicator(
//                                 color: Colors.white,
//                               )
//                             : Text(
//                                  S.of(context).save,
//                                 style: AppStyle.styleRegular16(
//                                   context,
//                                 ).copyWith(color: Colors.white),
//                               ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/auth/presentation/widgets/phone_number_controller.dart';
import 'package:camion/features/profile/presentation/logic/cubit/update_user_cubit/update_user_cubit.dart';
import 'package:camion/features/profile/presentation/screens/my_info.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camion/core/utils/app_toast.dart';

import '../../../auth/presentation/widgets/custom_phone_number_controller.dart';

class EditInfoScreen extends StatefulWidget {
  const EditInfoScreen({
    super.key,
    required this.fullName,
    required this.phone,
    required this.email,
  });

  final String fullName;
  final String phone; // API returns like +9715xxxxxxx
  final String email;

  @override
  State<EditInfoScreen> createState() => _EditInfoScreenState();
}

class _EditInfoScreenState extends State<EditInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final PhoneNumberController _phoneNumberController = PhoneNumberController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  late String currentFullName;
  late String currentEmail;
  late String currentPhone;

  bool isEnabled = false;

  @override
  void initState() {
    super.initState();

    currentFullName = widget.fullName;
    currentEmail = widget.email;
    currentPhone = widget.phone;

    nameController.text = currentFullName;
    emailController.text = currentEmail;

    _initPhoneFromProfile(currentPhone);

    // ✅ Recalculate button enabled state when any field changes
    nameController.addListener(_recalcEnabled);
    emailController.addListener(_recalcEnabled);

    // ✅ Phone changes listener (instead of CustomPhoneNumberField.onChanged)
    _phoneNumberController.phoneController.addListener(_recalcEnabled);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _initPhoneFromProfile(String rawPhone) {
    final phone = rawPhone.trim();
    if (phone.isEmpty) return;

    // ✅ Your controller parses +dialCode and selects correct country
    _phoneNumberController.fullPhoneNumber = phone;
  }

  /// Build payload with all required profile fields
  Map<String, dynamic> _buildUpdatePayload() {
    final data = <String, dynamic>{};

    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();

    final effectiveName = newName.isNotEmpty ? newName : currentFullName.trim();
    if (effectiveName.isNotEmpty &&
        AppInputFormatters.isValidFullName(effectiveName)) {
      data['fullName'] = effectiveName;
    }

    final effectiveEmail = newEmail.isNotEmpty ? newEmail : currentEmail.trim();
    if (effectiveEmail.isNotEmpty) {
      data['emailAddress'] = effectiveEmail;
    }

    final phoneParts = _resolvePhonePayload();
    if (phoneParts.$1.isNotEmpty && phoneParts.$2.isNotEmpty) {
      data['countryCode'] = phoneParts.$1;
      data['phoneNumber'] = phoneParts.$2;
    }

    return data;
  }

  (String, String) _resolvePhonePayload() {
    // Prefer current controller values; fall back to the persisted phone string.
    final countryCode = _phoneNumberController.countryCode.trim();
    final phoneNumber = _phoneNumberController.phoneNumber.trim();
    if (countryCode.isNotEmpty && phoneNumber.isNotEmpty) {
      return (countryCode, phoneNumber);
    }

    final raw = currentPhone.trim();
    if (raw.isEmpty) return ('', '');

    final match = RegExp(r'^\+\d{1,4}').firstMatch(raw);
    if (match == null) {
      return ('', raw.replaceAll(RegExp(r'\s+'), ' ').trim());
    }
    final code = match.group(0)?.trim() ?? '';
    final number = raw
        .substring(match.end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return (code, number);
  }

  bool _hasAnyEditableFieldChanged() {
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();
    final phoneEntered = _phoneNumberController.hasUserInput;

    final nameChanged = newName.isNotEmpty && newName != currentFullName;
    final emailChanged = newEmail.isNotEmpty && newEmail != currentEmail;
    final phoneChanged = phoneEntered && _isPhoneChanged();

    return nameChanged || emailChanged || phoneChanged;
  }

  bool _isPhoneChanged() {
    final currentDigits = _digitsOnly(currentPhone);
    final newDigits = _digitsOnly(_phoneNumberController.fullPhoneNumber);
    if (newDigits.isEmpty) return false;
    return newDigits != currentDigits;
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  void _recalcEnabled() {
    if (mounted) setState(() => isEnabled = _hasAnyEditableFieldChanged());
  }

  void _applyCurrentValuesFromSentPayload(Map<String, dynamic> sent) {
    if (sent.containsKey('fullName')) {
      currentFullName = nameController.text.trim();
    }
    if (sent.containsKey('emailAddress')) {
      currentEmail = emailController.text.trim();
    }
    if (sent.containsKey('phoneNumber')) {
      currentPhone = _phoneNumberController.fullPhoneNumber.trim();
    }
    if (mounted) setState(() => isEnabled = false);
  }

  String _invalidFullNameText(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lang == 'ar') {
      return 'الاسم الكامل يجب أن يحتوي على أحرف ومسافات فقط';
    }
    return 'Full name can contain only letters and spaces';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          CustomSliverAppBar(
            appBarHeight: 50.h,
            title: Text(
              S.of(context).edit_profile,
              style: AppStyle.styleRegular18(
                context,
              ).copyWith(color: AppColors.black, fontWeight: FontWeight.w500),
            ),
            isShownDivider: false,
            leading: GestureDetector(
              onTap: () => AppNavigator.safePop(context),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 24.sp,
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: SvgPicture.asset(
                  width: 26.w,
                  height: 26.h,
                  Assets.imagesIconsActiveEditInfo,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SizedBox(height: 25.h)),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // ---------- Name ----------
                  Row(
                    children: [
                      Text(
                        S.of(context).full_name,
                        style: AppStyle.styleRegular16(
                          context,
                        ).copyWith(color: Colors.black),
                      ),
                      SizedBox(width: 15.w),
                      SvgPicture.asset(Assets.imagesIconsEditInfo),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  CustomTextFormField(
                    hintText: S.of(context).full_name,
                    controller: nameController,
                    focusNode: _nameFocusNode,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _dismissKeyboard(),
                    inputFormatters: [
                      AppInputFormatters.noEmoji,
                      AppInputFormatters.fullNameNoSpecialCharacters,
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // ---------- Email ----------
                  Row(
                    children: [
                      Text(
                        S.of(context).email,
                        style: AppStyle.styleRegular16(
                          context,
                        ).copyWith(color: Colors.black),
                      ),
                      SizedBox(width: 15.w),
                      SvgPicture.asset(Assets.imagesIconsEditInfo),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  CustomTextFormField(
                    hintText: S.of(context).email,
                    controller: emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _dismissKeyboard(),
                  ),

                  SizedBox(height: 20.h),

                  // ---------- Phone ----------
                  Row(
                    children: [
                      Text(
                        S.of(context).phone_Number,
                        style: AppStyle.styleRegular16(
                          context,
                        ).copyWith(color: Colors.black),
                      ),
                      SizedBox(width: 15.w),
                      SvgPicture.asset(Assets.imagesIconsEditInfo),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  Opacity(
                    opacity: 1.0,
                    child: IgnorePointer(
                      ignoring: false,
                      child: Focus(
                        focusNode: _phoneFocusNode,
                        onFocusChange: (_) => setState(() {}),
                        child: CustomPhoneNumberField(
                          controller: _phoneNumberController,
                          hintText: S.of(context).phone_Number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _dismissKeyboard(),
                          validator: (value) {
                            final emailEmpty = emailController.text
                                .trim()
                                .isEmpty;
                            final phoneEntered =
                                _phoneNumberController.hasUserInput;

                            if (emailEmpty && !phoneEntered) {
                              return S
                                  .of(context)
                                  .please_enter_your_phone_number;
                            }

                            if (phoneEntered) {
                              final digits = _phoneNumberController
                                  .fullPhoneNumber
                                  .replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 7) {
                                return Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'ar'
                                    ? 'رقم الهاتف غير صالح'
                                    : 'Invalid Phone Number';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  BlocConsumer<UpdateUserCubit, UpdateUserState>(
                    listener: (context, state) {
                      if (state is UpdateUserLoaded) {
                        final sent = _buildUpdatePayload();
                        _applyCurrentValuesFromSentPayload(sent);

                        AppToast.show(
                          gravity: ToastGravity.TOP,
                          backgroundColor: Colors.green,
                          msg: S.of(context).profile_updated_successfully,
                        );

                        MyInfoScreen.profileKey.currentState?.refreshGetUser();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(true);
                        }
                      }

                      if (state is UpdateUserError) {
                        AppToast.show(
                          gravity: ToastGravity.TOP,
                          backgroundColor: Colors.red,
                          msg: state.error.message,
                        );
                      }
                    },
                    builder: (context, state) {
                      return CustomElevatedButton(
                        backgroundColor: isEnabled
                            ? AppColors.primaryColor
                            : Colors.grey,
                        onPressed: !isEnabled
                            ? () {}
                            : () {
                                _dismissKeyboard();
                                final data = _buildUpdatePayload();
                                final newName = nameController.text.trim();
                                final changedName = newName != currentFullName;
                                if (changedName &&
                                    !AppInputFormatters.isValidFullName(
                                      newName,
                                    )) {
                                  AppToast.show(
                                    gravity: ToastGravity.TOP,
                                    backgroundColor: Colors.red,
                                    msg: _invalidFullNameText(context),
                                  );
                                  return;
                                }
                                if (data.isEmpty) return;
                                context.read<UpdateUserCubit>().updateUser(
                                  data: data,
                                );
                              },
                        child: state is UpdateUserLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                S.of(context).save,
                                style: AppStyle.styleRegular16(
                                  context,
                                ).copyWith(color: Colors.white),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ),
        ],
      ),
    );
  }
}
