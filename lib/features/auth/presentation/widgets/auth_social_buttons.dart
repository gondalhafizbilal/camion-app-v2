import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/notifications/push_notification.dart';
import 'package:camion/core/services/apple_auth_service.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/facebook_auth_service.dart';
import 'package:camion/core/services/google_auth_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AuthSocialButtons extends StatefulWidget {
  const AuthSocialButtons({
    super.key,
    required this.contextLabel,
    this.nextPath,
  });

  final String contextLabel;
  final String? nextPath;

  @override
  State<AuthSocialButtons> createState() => _AuthSocialButtonsState();
}

class _AuthSocialButtonsState extends State<AuthSocialButtons> {
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isAppleLoading = false;

  void _logGoogle(String message) {
    if (!kDebugMode) return;
    debugPrint('[AUTH][GOOGLE][UI] $message');
  }

  void _logFacebook(String message) {
    if (!kDebugMode) return;
    debugPrint('[AUTH][FACEBOOK][UI] $message');
  }

  void _logApple(String message) {
    if (!kDebugMode) return;
    debugPrint('[AUTH][APPLE][UI] $message');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthSocialButton(
          logo: Assets.imagesGoogleIcon,
          title: _continueWithGoogle(context),
          onTap: (_isGoogleLoading || _isFacebookLoading || _isAppleLoading)
              ? null
              : () => _signInWithGoogle(context),
          isLoading: _isGoogleLoading,
        ),
        SizedBox(height: 14.h),
        _AuthSocialButton(
          logo: Assets.imagesLogosFacebook,
          title: _continueWithFacebook(context),
          onTap: (_isGoogleLoading || _isFacebookLoading || _isAppleLoading)
              ? null
              : () => _signInWithFacebook(context),
          isLoading: _isFacebookLoading,
        ),
        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
          SizedBox(height: 14.h),
          _AuthSocialButton(
            logo: Assets.imagesAppleIcon,
            title: _continueWithAppleId(context),
            onTap: (_isGoogleLoading || _isFacebookLoading || _isAppleLoading)
                ? null
                : () => _signInWithApple(context),
            isLoading: _isAppleLoading,
          ),
        ],
      ],
    );
  }

  String _continueWithGoogle(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? 'الاستمرار عبر Google'
        : 'Continue with Google';
  }

  String _continueWithFacebook(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? 'الاستمرار عبر Facebook'
        : 'Continue with Facebook';
  }

  String _continueWithAppleId(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? 'الاستمرار عبر Apple ID'
        : 'Continue with Apple ID';
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _logGoogle('Google button tapped from ${widget.contextLabel}');
    setState(() => _isGoogleLoading = true);

    try {
      _logGoogle('Starting native Google authentication flow');
      final idToken = await sl<GoogleAuthService>().signInAndGetIdToken();
      if (idToken == null || idToken.trim().isEmpty) {
        throw Exception('Google sign-in did not return an ID token.');
      }
      _logGoogle(
        'Native Google returned idToken length=${idToken.trim().length}',
      );
      final firebaseDeviceToken =
          await PushNotificationsService.resolveAuthFlowToken();
      final cache = sl<SecureCacheHelper>();
      final guestUUID =
          (await cache.getData(key: 'guestUUID'))?.trim() ??
          ((await cache.getData(key: 'guestId'))?.trim() ?? '');
      _logGoogle(
        'Resolved firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
      );

      _logGoogle('Sending idToken to backend Google OAuth login endpoint');
      final result = await sl<AuthRepository>().loginWithGoogleIdToken(
        idToken: idToken,
        guestUUID: guestUUID,
        firebaseDeviceToken: firebaseDeviceToken,
      );

      await result.fold(
        (error) async {
          _logGoogle(
            'Backend login failed status=${error.statusCode} message=${error.message}',
          );
          throw Exception(error.message);
        },
        (auth) async {
          final accessToken = auth.token.trim();
          if (accessToken.isEmpty) {
            throw Exception(
              'Login failed: access token not returned by server.',
            );
          }
          _logGoogle(
            'Backend login success tokenLength=${accessToken.length} uuid=${auth.customer.uuid}',
          );

          await Future.wait([
            cache.saveData(key: 'token', value: accessToken),
            cache.saveData(key: 'id', value: auth.customer.uuid),
            cache.saveData(key: 'userRole', value: auth.customer.role),
            cache.saveData(key: 'authLoginMethod', value: 'google'),
            cache.removeData(key: 'authSessionToken'),
            if (auth.customer.emailAddress.trim().isNotEmpty)
              cache.saveData(key: 'email', value: auth.customer.emailAddress),
            if (auth.customer.fullName.trim().isNotEmpty)
              cache.saveData(key: 'userName', value: auth.customer.fullName),
            if (auth.customer.phoneNumber.trim().isNotEmpty)
              cache.saveData(
                key: 'phoneNumber',
                value: auth.customer.phoneNumber,
              ),
          ]);
          await sl<AppsFlyerService>().syncCustomerUserId(
            customerUserId: auth.customer.uuid,
          );
          _logGoogle(
            'Session cached (token/id/userRole/authLoginMethod/email/userName/phoneNumber)',
          );
        },
      );

      if (!context.mounted) return;
      _logGoogle('Navigating after Google login');
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        msg: 'Logged in with Google successfully.',
      );

      final nextDecoded = widget.nextPath != null
          ? Uri.decodeComponent(widget.nextPath!)
          : null;
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
    } catch (e) {
      _logGoogle('Google login exception: $e');
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Google sign-in failed. $message',
      );
    } finally {
      _logGoogle('Google login flow finished');
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _logFacebook('Facebook button tapped from ${widget.contextLabel}');
    setState(() => _isFacebookLoading = true);

    try {
      _logFacebook('Starting native Facebook authentication flow');
      final accessToken = await sl<FacebookAuthService>()
          .signInAndGetAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw Exception('Facebook sign-in did not return an access token.');
      }
      _logFacebook(
        'Native Facebook returned accessToken length=${accessToken.trim().length}',
      );
      final firebaseDeviceToken =
          await PushNotificationsService.resolveAuthFlowToken();
      final cache = sl<SecureCacheHelper>();
      final guestUUID =
          (await cache.getData(key: 'guestUUID'))?.trim() ??
          ((await cache.getData(key: 'guestId'))?.trim() ?? '');
      _logFacebook(
        'Resolved firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
      );

      _logFacebook(
        'Sending accessToken to backend Facebook OAuth login endpoint',
      );
      final result = await sl<AuthRepository>().loginWithFacebookAccessToken(
        accessToken: accessToken,
        guestUUID: guestUUID,
        firebaseDeviceToken: firebaseDeviceToken,
      );
      _logFacebook('Backend Facebook OAuth request finished');

      await result.fold(
        (error) async {
          _logFacebook(
            'Backend login failed status=${error.statusCode} message=${error.message}',
          );
          throw Exception(error.message);
        },
        (auth) async {
          final sessionToken = auth.token.trim();
          if (sessionToken.isEmpty) {
            throw Exception(
              'Login failed: access token not returned by server.',
            );
          }
          _logFacebook(
            'Backend login success tokenLength=${sessionToken.length} uuid=${auth.customer.uuid}',
          );

          await Future.wait([
            cache.saveData(key: 'token', value: sessionToken),
            cache.saveData(key: 'id', value: auth.customer.uuid),
            cache.saveData(key: 'userRole', value: auth.customer.role),
            cache.saveData(key: 'authLoginMethod', value: 'facebook'),
            cache.removeData(key: 'authSessionToken'),
            if (auth.customer.emailAddress.trim().isNotEmpty)
              cache.saveData(key: 'email', value: auth.customer.emailAddress),
            if (auth.customer.fullName.trim().isNotEmpty)
              cache.saveData(key: 'userName', value: auth.customer.fullName),
            if (auth.customer.phoneNumber.trim().isNotEmpty)
              cache.saveData(
                key: 'phoneNumber',
                value: auth.customer.phoneNumber,
              ),
          ]);
          await sl<AppsFlyerService>().syncCustomerUserId(
            customerUserId: auth.customer.uuid,
          );
          _logFacebook(
            'Session cached (token/id/userRole/authLoginMethod/email/userName/phoneNumber)',
          );
          _logFacebook(
            'Cached values summary tokenLength=${sessionToken.length} id=${auth.customer.uuid} role=${auth.customer.role}',
          );
        },
      );

      if (!context.mounted) return;
      _logFacebook('Navigating after Facebook login');
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        msg: 'Logged in with Facebook successfully.',
      );

      final nextDecoded = widget.nextPath != null
          ? Uri.decodeComponent(widget.nextPath!)
          : null;
      if (nextDecoded != null && nextDecoded.isNotEmpty) {
        _logFacebook('Resolved nextPath=$nextDecoded');
        final router = RouterGenerator.mainRouting;
        if (router.canPop()) {
          _logFacebook(
            'Router canPop=true, popping current route before redirect',
          );
          router.pop();
        }
        final currentPath = router.routeInformationProvider.value.uri
            .toString();
        _logFacebook('Current route before redirect=$currentPath');
        if (currentPath != nextDecoded) {
          _logFacebook('Redirecting to nextPath');
          router.go(nextDecoded);
        }
        return;
      }
      _logFacebook('Navigating to default bottom nav route');
      context.go(AppRouter.selectingFromBottomNavBar);
    } catch (e) {
      _logFacebook('Facebook login exception: $e');
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Facebook sign-in failed. $message',
      );
    } finally {
      _logFacebook('Facebook login flow finished');
      if (mounted) {
        setState(() => _isFacebookLoading = false);
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _logApple('Apple button tapped from ${widget.contextLabel}');
    setState(() => _isAppleLoading = true);

    try {
      _logApple('Starting native Apple authentication flow');
      final authPayload = await sl<AppleAuthService>()
          .signInAndGetAuthPayload();
      if (authPayload == null || authPayload.identityToken.trim().isEmpty) {
        throw Exception('Apple sign-in did not return an identity token.');
      }
      _logApple(
        'Native Apple returned identityToken length=${authPayload.identityToken.trim().length} codePresent=${(authPayload.authorizationCode ?? '').isNotEmpty} namePresent=${(authPayload.fullName ?? '').isNotEmpty}',
      );
      final firebaseDeviceToken =
          await PushNotificationsService.resolveAuthFlowToken();
      final cache = sl<SecureCacheHelper>();
      final guestUUID =
          (await cache.getData(key: 'guestUUID'))?.trim() ??
          ((await cache.getData(key: 'guestId'))?.trim() ?? '');
      _logApple(
        'Resolved firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
      );

      _logApple(
        'Sending Apple auth payload to backend Apple OAuth login endpoint',
      );
      final result = await sl<AuthRepository>().loginWithAppleIdToken(
        identityToken: authPayload.identityToken,
        guestUUID: guestUUID,
        authorizationCode: authPayload.authorizationCode,
        fullName: authPayload.fullName,
        firebaseDeviceToken: firebaseDeviceToken,
      );

      await result.fold(
        (error) async {
          _logApple(
            'Backend login failed status=${error.statusCode} message=${error.message}',
          );
          throw Exception(error.message);
        },
        (auth) async {
          final accessToken = auth.token.trim();
          if (accessToken.isEmpty) {
            throw Exception(
              'Login failed: access token not returned by server.',
            );
          }
          _logApple(
            'Backend login success tokenLength=${accessToken.length} uuid=${auth.customer.uuid}',
          );

          await Future.wait([
            cache.saveData(key: 'token', value: accessToken),
            cache.saveData(key: 'id', value: auth.customer.uuid),
            cache.saveData(key: 'userRole', value: auth.customer.role),
            cache.saveData(key: 'authLoginMethod', value: 'apple'),
            cache.removeData(key: 'authSessionToken'),
            if (auth.customer.emailAddress.trim().isNotEmpty)
              cache.saveData(key: 'email', value: auth.customer.emailAddress),
            if (auth.customer.fullName.trim().isNotEmpty)
              cache.saveData(key: 'userName', value: auth.customer.fullName),
            if (auth.customer.phoneNumber.trim().isNotEmpty)
              cache.saveData(
                key: 'phoneNumber',
                value: auth.customer.phoneNumber,
              ),
          ]);
          await sl<AppsFlyerService>().syncCustomerUserId(
            customerUserId: auth.customer.uuid,
          );
        },
      );

      if (!context.mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        msg: 'Logged in with Apple successfully.',
      );

      final nextDecoded = widget.nextPath != null
          ? Uri.decodeComponent(widget.nextPath!)
          : null;
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
    } catch (e) {
      _logApple('Apple login exception: $e');
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Apple sign-in failed. $message',
      );
    } finally {
      _logApple('Apple login flow finished');
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }
}

class _AuthSocialButton extends StatelessWidget {
  const _AuthSocialButton({
    required this.logo,
    required this.title,
    required this.onTap,
    this.isLoading = false,
  });

  final String logo;
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CustomElevatedButton(
      onPressed: onTap,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFF1A1A1A),
      elevation: 0,
      verticalPadding: 4.h,
      widget: isLoading
          ? SizedBox(
              width: 22.w,
              height: 22.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFFCC2830),
              ),
            )
          : SvgPicture.asset(logo, width: 24.w, height: 24.w),
      child: Text(
        isLoading ? 'Please wait...' : title,
        style: AppStyle.styleRegular16(context).copyWith(
          fontSize: 16.sp,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
