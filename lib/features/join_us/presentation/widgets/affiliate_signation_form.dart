import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/features/join_us/presentation/widgets/gender_form_field.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AffiliateSignationForm extends StatefulWidget {
  const AffiliateSignationForm({
    super.key,
    required this.fullNameController,
    required this.genderController,
    required this.nationalityController,
    required this.bioController,
    this.onGenderChanged,
  });

  final TextEditingController fullNameController;
  final TextEditingController genderController;
  final TextEditingController nationalityController;
  final TextEditingController bioController;
  final Function(String?)? onGenderChanged;

  @override
  State<AffiliateSignationForm> createState() => _AffiliateSignationFormState();
}

class _AffiliateSignationFormState extends State<AffiliateSignationForm> {
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).personal_data,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Montes',
            height: 2,
          ),
        ),
        SizedBox(height: 24.h),
        _FormLabel(label: S.of(context).full_name),
        SizedBox(height: 12.h),
        CustomTextFormField(
          controller: widget.fullNameController,
          textInputAction: TextInputAction.next,
          hintText: Localizations.localeOf(context).languageCode == 'ar'
              ? 'مثال: أحمد محمد'
              : 'eg. Jack Daniels',
          inputFormatters: [AppInputFormatters.fullNameNoSpecialCharacters],
          validator: (value) {
            final fullName = value?.trim() ?? '';
            if (fullName.isEmpty) {
              return S.of(context).please_enter_your_name;
            }
            if (!AppInputFormatters.isValidFullName(fullName)) {
              return Localizations.localeOf(context).languageCode == 'ar'
                  ? 'يُسمح بالحروف والمسافات فقط'
                  : 'Only letters and spaces are allowed';
            }
            return null;
          },
        ),
        SizedBox(height: 22.h),
        _FormLabel(
          label: Localizations.localeOf(context).languageCode == 'ar'
              ? 'الجنس'
              : 'Gender',
        ),
        SizedBox(height: 12.h),
        GenderFormField(
          controller: widget.genderController,
          hintText: Localizations.localeOf(context).languageCode == 'ar'
              ? 'مثال: ذكر/أنثى'
              : 'eg. M/F',
          onSaved: (value) {
            selectedGender = value;

            if (widget.onGenderChanged != null) {
              widget.onGenderChanged!(value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).please_select_your_gender;
            }
            return null;
          },
        ),
        SizedBox(height: 22.h),
        _FormLabel(label: S.of(context).nationality),
        SizedBox(height: 12.h),
        CustomTextFormField(
          controller: widget.nationalityController,
          textInputAction: TextInputAction.next,
          hintText: Localizations.localeOf(context).languageCode == 'ar'
              ? 'مثال: قطر'
              : 'eg. Qatar',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).please_select_your_nationality;
            }
            return null;
          },
        ),
        SizedBox(height: 22.h),
        _FormLabel(label: S.of(context).about_you),
        SizedBox(height: 12.h),
        CustomTextFormField(
          controller: widget.bioController,
          textInputAction: TextInputAction.done,
          hintText: Localizations.localeOf(context).languageCode == 'ar'
              ? 'أخبرنا عن جمهورك ونوع المحتوى ولماذا تريد الانضمام لبرنامج التسويق بالعمولة.'
              : 'Tell us about your audience, content style, and why you want to join our affiliate program.',
          maxLines: 10,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).please_enter_your_bio;
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        fontFamily: 'Montes',
        height: 1.5,
      ),
    );
  }
}
