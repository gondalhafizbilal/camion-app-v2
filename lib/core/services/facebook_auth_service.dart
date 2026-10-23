import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

class FacebookAuthService {
  /// Returns Facebook access token to be sent to backend.
  Future<String?> signInAndGetAccessToken() async {
    if (kDebugMode) {
      debugPrint('[AUTH][FACEBOOK][NATIVE] login() started');
    }
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
      // iOS defaults to limited tracking in the plugin, which can yield a
      // limited token not accepted by backends expecting classic FB access tokens.
      loginTracking: LoginTracking.enabled,
    );
    if (kDebugMode) {
      debugPrint(
        '[AUTH][FACEBOOK][NATIVE] login() status=${result.status.name} hasToken=${result.accessToken != null}',
      );
    }

    switch (result.status) {
      case LoginStatus.success:
        if (kDebugMode) {
          final len = result.accessToken?.tokenString.trim().length ?? 0;
          debugPrint(
            '[AUTH][FACEBOOK][NATIVE] accessToken received length=$len',
          );
        }
        return result.accessToken?.tokenString;
      case LoginStatus.cancelled:
        if (kDebugMode) {
          debugPrint('[AUTH][FACEBOOK][NATIVE] login cancelled by user');
        }
        return null;
      case LoginStatus.failed:
        if (kDebugMode) {
          debugPrint(
            '[AUTH][FACEBOOK][NATIVE] login failed message=${result.message}',
          );
        }
        return null;
      case LoginStatus.operationInProgress:
        if (kDebugMode) {
          debugPrint(
            '[AUTH][FACEBOOK][NATIVE] login ignored: operation already in progress',
          );
        }
        return null;
    }
  }

  Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('[AUTH][FACEBOOK][NATIVE] logOut() started');
    }
    await FacebookAuth.instance.logOut();
    if (kDebugMode) {
      debugPrint('[AUTH][FACEBOOK][NATIVE] logOut() completed');
    }
  }
}
