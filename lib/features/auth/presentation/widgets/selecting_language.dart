import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _LoginLanguageOption {
  const _LoginLanguageOption({
    required this.code,
    required this.labelEn,
    required this.labelAr,
  });

  final String code;
  final String labelEn;
  final String labelAr;
}

class SelectingLanguage extends StatefulWidget {
  const SelectingLanguage({
    super.key,
    required TextEditingController languageController,
  }) : _languageController = languageController;

  final TextEditingController _languageController;

  @override
  State<SelectingLanguage> createState() => _SelectingLanguageState();
}

class _SelectingLanguageState extends State<SelectingLanguage> {
  static const List<_LoginLanguageOption> _options = [
    _LoginLanguageOption(code: 'en', labelEn: 'English', labelAr: 'الإنجليزية'),
    _LoginLanguageOption(code: 'ar', labelEn: 'Arabic', labelAr: 'العربية'),
  ];

  void _showCountryPicker() async {
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return ListView(
          shrinkWrap: true,
          children: _options.map((option) {
            final label = isArabic ? option.labelAr : option.labelEn;
            return ListTile(
              title: Text(label, textAlign: TextAlign.left),
              trailing: Text(
                option.code.toUpperCase(),
                style: AppStyle.styleRegular14(
                  context,
                ).copyWith(color: AppColors.gray),
              ),
              onTap: () => Navigator.of(context).pop(option.code),
            );
          }).toList(),
        );
      },
    );

    if (selectedLanguage != null) {
      if (!mounted) return;
      await context.read<LocalizationsCubit>().changeLocale(
        locale: Locale(selectedLanguage),
      );
      if (!mounted) return;
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final selected = _options.firstWhere(
        (item) => item.code == selectedLanguage,
      );
      setState(() {
        widget._languageController.text = isArabic
            ? selected.labelAr
            : selected.labelEn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: widget._languageController,
      hintText: S.of(context).language,

      suffixIcon: GestureDetector(
        onTap: _showCountryPicker,
        child: Container(
          padding: EdgeInsets.all(12.h),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade700,
            size: 24.r,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return Localizations.localeOf(context).languageCode == 'ar'
              ? 'الرجاء إدخال ${S.of(context).language}'
              : 'Please enter ${S.of(context).language.toLowerCase()}';
        }
        return null;
      },
    );
  }
}
