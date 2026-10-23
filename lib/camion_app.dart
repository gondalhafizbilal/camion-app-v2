import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/app_page_transitions.dart';
import 'package:camion/config/widgets/app_update_gate.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/global_connectivity_guard.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CamionApp extends StatelessWidget {
  const CamionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      child: AppUpdateGate(
        child: BlocBuilder<LocalizationsCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              routerConfig: RouterGenerator.mainRouting,
              scaffoldMessengerKey: AppToast.messengerKey,
              debugShowCheckedModeBanner: false,
              title: AppConfig.instance.flavor == AppFlavor.development
                  ? 'CAMION DEVELOPMENT'
                  : 'CAMION',
              builder: (context, child) {
                if (child == null) return const SizedBox.shrink();
                return SafeArea(
                  top: false,
                  bottom: true,
                  maintainBottomViewPadding: true,
                  child: GlobalConnectivityGuard(child: child),
                );
              },
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              locale: locale,
              theme: ThemeData(
                fontFamily: 'Montes',
                scaffoldBackgroundColor: Colors.white,
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android:
                        AppFadeSlidePageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.macOS: AppFadeSlidePageTransitionsBuilder(),
                    TargetPlatform.windows:
                        AppFadeSlidePageTransitionsBuilder(),
                    TargetPlatform.linux: AppFadeSlidePageTransitionsBuilder(),
                  },
                ),
                splashFactory: InkSparkle.splashFactory,
                splashColor: AppColors.primaryColor.withAlpha(26),
                highlightColor: AppColors.primaryColor.withAlpha(12),
                hoverColor: AppColors.primaryColor.withAlpha(10),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primaryColor,
                  primary: AppColors.primaryColor,
                ),
                primaryColor: AppColors.primaryColor,
                textTheme: ThemeData.light().textTheme.apply(
                  fontFamily: 'Montes',
                ),
                primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
                  fontFamily: 'Montes',
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  hintStyle: TextStyle(fontFamily: 'Montes'),
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    borderSide: BorderSide(width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    borderSide: BorderSide(width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    borderSide: BorderSide(width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    borderSide: BorderSide(width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    borderSide: BorderSide(width: 1),
                  ),
                ),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppColors.primaryColor,
                  selectionColor: AppColors.primaryColor.withAlpha(70),
                  selectionHandleColor: AppColors.primaryColor,
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    splashFactory: InkSparkle.splashFactory,
                    foregroundColor: AppColors.primaryColor,
                    overlayColor: AppColors.primaryColor.withAlpha(22),
                    highlightColor: AppColors.primaryColor.withAlpha(12),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    disabledForegroundColor: Colors.white70,
                    splashFactory: InkSparkle.splashFactory,
                    overlayColor: AppColors.primaryColor.withAlpha(22),
                    animationDuration: const Duration(milliseconds: 170),
                    textStyle: const TextStyle(
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 24 / 14,
                    ),
                    minimumSize: Size(0, AppButtonTokens.height),
                    padding: EdgeInsets.symmetric(
                      vertical: AppButtonTokens.verticalPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppButtonTokens.radius,
                      ),
                    ),
                    side: const BorderSide(
                      color: Colors.transparent,
                      width: AppButtonTokens.borderWidth,
                    ),
                    elevation: AppButtonTokens.elevation,
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    splashFactory: InkSparkle.splashFactory,
                    overlayColor: AppColors.primaryColor.withAlpha(16),
                    animationDuration: const Duration(milliseconds: 170),
                    textStyle: const TextStyle(
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 24 / 14,
                    ),
                    minimumSize: Size(0, AppButtonTokens.height),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: AppButtonTokens.verticalPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppButtonTokens.radius,
                      ),
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    splashFactory: InkSparkle.splashFactory,
                    overlayColor: AppColors.primaryColor.withAlpha(16),
                    animationDuration: const Duration(milliseconds: 170),
                    textStyle: const TextStyle(
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 24 / 14,
                    ),
                    minimumSize: Size(0, AppButtonTokens.height),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: AppButtonTokens.verticalPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppButtonTokens.radius,
                      ),
                    ),
                    side: const BorderSide(
                      color: Colors.transparent,
                      width: AppButtonTokens.borderWidth,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
