import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GenderFormField extends FormField<String> {
  GenderFormField({
    super.key,
    required TextEditingController controller,
    required String hintText,
    super.onSaved,
    FormFieldValidator<String>? validator,
    super.initialValue,
  }) : super(
         validator:
             validator ??
             (value) {
               if (value == null || value.isEmpty) {
                 final isArabic =
                     WidgetsBinding
                         .instance
                         .platformDispatcher
                         .locale
                         .languageCode ==
                     'ar';
                 return isArabic
                     ? 'يرجى اختيار الجنس'
                     : 'Please select a gender';
               }
               return null;
             },
         builder: (FormFieldState<String> state) {
           Future<void> openSheet() async {
             FocusManager.instance.primaryFocus?.unfocus();
             final value = await showModalBottomSheet<String>(
               context: state.context,
               useRootNavigator: true,
               shape: const RoundedRectangleBorder(
                 borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
               ),
               builder: (context) {
                 return SafeArea(
                   child: Padding(
                     padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       crossAxisAlignment: CrossAxisAlignment.start,
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
                         SizedBox(height: 16.h),
                         ListTile(
                           title: Text(
                             Localizations.localeOf(context).languageCode ==
                                     'ar'
                                 ? 'ذكر'
                                 : 'Male',
                           ),
                           onTap: () => Navigator.of(context).pop('male'),
                         ),
                         ListTile(
                           title: Text(
                             Localizations.localeOf(context).languageCode ==
                                     'ar'
                                 ? 'أنثى'
                                 : 'Female',
                           ),
                           onTap: () => Navigator.of(context).pop('female'),
                         ),
                       ],
                     ),
                   ),
                 );
               },
             );

             if (value == null || value.isEmpty) return;
             controller.text = value == 'male'
                 ? (Localizations.localeOf(state.context).languageCode == 'ar'
                       ? 'ذكر'
                       : 'Male')
                 : (Localizations.localeOf(state.context).languageCode == 'ar'
                       ? 'أنثى'
                       : 'Female');
             state.didChange(value);
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               CustomTextFormField(
                 controller: controller,
                 hintText: hintText,
                 readOnly: true,
                 onTap: openSheet,
                 suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                 validator: (_) => state.errorText,
               ),
             ],
           );
         },
       );
}
