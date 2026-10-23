import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/config/widgets/section_top_header.dart';
import 'package:camion/features/profile/data/models/get_user_model/user_model.dart';
import 'package:camion/features/profile/data/repository/profie_repo.dart';
import 'package:camion/features/profile/presentation/logic/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/get_user_cubit/get_user_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/log_out_cubit/log_out_cubit.dart';
import 'package:camion/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/features/join_us/data/repository/supplier_repo.dart'
    as affiliate_repo;
import 'package:camion/features/join_us_influencers/data/repository/supplier_repo.dart'
    as influencer_repo;
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<AuthSessionNotifier>(),
      builder: (context, _) {
        if (!sl<AuthSessionNotifier>().isLoggedIn) {
          return const _GuestProfileScreen();
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => LogOutCubit()),
            BlocProvider(
              create: (context) => DeleteAccountCubit(sl<ProfileRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  GetUserCubit(sl<ProfileRepository>())..getUserById(),
            ),
          ],
          child: const _ProfileScreenBody(),
        );
      },
    );
  }
}

class _GuestProfileScreen extends StatelessWidget {
  const _GuestProfileScreen();

  String _tr(BuildContext context, {required String en, required String ar}) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? ar
        : en;
  }

  @override
  Widget build(BuildContext context) {
    final next = Uri.encodeComponent(
      '${AppRouter.selectingFromBottomNavBar}?tab=4',
    );

    return Scaffold(
      backgroundColor: ProfileDesignSystem.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 24.h),
          child: Column(
            children: [
              _ProfileHeader(
                onSettingsTap: () => context.push(AppRouter.settings),
                onNotificationsTap: () =>
                    context.push(AppRouter.notificationScreen),
                useSettingsAsFirstIcon: true,
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 343.w,
                    constraints: BoxConstraints(minHeight: 252.h),
                    padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 18.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.h,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD72631),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              _tr(
                                context,
                                en: 'Login for a better experience!',
                                ar: 'سجل الدخول للحصول على تجربة أفضل!',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montes',
                                height: 24 / 16,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18.w),
                              child: Text(
                                _tr(
                                  context,
                                  en: 'Sign in to manage your profile, orders, and preferences.',
                                  ar: 'سجل الدخول لإدارة ملفك الشخصي وطلباتك وتفضيلاتك.',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 14.sp,
                                  height: 24 / 14,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Montes',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: 295.w,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.push('${AppRouter.login}?next=$next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD72631),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _tr(context, en: 'Log In', ar: 'تسجيل الدخول'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montes',
                                height: 24 / 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

  String _withFromProfile(String route) {
    final separator = route.contains('?') ? '&' : '?';
    return '$route${separator}fromProfile=1';
  }

  static final Uri _androidRateUri = Uri.parse(
    'market://details?id=com.camiontrading.app',
  );
  static final Uri _androidFallbackUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.camiontrading.app',
  );
  static final Uri _iosRateUri = Uri.parse(
    'itms-apps://itunes.apple.com/app/id6758658533?action=write-review',
  );
  static final Uri _iosFallbackUri = Uri.parse(
    'https://apps.apple.com/gh/app/camion-trading-%D9%83%D9%85%D9%8A%D9%88%D9%86/id6758658533',
  );

  String _tr(BuildContext context, {required String en, required String ar}) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? ar
        : en;
  }

  bool _isDeletionPending(GetUserModel user) {
    return user.markedForDeletionAt != null && user.deletedAt == null;
  }

  String _deleteTileLabel(BuildContext context, GetUserModel user) {
    final pending = _isDeletionPending(user);
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    if (pending) {
      return isArabic ? 'تم وضع الحذف' : 'Deletion Marked';
    }
    return S.of(context).delete_account;
  }

  Future<_CachedProfileContact> _loadCachedProfileContact() async {
    final cache = sl<SecureCacheHelper>();
    final email = ((await cache.getData(key: 'email')) ?? '').trim();
    final phone = ((await cache.getData(key: 'phoneNumber')) ?? '').trim();
    final authLoginMethod =
        ((await cache.getData(key: 'authLoginMethod')) ?? '')
            .trim()
            .toLowerCase();
    return _CachedProfileContact(
      email: email,
      phone: phone,
      authLoginMethod: authLoginMethod.isEmpty ? null : authLoginMethod,
    );
  }

  Future<void> _openRateUs(BuildContext context) async {
    final platform = defaultTargetPlatform;
    final isIos = platform == TargetPlatform.iOS;
    final primary = isIos ? _iosRateUri : _androidRateUri;
    final fallback = isIos ? _iosFallbackUri : _androidFallbackUri;

    if (await canLaunchUrl(primary)) {
      await launchUrl(primary, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            context,
            en: 'Unable to open store right now.',
            ar: 'تعذر فتح المتجر حالياً.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state is DeleteAccountSuccess) {
          if (state.action == DeleteAccountAction.requestDeletion) {
            _showDeletionMarkedDialog(context).then((_) async {
              if (!context.mounted) return;
              final success = await context.read<LogOutCubit>().logOut();
              if (!context.mounted || !success) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _tr(
                      context,
                      en: 'Logout successful',
                      ar: 'تم تسجيل الخروج بنجاح',
                    ),
                  ),
                ),
              );
            });
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          context.read<GetUserCubit>().getUserById();
        }

        if (state is DeleteAccountFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error.message)));
        }
      },
      child: Scaffold(
        backgroundColor: ProfileDesignSystem.pageBackground,
        body: SafeArea(
          child: BlocBuilder<GetUserCubit, GetUserState>(
            builder: (context, state) {
              final user = state is GetUserLoaded
                  ? state.user
                  : _fallbackUser();

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      10.h,
                      16.w,
                      ProfileDesignSystem.bottomSafeSpacing.h,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: isArabic
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          _ProfileHeader(
                            onSettingsTap: () => context.push(
                              _withFromProfile(AppRouter.settings),
                            ),
                            onNotificationsTap: () => context.push(
                              _withFromProfile(AppRouter.notificationScreen),
                            ),
                          ),
                          if (AppConfig.instance.flavor.isDevelopment) ...[
                            SizedBox(height: 8.h),
                            Align(
                              alignment: isArabic
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD72631,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999.r),
                                  border: Border.all(
                                    color: const Color(0xFFD72631),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'Development',
                                  style: TextStyle(
                                    color: const Color(0xFFD72631),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Montes',
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 22.h),
                          FutureBuilder<_CachedProfileContact>(
                            future: _loadCachedProfileContact(),
                            builder: (context, snapshot) {
                              final cached = snapshot.data;
                              final resolvedEmail = user.email.trim().isNotEmpty
                                  ? user.email.trim()
                                  : (cached?.email ?? '');
                              final resolvedPhone = user.phone.trim().isNotEmpty
                                  ? user.phone.trim()
                                  : (cached?.phone ?? '');
                              final resolvedMethod = cached?.authLoginMethod;

                              return _EmailCard(
                                email: resolvedEmail,
                                phone: resolvedPhone,
                                authLoginMethod: resolvedMethod,
                              );
                            },
                          ),
                          SizedBox(height: 24.h),
                          ProfileSectionTitle(
                            title: _tr(
                              context,
                              en: 'Overview',
                              ar: 'نظرة عامة',
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).personal_information,
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.myInfo),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: _tr(
                              context,
                              en: 'My Addresses',
                              ar: 'عناويني',
                            ),
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.myAddresses),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).my_orders,
                            onTap: () => context.push(AppRouter.myOrders),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: _tr(context, en: 'My Coupons', ar: 'قسائمي'),
                            onTap: () => _openCoupons(context, user),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: _tr(
                              context,
                              en: 'Affiliator Dashboard',
                              ar: 'لوحة المسوق بالعمولة',
                            ),
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.affiliateCheckScreen),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: _tr(
                              context,
                              en: 'Influencer Dashboard',
                              ar: 'لوحة المؤثر',
                            ),
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.influencerCheckScreen),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).give_us_feedback,
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.feedBackScreen),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).rate_us,
                            onTap: () => _openRateUs(context),
                          ),
                          SizedBox(height: 24.h),
                          ProfileSectionTitle(
                            title: _tr(context, en: 'General', ar: 'عام'),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: _tr(
                              context,
                              en: 'Camion Chatbot',
                              ar: 'مساعد كاميون الذكي',
                            ),
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.chatbot),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).language,
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.changeLanuage),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).currency,
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.changeCurrency),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).privacy_policy,
                            onTap: () => context.push(
                              _withFromProfile(AppRouter.privacyScreen),
                            ),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: S.of(context).help,
                            onTap: () =>
                                context.push(_withFromProfile(AppRouter.help)),
                          ),
                          SizedBox(
                            height: ProfileDesignSystem.sectionSpacing.h,
                          ),
                          _ProfileActionTile(
                            label: _deleteTileLabel(context, user),
                            textColor: const Color(0xFFD92B2B),
                            onTap: () => _showDeleteDialog(context, user),
                          ),
                          SizedBox(height: 24.h),
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: ProfileDesignSystem.maxCardWidth.w,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: () => _showLogoutDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ProfileDesignSystem.accent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: Text(
                                    S.of(context).logout,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Montes',
                                      height: 24 / 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  GetUserModel _fallbackUser() {
    return GetUserModel(
      id: '',
      email: '',
      phone: '',
      fullName: '',
      isActive: false,
      code: '',
      role: '',
      notificationToken: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool _isInfluencerType(String? type) {
    final normalized = (type ?? '').trim().toLowerCase();
    return normalized.contains('influencer');
  }

  bool _isAffiliateType(String? type) {
    final normalized = (type ?? '').trim().toLowerCase();
    return normalized.contains('affiliate');
  }

  bool _isNotRegisteredMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('no affiliate') ||
        normalized.contains('no influencer');
  }

  bool _isRegisteredAsOtherRoleMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') &&
        (normalized.contains('affiliate') || normalized.contains('influencer'));
  }

  Future<void> _showCouponRegistrationChoice(BuildContext context) async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isArabic
                      ? 'أنت غير مسجل كمسوق أو مؤثر'
                      : 'You are not registered as affiliate or influencer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isArabic
                      ? 'اختر الطريقة التي تريد التسجيل بها للمتابعة'
                      : 'Choose how you want to register to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                    fontSize: 13.sp,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      _withFromProfile(AppRouter.affiliateCheckScreen),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileDesignSystem.accent,
                    foregroundColor: Colors.white,
                    minimumSize: Size.fromHeight(44.h),
                  ),
                  child: Text(
                    isArabic ? 'التسجيل كمسوق' : 'Register as Affiliate',
                  ),
                ),
                SizedBox(height: 10.h),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      _withFromProfile(AppRouter.influencerCheckScreen),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(44.h),
                  ),
                  child: Text(
                    isArabic ? 'التسجيل كمؤثر' : 'Register as Influencer',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCoupons(BuildContext context, GetUserModel user) async {
    final role = user.role.toLowerCase();
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.isEmpty) {
      if (!context.mounted) return;
      context.push(_withFromProfile(AppRouter.login));
      return;
    }

    final affiliateRepo = sl<affiliate_repo.AffiliateRepository>();
    final influencerRepo = sl<influencer_repo.InfluencerRepository>();

    final affiliateFuture = affiliateRepo.getAffiliateStatus(token: token);
    final influencerFuture = influencerRepo.getAffiliateStatus(token: token);
    final affiliateResult = await affiliateFuture;
    final influencerResult = await influencerFuture;
    if (!context.mounted) return;

    bool affiliateRegistered = false;
    bool influencerRegistered = false;
    bool affiliateConflictWithInfluencer = false;
    bool influencerConflictWithAffiliate = false;
    bool affiliateUnknownError = false;
    bool influencerUnknownError = false;

    affiliateResult.fold(
      (error) {
        if (_isRegisteredAsOtherRoleMessage(error.message) &&
            error.message.toLowerCase().contains('influencer')) {
          influencerRegistered = true;
          affiliateConflictWithInfluencer = true;
        }
        affiliateUnknownError =
            !_isNotRegisteredMessage(error.message) &&
            !_isRegisteredAsOtherRoleMessage(error.message);
      },
      (status) {
        final normalizedStatus = status.status.trim().toLowerCase();
        final isAccepted =
            normalizedStatus == 'accepted' || normalizedStatus == 'approved';
        final isInfluencerType = _isInfluencerType(status.type);
        final isAffiliateType = _isAffiliateType(status.type);
        if (isAccepted && (isAffiliateType || !isInfluencerType)) {
          affiliateRegistered = true;
        }
      },
    );

    influencerResult.fold(
      (error) {
        if (_isRegisteredAsOtherRoleMessage(error.message) &&
            error.message.toLowerCase().contains('affiliate')) {
          affiliateRegistered = true;
          influencerConflictWithAffiliate = true;
        }
        influencerUnknownError =
            !_isNotRegisteredMessage(error.message) &&
            !_isRegisteredAsOtherRoleMessage(error.message);
      },
      (status) {
        final normalizedStatus = status.status.trim().toLowerCase();
        final isAccepted =
            normalizedStatus == 'accepted' || normalizedStatus == 'approved';
        final isInfluencerType = _isInfluencerType(status.type);
        final isAffiliateType = _isAffiliateType(status.type);
        if (isAccepted && (isInfluencerType || !isAffiliateType)) {
          influencerRegistered = true;
        }
      },
    );

    if (influencerRegistered &&
        !affiliateRegistered &&
        !influencerUnknownError) {
      context.push(_withFromProfile(AppRouter.myinfluencerCodings));
      return;
    }
    if (affiliateRegistered &&
        !influencerRegistered &&
        !affiliateUnknownError) {
      context.push(_withFromProfile(AppRouter.myCodings));
      return;
    }

    if (affiliateConflictWithInfluencer && !influencerUnknownError) {
      context.push(_withFromProfile(AppRouter.myinfluencerCodings));
      return;
    }
    if (influencerConflictWithAffiliate && !affiliateUnknownError) {
      context.push(_withFromProfile(AppRouter.myCodings));
      return;
    }

    if (influencerRegistered && affiliateRegistered) {
      if (role.contains('affiliate')) {
        context.push(_withFromProfile(AppRouter.myCodings));
      } else {
        context.push(_withFromProfile(AppRouter.myinfluencerCodings));
      }
      return;
    }

    if (influencerRegistered) {
      context.push(_withFromProfile(AppRouter.myinfluencerCodings));
      return;
    }
    if (affiliateRegistered) {
      context.push(_withFromProfile(AppRouter.myCodings));
      return;
    }

    await _showCouponRegistrationChoice(context);
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final localized = S.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AccountActionDialog(
          title: localized.logout,
          description: localized.logout_description,
          buttonLabel: localized.logout,
          icon: SvgPicture.asset(
            Assets.imagesLogout,
            width: 35.w,
            height: 35.h,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onClose: () => Navigator.of(dialogContext).pop(),
          onConfirm: () async {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            final success = await context.read<LogOutCubit>().logOut();
            if (!context.mounted || !success) return;
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    GetUserModel user,
  ) async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final deletionPending = _isDeletionPending(user);
    final title = deletionPending
        ? (isArabic ? 'الحساب قيد الحذف' : 'Account Deletion Marked')
        : (isArabic ? 'طلب حذف الحساب' : 'Request Account Deletion');
    final buttonLabel = deletionPending
        ? (isArabic ? 'إلغاء الحذف' : 'Cancel Deletion')
        : (isArabic ? 'طلب الحذف' : 'Request Deletion');
    final note = deletionPending
        ? (isArabic
              ? 'تم وضع حسابك قيد الحذف. يمكنك استعادة الحساب خلال 14 يوماً من طلب الحذف عبر تسجيل الدخول والضغط على "إلغاء الحذف".'
              : 'Your account is currently marked for deletion. You can recover your account within 14 days of the deletion request by logging in and selecting "Cancel Deletion".')
        : (isArabic
              ? 'لن يتم حذف الحساب فوراً. عند طلب الحذف سيتم وضع الحساب قيد الحذف لمدة 14 يوماً. بعد إرسال الطلب سيتم تسجيل خروجك، وعند تسجيل الدخول مرة أخرى يمكنك إلغاء طلب الحذف.'
              : 'Your account will not be deleted immediately. Once you request deletion, it will be marked for deletion for 14 days. After requesting deletion, you will be logged out, and logging in again lets you cancel the deletion request.');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AccountActionDialog(
          title: title,
          description: note,
          buttonLabel: buttonLabel,
          icon: Image.asset(
            Assets.imagesAccountDelete,
            width: 35.w,
            height: 35.h,
          ),
          onClose: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            if (deletionPending) {
              context.read<DeleteAccountCubit>().cancelDeletion();
            } else {
              context.read<DeleteAccountCubit>().deleteAccount();
            }
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _showDeletionMarkedDialog(BuildContext context) async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AccountActionDialog(
          title: isArabic
              ? 'تم وضع الحساب قيد الحذف'
              : 'Account Marked for Deletion',
          description: isArabic
              ? 'تم وضع حسابك قيد الحذف. عند تسجيل الدخول مرة أخرى يمكنك إلغاء طلب الحذف خلال 14 يوماً.'
              : 'Your account is marked for deletion. If you log in again, you can cancel the deletion request within 14 days.',
          buttonLabel: isArabic ? 'حسناً' : 'OK',
          icon: Image.asset(
            Assets.imagesAccountDelete,
            width: 35.w,
            height: 35.h,
          ),
          onClose: () => Navigator.of(dialogContext).pop(),
          onConfirm: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }
}

class _CachedProfileContact {
  const _CachedProfileContact({
    required this.email,
    required this.phone,
    required this.authLoginMethod,
  });

  final String email;
  final String phone;
  final String? authLoginMethod;
}

class _AccountActionDialog extends StatelessWidget {
  const _AccountActionDialog({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onClose,
    required this.onConfirm,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final Widget icon;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: 343.w,
        padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0x26000000), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.r,
                    color: AppColors.mediumGray,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              width: 65.w,
              height: 65.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: Center(child: icon),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
                height: 24 / 16,
                color: AppColors.deepDark,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
                fontSize: 12.sp,
                height: 18 / 12,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      child: Text(
                        buttonLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onSettingsTap,
    required this.onNotificationsTap,
    this.useSettingsAsFirstIcon = false,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onNotificationsTap;
  final bool useSettingsAsFirstIcon;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return SectionTopHeader(
      title: isArabic ? 'الملف الشخصي' : 'Profile',
      titleTextAlign: isArabic ? TextAlign.right : TextAlign.left,
      onSearchTap: useSettingsAsFirstIcon
          ? onSettingsTap
          : () => openRecentSearchSheet(context),
      onNotificationTap: onNotificationsTap,
      searchActionIcon: useSettingsAsFirstIcon
          ? SvgPicture.asset(Assets.imagesSettings, width: 40.w, height: 40.h)
          : null,
    );
  }
}

class _EmailCard extends StatelessWidget {
  const _EmailCard({
    required this.email,
    required this.phone,
    required this.authLoginMethod,
  });

  final String email;
  final String phone;
  final String? authLoginMethod;

  @override
  Widget build(BuildContext context) {
    final isPhoneVerified = authLoginMethod == 'phone';
    final isEmailVerified = authLoginMethod == 'email';
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    final contactText = isPhoneVerified ? phone : email;
    final verifiedText = (isPhoneVerified || isEmailVerified)
        ? (isArabic ? 'موثّق' : 'verified')
        : '';

    return ProfileCardFrame(
      child: Row(
        children: [
          Expanded(
            child: Text(
              contactText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ProfileDesignSystem.cardText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montes',
                height: 24 / 14,
              ),
            ),
          ),
          if (verifiedText.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 17.sp,
                  color: const Color(0xFF1E9E53),
                ),
                SizedBox(width: 6.w),
                Text(
                  verifiedText,
                  style: TextStyle(
                    color: const Color(0xFF1E9E53),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montes',
                    height: 24 / 13,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.label,
    required this.onTap,
    this.textColor = Colors.black,
  });

  final String label;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return GestureDetector(
      onTap: onTap,
      child: ProfileCardFrame(
        child: Align(
          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            label,
            style: AppStyle.styleProfileCardLabel14Medium(
              context,
            ).copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
