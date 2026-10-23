import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/join_us_influencers/data/models/social_media_selecting_model.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/toggle_social_media_cubit/toggle_social_media_selecting_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SelectInfluencerSocialMediaScreen extends StatelessWidget {
  const SelectInfluencerSocialMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) =>
        Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
    final socialMedia = [
      SocialMediaSelectingModel(
        title: t("Facebook", "فيسبوك"),
        socialMediaLogo: Assets.imagesLogosFacebook,
        selectingCheckBox: false,
      ),
      SocialMediaSelectingModel(
        title: t("Google", "جوجل"),
        socialMediaLogo: Assets.imagesGoogleIcon,
        selectingCheckBox: false,
      ),
      SocialMediaSelectingModel(
        title: t("Snapchat", "سناب شات"),
        socialMediaLogo: Assets.imagesSnapChat,
        selectingCheckBox: false,
      ),
      SocialMediaSelectingModel(
        title: t("Instagram", "انستجرام"),
        socialMediaLogo: Assets.imagesInstagram,
        selectingCheckBox: false,
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CustomJoinUsSliverAppBar(
                title: S.of(context).join_us_as_influencer,
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    t(
                      "Which social platforms do you prefer to publish your ads on?",
                      "أي من المنصات التالية تفضل وضع إعلاناتك بها",
                    ),
                    style: AppStyle.styleRegular15(context).copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 10.h)),

              SliverList.builder(
                itemCount: socialMedia.length,
                itemBuilder: (context, index) {
                  return BlocSelector<
                    ToggleInfluencerSocialMediaSelectingCubit,
                    ToggleSocialMediaSelectingState,
                    bool
                  >(
                    selector: (state) => state.selectedIndexes.contains(index),
                    builder: (context, isSelected) {
                      return GestureDetector(
                        onTap: () {
                          context
                              .read<ToggleInfluencerSocialMediaSelectingCubit>()
                              .toggle(index);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withAlpha(15)
                                : AppColors.backgroundGray,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              index == 2
                                  ? Image.asset(Assets.imagesSnapChatPng)
                                  : SvgPicture.asset(
                                      socialMedia[index].socialMediaLogo,
                                      width: 30.w,
                                      height: 30.h,
                                    ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  socialMedia[index].title,
                                  style: AppStyle.styleRegular14(context)
                                      .copyWith(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              SvgPicture.asset(
                                isSelected
                                    ? Assets.imagesSelectedCheckbox
                                    : Assets.imagesNotSelectedCheckbox,
                                width: 24.w,
                                height: 24.h,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          Positioned(
            bottom: 16.h,
            left: 16.w,
            right: 16.w,
            child: CustomElevatedButton(
              child: Text(
                S.of(context).next,
                style: AppStyle.styleRegular15(
                  context,
                ).copyWith(color: Colors.white),
              ),
              onPressed: () {
                GoRouter.of(context).push(AppRouter.selectCoutriesOfInfluencer);
              },
            ),
          ),
        ],
      ),
    );
  }
}
