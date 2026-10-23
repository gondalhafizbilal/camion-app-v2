import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/auth/presentation/logic/guest_auth_cubit/guest_auth_cubit.dart';
import 'package:camion/features/auth/presentation/widgets/auth_background_scaffold.dart';
import 'package:camion/features/auth/presentation/widgets/camion_logo.dart';
import 'package:camion/features/auth/presentation/widgets/auth_social_buttons.dart';
import 'package:camion/features/auth/presentation/widgets/login_form.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    this.nextPath,
    this.requiresGuestBootstrapOnLogin = false,
    this.exitAppOnBack = false,
  });
  final String? nextPath;
  final bool requiresGuestBootstrapOnLogin;
  final bool exitAppOnBack;
  static const String _continueAsGuestEverKey = 'continueAsGuestEver';

  Future<List<String>> _loadLanguageCodes(BuildContext context) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final result = await sl<HomeRepository>().getLanguagesGraphql(token: token);
    final supported = S.delegate.supportedLocales
        .map((locale) => locale.languageCode.toLowerCase())
        .toSet();
    final codes = result.fold(
      (_) => <String>[],
      (items) => items
          .map((item) => item.shortCode.toLowerCase())
          .where((code) => code.isNotEmpty && supported.contains(code))
          .toSet()
          .toList(),
    );
    if (codes.isEmpty) {
      return const <String>['en', 'ar'];
    }
    final normalized = codes.toSet();
    normalized.add('en');
    normalized.add('ar');
    return normalized.toList();
  }

  String _localizedLanguageName(BuildContext context, String code) {
    switch (code) {
      case 'ar':
        return S.of(context).arabic;
      case 'en':
        return S.of(context).english;
      case 'de':
        return S.of(context).german;
      case 'fr':
        return S.of(context).french;
      case 'es':
        return S.of(context).spanish;
      case 'it':
        return S.of(context).italian;
      case 'bn':
        return S.of(context).bengali;
      case 'nl':
        return S.of(context).dutch;
      case 'hi':
        return S.of(context).hindi;
      case 'id':
        return S.of(context).indonesian;
      case 'ja':
        return S.of(context).japanese;
      case 'jv':
        return S.of(context).javanese;
      case 'ko':
        return S.of(context).korean;
      case 'ms':
        return S.of(context).malay;
      case 'zh':
        return S.of(context).mandarin_chinese;
      case 'mr':
        return S.of(context).marathi;
      case 'fa':
        return S.of(context).persian;
      case 'pl':
        return S.of(context).polish;
      case 'pt':
        return S.of(context).portuguese;
      case 'pa':
        return S.of(context).punjabi;
      case 'ro':
        return S.of(context).romanian;
      case 'ru':
        return S.of(context).russian;
      case 'sw':
        return S.of(context).swahili;
      case 'ta':
        return S.of(context).tamil;
      case 'te':
        return S.of(context).telugu;
      case 'th':
        return S.of(context).thai;
      case 'tr':
        return S.of(context).turkish;
      case 'uk':
        return S.of(context).ukrainian;
      case 'ur':
        return S.of(context).urdu;
      case 'vi':
        return S.of(context).vietnamese;
      default:
        return code.toUpperCase();
    }
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final selectedCode = context.read<LocalizationsCubit>().state.languageCode;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
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
              Text(
                S.of(context).change_language,
                style: AppStyle.styleSectionTitle16Medium(
                  context,
                ).copyWith(color: Colors.black),
              ),
              SizedBox(height: 10.h),
              Flexible(
                child: FutureBuilder<List<String>>(
                  future: _loadLanguageCodes(context),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFCB262E),
                        ),
                      );
                    }
                    final codes = snapshot.data ?? const <String>['en', 'ar'];
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: codes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final code = codes[index];
                        final selected = code == selectedCode;
                        return ListTile(
                          onTap: () async {
                            await context
                                .read<LocalizationsCubit>()
                                .changeLocale(locale: Locale(code));
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          title: Text(
                            _localizedLanguageName(context, code),
                            style: AppStyle.styleInputField14Regular(context)
                                .copyWith(
                                  color: selected
                                      ? const Color(0xFFCB262E)
                                      : Colors.black,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFCB262E),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !exitAppOnBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !exitAppOnBack) return;
        SystemNavigator.pop();
      },
      child: BlocListener<GuestAuthCubit, GuestAuthState>(
        listener: (context, state) async {
          if (state is GuestAuthError && state.isSilent) {
            return;
          }
          if (state is GuestAuthError) {
            AppToast.show(
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.red,
              msg: state.error.message,
            );
          }

          if (state is GuestAuthLoaded && state.isSilent) {
            return;
          }
          if (state is GuestAuthLoaded) {
            final resolvedToken = state.token.trim();
            if (resolvedToken.isEmpty) {
              AppToast.show(
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.red,
                msg: 'Guest login failed: access token is missing.',
              );
              return;
            }

            final cachedToken =
                (await sl<SecureCacheHelper>().getData(key: 'token'))?.trim() ??
                '';
            if (cachedToken.isEmpty) {
              AppToast.show(
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.red,
                msg: 'Guest login failed: session was not saved.',
              );
              return;
            }

            await sl<SecureCacheHelper>().saveData(
              key: _continueAsGuestEverKey,
              value: 'true',
            );

            AppToast.show(
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.green,
              msg: 'Guest session started successfully.',
            );
            final nextDecoded = nextPath != null
                ? Uri.decodeComponent(nextPath!)
                : null;
            if (!context.mounted) return;
            if (nextDecoded != null && nextDecoded.isNotEmpty) {
              final router = RouterGenerator.mainRouting;
              if (router.canPop()) {
                router.pop();
              }
              final currentPath = router.routeInformationProvider.value.uri
                  .toString();
              if (currentPath != nextDecoded) {
                router.go(nextDecoded);
              }
              return;
            }
            context.go(AppRouter.selectingFromBottomNavBar);
          }
        },
        child: AuthBackgroundScaffold(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (36.h),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: GestureDetector(
                                onTap: () => _showLanguageSheet(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24.r),
                                    border: Border.all(
                                      color: const Color(0xFFCB262E),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.language_rounded,
                                        size: 16,
                                        color: Color(0xFFCB262E),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        _localizedLanguageName(
                                          context,
                                          context
                                              .watch<LocalizationsCubit>()
                                              .state
                                              .languageCode,
                                        ),
                                        style:
                                            AppStyle.styleFilterChip12Medium(
                                              context,
                                            ).copyWith(
                                              color: const Color(0xFFCB262E),
                                            ),
                                      ),
                                      SizedBox(width: 4.w),
                                      const Icon(
                                        Icons.expand_more_rounded,
                                        size: 16,
                                        color: Color(0xFFCB262E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          const Center(
                            child: CamionLogo(width: 120, height: 90),
                          ),
                          // SizedBox(height: 16.h),
                          // Text(
                          //   S.of(context).login,
                          //   style: AppStyle.styleVerificationTitle24Medium(
                          //     context,
                          //   ).copyWith(color: Colors.black, fontSize: 30.sp),
                          // ),
                          // SizedBox(height: 8.h),
                          // Text(
                          //   _pageSubtitle(context),
                          //   style:
                          //       AppStyle.styleVerificationBody12Regular(
                          //         context,
                          //       ).copyWith(
                          //         color: const Color(0xFF4A4A4A),
                          //         fontSize: 14.sp,
                          //       ),
                          // ),
                          SizedBox(height: 28.h),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'البريد الإلكتروني/رقم الهاتف'
                                : 'Email/Phone Number',
                            style: AppStyle.styleRegular16(context).copyWith(
                              color: Colors.black,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          LoginForm(
                            nextPath: nextPath,
                            requiresGuestBootstrapOnLogin:
                                requiresGuestBootstrapOnLogin,
                          ),
                          SizedBox(height: 18.h),
                          AuthSocialButtons(
                            contextLabel: 'Login',
                            nextPath: nextPath,
                          ),
                          SizedBox(height: 24.h),
                          BlocBuilder<GuestAuthCubit, GuestAuthState>(
                            builder: (context, guestState) {
                              final isLoading = guestState is GuestAuthLoading;
                              return CustomElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context
                                          .read<GuestAuthCubit>()
                                          .registerGuest(),
                                backgroundColor: Colors.white,
                                borderColor: const Color(0xFF1A1A1A),
                                elevation: 0,
                                verticalPadding: 4.h,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Color(0xFFCC2830),
                                        ),
                                      )
                                    : Text(
                                        Localizations.localeOf(
                                                  context,
                                                ).languageCode ==
                                                'ar'
                                            ? 'المتابعة كزائر'
                                            : 'Continue As Guest',
                                        style: AppStyle.styleMedium16(context)
                                            .copyWith(
                                              color: const Color(0xFFCC2830),
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w500,
                                              height: 18 / 16,
                                            ),
                                      ),
                              );
                            },
                          ),
                          const Spacer(),
                          SizedBox(height: 16.h),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        "${S.of(context).dont_have_an_account} ",
                                    style: AppStyle.styleRegular16(context)
                                        .copyWith(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          height: 18 / 12,
                                        ),
                                  ),
                                  TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        final currentNext = nextPath;
                                        if (currentNext != null &&
                                            currentNext.isNotEmpty) {
                                          final encoded = Uri.encodeComponent(
                                            currentNext,
                                          );
                                          GoRouter.of(context).push(
                                            '${AppRouter.register}?next=$encoded',
                                          );
                                          return;
                                        }
                                        GoRouter.of(
                                          context,
                                        ).pushNamed(AppRouter.register);
                                      },
                                    text: S.of(context).register,
                                    style: AppStyle.styleRegular16(context)
                                        .copyWith(
                                          color: const Color(0xFFCC2830),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          height: 18 / 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
