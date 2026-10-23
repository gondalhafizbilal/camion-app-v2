import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/Affiliate_sign_cubit/affiliate_sign_cubit.dart';
import 'package:camion/features/join_us/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:camion/features/join_us/presentation/widgets/affiliate_signation_form.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';

class JoinUsScreen extends StatefulWidget {
  const JoinUsScreen({super.key});

  @override
  State<JoinUsScreen> createState() => _JoinUsScreenState();
}

class _JoinUsScreenState extends State<JoinUsScreen> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String? selectedGender;

  String _pleaseSelectGenderText(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lang == 'ar') return 'يرجى اختيار الجنس';
    return 'Please select a gender';
  }

  @override
  void dispose() {
    fullNameController.dispose();
    genderController.dispose();
    nationalityController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                CustomJoinUsSliverAppBar(
                  title: S.of(context).join_us_as_affiliate,
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 110.h),
                      child: Form(
                        key: formKey,
                        child: AffiliateSignationForm(
                          fullNameController: fullNameController,
                          genderController: genderController,
                          nationalityController: nationalityController,
                          bioController: bioController,
                          onGenderChanged: (gender) {
                            selectedGender = gender;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 16.h,
              left: 16.w,
              right: 16.w,
              child: BlocConsumer<AffiliateSignCubit, AffiliateSignState>(
                listener: (context, state) {
                  if (state is AffiliateSignSuccess) {
                    final fromProfile =
                        GoRouterState.of(
                          context,
                        ).uri.queryParameters['fromProfile'] ==
                        '1';
                    final target = fromProfile
                        ? '${AppRouter.affiliateCheckScreen}?fromProfile=1'
                        : AppRouter.affiliateCheckScreen;
                    GoRouter.of(context).pushReplacement(target);
                  }
                  if (state is AffiliateSignError) {
                    AppToast.show(
                      msg: state.error.message,
                      backgroundColor: Colors.red,
                      gravity: ToastGravity.TOP,
                    );
                  }
                },
                builder: (context, state) {
                  return CustomElevatedButton(
                    onPressed: state is AffiliateSignLoading
                        ? () {}
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            formKey.currentState!.save();

                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            if (selectedGender == null ||
                                selectedGender!.isEmpty) {
                              AppToast.show(
                                msg: _pleaseSelectGenderText(context),
                                backgroundColor: Colors.red,
                              );
                              return;
                            }

                            context.read<AffiliateSignCubit>().signSupplier(
                              name: fullNameController.text,
                              nationality: nationalityController.text,
                              gender: selectedGender!,
                              bio: bioController.text,
                            );
                          },
                    child: state is AffiliateSignLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(S.of(context).next),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
