import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'log_out_state.dart';

class LogOutCubit extends Cubit<LogOutState> {
  LogOutCubit() : super(LogOutInitial());

  static const List<String> _authPreferenceKeys = <String>[
    'token',
    'authSessionToken',
    'authLoginMethod',
    'email',
    'id',
    'guestId',
    'userRole',
    'phoneNumber',
    'userName',
    'loginMethod',
  ];

  Future<bool> logOut() async {
    appLog('logout');
    emit(LogOutLoading());
    final secureCache = sl<SecureCacheHelper>();
    final cacheHelper = sl<CacheHelper>();
    String? logoutWarning;
    final location =
        '${AppRouter.login}?logout=1&ts=${DateTime.now().millisecondsSinceEpoch}';
    try {
      final accessToken =
          (await secureCache.getData(key: 'token'))?.trim() ?? '';
      if (accessToken.isNotEmpty) {
        final logoutResult = await sl<AuthRepository>().logout(
          accessToken: accessToken,
        );
        logoutResult.fold(
          (error) {
            logoutWarning = error.message.trim().isEmpty
                ? 'Signed out locally. Server logout could not be confirmed.'
                : error.message.trim();
          },
          (_) {
            logoutWarning = null;
          },
        );
      }
    } catch (_) {
      logoutWarning =
          'Signed out locally. Server logout could not be confirmed.';
    }

    // Move to login before the auth cache is torn down so session listeners
    // cannot briefly re-render the profile shell as the active screen.
    RouterGenerator.mainRouting.go(location);

    // Ensure local sign-out never blocks navigation even if a platform storage
    // operation fails on specific devices.
    try {
      await secureCache.clearData();
    } catch (_) {}
    try {
      await cacheHelper.clearData();
    } catch (_) {
      // Fallback: force-remove auth/session keys if full clear fails.
      for (final key in _authPreferenceKeys) {
        try {
          await cacheHelper.removeData(key: key);
        } catch (_) {}
      }
    }

    emit(LogOutSuccess(message: 'Logout successful'));
    AppToast.show(
      msg: 'Logout successful',
      gravity: ToastGravity.TOP,
      backgroundColor: AppColors.green,
    );
    if (logoutWarning != null && logoutWarning!.isNotEmpty) {
      AppToast.show(
        msg: logoutWarning!,
        gravity: ToastGravity.TOP,
        backgroundColor: AppColors.alertRed,
      );
    }
    return true;
  }
}
