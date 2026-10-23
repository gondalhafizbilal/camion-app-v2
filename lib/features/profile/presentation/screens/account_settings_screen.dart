import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/profile/presentation/logic/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/get_user_cubit/get_user_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/log_out_cubit/log_out_cubit.dart';
import 'package:camion/features/profile/presentation/widgets/custom_modal_bottom_sheet_profile.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  bool _isDeletionPending(GetUserState state) {
    if (state is! GetUserLoaded) return false;
    final user = state.user;
    return user.markedForDeletionAt != null && user.deletedAt == null;
  }

  String _deletionTileLabel(BuildContext context, bool deletionPending) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    if (deletionPending) {
      return isArabic ? 'تم وضع الحذف' : 'Deletion Marked';
    }
    return S.of(context).delete_account;
  }

  Future<void> _showDeletionMarkedDialog(BuildContext context) async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isArabic
                ? 'تم وضع الحساب قيد الحذف'
                : 'Account Marked for Deletion',
          ),
          content: Text(
            isArabic
                ? 'تم وضع حسابك قيد الحذف. عند تسجيل الدخول مرة أخرى يمكنك إلغاء طلب الحذف خلال 14 يوماً.'
                : 'Your account is marked for deletion. If you log in again, you can cancel the deletion request within 14 days.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return MultiBlocListener(
      listeners: [
        BlocListener<DeleteAccountCubit, DeleteAccountState>(
          listener: (context, state) {
            if (state is DeleteAccountSuccess) {
              final isArabic =
                  Localizations.localeOf(context).languageCode.toLowerCase() ==
                  'ar';
              if (state.action == DeleteAccountAction.requestDeletion) {
                _showDeletionMarkedDialog(context).then((_) async {
                  if (!context.mounted) return;
                  final success = await context.read<LogOutCubit>().logOut();
                  if (!context.mounted || !success) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تم تسجيل الخروج بنجاح'
                            : 'Logout successful',
                      ),
                    ),
                  );
                });
                return;
              }
              context.read<GetUserCubit>().getUserById();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is DeleteAccountFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error.message)));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 15.h)),
            CustomSliverAppBar(
              appBarHeight: 50.h,
              title: Text(
                S.of(context).settings,
                style: AppStyle.styleRegular18(
                  context,
                ).copyWith(color: AppColors.black),
              ),
              leading: GestureDetector(
                onTap: () {
                  AppNavigator.safePop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.black,
                  size: 24.sp,
                ),
              ),
              actions: const [],
            ),
            SliverToBoxAdapter(child: SizedBox(height: 15.h)),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: screenWidth > 800 ? 30.h : 12.h,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () {
                      customModalBottomSheetProfile(
                        title: S.of(context).are_you_sure_you_want_to_logout,
                        subTitle: S.of(context).logout_description,
                        screenWidth: screenWidth,
                        context: context,
                        contentBuilder: (bottomSheetContext) => Row(
                          children: [
                            Expanded(
                              child: CustomElevatedButton(
                                backgroundColor: AppColors.primaryColor,
                                child: Text(
                                  S.of(context).logout,
                                  style: AppStyle.styleRegular15(
                                    context,
                                  ).copyWith(color: Colors.white),
                                ),
                                onPressed: () async {
                                  final success = await context
                                      .read<LogOutCubit>()
                                      .logOut();
                                  if (!bottomSheetContext.mounted) return;
                                  if (!success) return;
                                  Navigator.of(bottomSheetContext).pop();
                                  if (!context.mounted) return;
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomElevatedButton(
                                borderColor: AppColors.primaryColor,
                                backgroundColor: AppColors.white,
                                textColor: AppColors.primaryColor,
                                child: Text(
                                  S.of(context).cancel,
                                  style: AppStyle.styleRegular15(
                                    context,
                                  ).copyWith(color: AppColors.primaryColor),
                                ),
                                onPressed: () {
                                  Navigator.of(bottomSheetContext).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: SvgPicture.asset(
                      Assets.imagesLogout,
                      width: 25.w,
                      height: 25.h,
                    ),
                    title: Text(
                      S.of(context).logout,
                      style: AppStyle.styleSemiBold15(context).copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: screenWidth > 800 ? 30.h : 15.h),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: screenWidth > 800 ? 30.h : 12.h,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: BlocBuilder<GetUserCubit, GetUserState>(
                    builder: (context, userState) {
                      final isArabic =
                          Localizations.localeOf(
                            context,
                          ).languageCode.toLowerCase() ==
                          'ar';
                      final deletionPending = _isDeletionPending(userState);

                      return ListTile(
                        onTap: () {
                          final title = deletionPending
                              ? (isArabic
                                    ? 'الحساب قيد الحذف'
                                    : 'Account Deletion Marked')
                              : (isArabic
                                    ? 'طلب حذف الحساب'
                                    : 'Request Account Deletion');
                          final policyNote = deletionPending
                              ? (isArabic
                                    ? 'تم وضع حسابك قيد الحذف. يمكنك استعادة الحساب خلال 14 يوماً من طلب الحذف عبر تسجيل الدخول والضغط على "إلغاء الحذف".'
                                    : 'Your account is currently marked for deletion. You can recover your account within 14 days of the deletion request by logging in and selecting "Cancel Deletion".')
                              : (isArabic
                                    ? 'لن يتم حذف الحساب فوراً. عند طلب الحذف سيتم وضع الحساب قيد الحذف لمدة 14 يوماً. بعد إرسال الطلب سيتم تسجيل خروجك، وعند تسجيل الدخول مرة أخرى يمكنك إلغاء طلب الحذف.'
                                    : 'Your account will not be deleted immediately. Once you request deletion, it will be marked for deletion for 14 days. After requesting deletion, you will be logged out, and logging in again lets you cancel the deletion request.');

                          customModalBottomSheetProfile(
                            title: title,
                            subTitle: policyNote,
                            screenWidth: screenWidth,
                            context: context,
                            contentBuilder: (bottomSheetContext) => Row(
                              children: [
                                Expanded(
                                  child: CustomElevatedButton(
                                    backgroundColor: AppColors.primaryColor,
                                    child: Text(
                                      deletionPending
                                          ? (isArabic
                                                ? 'إلغاء الحذف'
                                                : 'Cancel Deletion')
                                          : (isArabic
                                                ? 'طلب الحذف'
                                                : 'Request Deletion'),
                                      style: AppStyle.styleRegular15(
                                        context,
                                      ).copyWith(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      if (deletionPending) {
                                        context
                                            .read<DeleteAccountCubit>()
                                            .cancelDeletion();
                                      } else {
                                        context
                                            .read<DeleteAccountCubit>()
                                            .deleteAccount();
                                      }
                                      Navigator.of(bottomSheetContext).pop();
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: CustomElevatedButton(
                                    borderColor: AppColors.primaryColor,
                                    backgroundColor: AppColors.white,
                                    textColor: AppColors.primaryColor,
                                    child: Text(
                                      S.of(context).cancel,
                                      style: AppStyle.styleRegular15(
                                        context,
                                      ).copyWith(color: AppColors.primaryColor),
                                    ),
                                    onPressed: () {
                                      Navigator.of(bottomSheetContext).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        contentPadding: EdgeInsets.zero,
                        leading: SvgPicture.asset(
                          Assets.imagesAccountDelete,
                          width: 30.w,
                          height: 30.h,
                        ),
                        title: Text(
                          _deletionTileLabel(context, deletionPending),
                          style: AppStyle.styleSemiBold15(context).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
