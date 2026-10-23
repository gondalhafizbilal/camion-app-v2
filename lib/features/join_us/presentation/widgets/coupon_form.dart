import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_text_form_field.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_input_formatters.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/create_coupon_cubit/create_coupon_cubit.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CouponForm extends StatefulWidget {
  const CouponForm({super.key});

  @override
  State<CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<CouponForm> {
  static final RegExp _yyyyMmDdRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController couponCodeController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  DateTime? selectedExpiryDate;

  @override
  void dispose() {
    couponCodeController.dispose();
    discountController.dispose();
    expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() {
      selectedExpiryDate = picked;
      expiryDateController.text =
          "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CouponFieldLabel(
            label: Localizations.localeOf(context).languageCode == 'ar'
                ? 'رمز القسيمة'
                : 'Coupon Code',
          ),
          SizedBox(height: 12.h),
          CustomTextFormField(
            controller: couponCodeController,
            hintText: Localizations.localeOf(context).languageCode == 'ar'
                ? 'مثال: HELLO123456'
                : 'eg. HELLO123456',
            inputFormatters: [AppInputFormatters.couponCodeAlphaNumericOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return S.of(context).please_enter_your_coupon_code;
              }
              return null;
            },
          ),
          SizedBox(height: 22.h),
          _CouponFieldLabel(
            label: Localizations.localeOf(context).languageCode == 'ar'
                ? 'النسبة'
                : 'Percentage',
          ),
          SizedBox(height: 12.h),
          CustomTextFormField(
            controller: discountController,
            hintText: Localizations.localeOf(context).languageCode == 'ar'
                ? 'مثال: 10'
                : 'e.g. 10',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              final discountText = (value ?? '').trim();
              if (discountText.isEmpty) {
                return S.of(context).please_enter_your_discount_rate;
              }
              final discount = int.tryParse(discountText);
              if (discount == null || discount < 1 || discount > 10) {
                return isArabic ? 'يجب أن تكون نسبة الخصم بين 1 و 10' : 'Discount must be between 1 and 10';
              }
              return null;
            },
          ),
          SizedBox(height: 22.h),
          _CouponFieldLabel(
            label: Localizations.localeOf(context).languageCode == 'ar'
                ? 'الصلاحية'
                : 'Validity',
          ),
          SizedBox(height: 12.h),
          CustomTextFormField(
            controller: expiryDateController,
            hintText: 'YYYY-MM-DD',
            readOnly: true,
            onTap: _pickExpiryDate,
            suffixIcon: const Icon(Icons.calendar_month_outlined),
            validator: (value) {
              final expiryText = (value ?? '').trim();
              if (expiryText.isEmpty) {
                return isArabic ? 'تاريخ انتهاء الصلاحية مطلوب' : 'Expiry date is required';
              }
              if (!_yyyyMmDdRegex.hasMatch(expiryText)) {
                return isArabic ? 'استخدم تنسيق YYYY-MM-DD' : 'Use YYYY-MM-DD format';
              }
              return null;
            },
          ),
          SizedBox(height: 28.h),
          BlocConsumer<CreateCouponCubit, CreateCouponState>(
            listener: (context, state) {
              if (state is CreateCouponSuccess) {
                FocusScope.of(context).unfocus();
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  msg: S.of(context).Coupon_created_successfully,
                  backgroundColor: Colors.green,
                );
                Navigator.pop(context);
              }

              if (state is CreateCouponError) {
                FocusScope.of(context).unfocus();
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  msg: state.error.message,
                  backgroundColor: Colors.red,
                );
              }
            },
            builder: (context, state) {
              return CustomElevatedButton(
                elevation: 0,
                onPressed: state is CreateCouponLoading
                    ? () {}
                    : () async {
                        final createCouponCubit = context.read<CreateCouponCubit>();
                        FocusManager.instance.primaryFocus?.unfocus();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 120),
                        );
                        if (!mounted) return;
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        createCouponCubit.createCoupon(
                          code: couponCodeController.text.trim(),
                          expiryDate: expiryDateController.text.trim(),
                          discountPercentage:
                              num.tryParse(discountController.text.trim()) ?? 0,
                        );
                      },
                child: state is CreateCouponLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(S.of(context).create),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CouponFieldLabel extends StatelessWidget {
  const _CouponFieldLabel({required this.label});

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
