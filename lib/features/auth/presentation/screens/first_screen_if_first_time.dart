import 'dart:async';

import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/startup_gate_service.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:camion/features/auth/presentation/logic/guest_auth_cubit/guest_auth_cubit.dart';
import 'package:camion/features/home/data/graphql/home_graphql_queries.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FirstScreenIfFirstTime extends StatefulWidget {
  const FirstScreenIfFirstTime({super.key});

  @override
  State<FirstScreenIfFirstTime> createState() => _FirstScreenIfFirstTimeState();
}

class _FirstScreenIfFirstTimeState extends State<FirstScreenIfFirstTime> {
  static const String _continueAsGuestEverKey = 'continueAsGuestEver';
  static const String _splashImagePath =
      'assets/images/splash_screen_latest.png';
  static const Duration _splashDelay = Duration(seconds: 3);
  static const Duration _cachedTokenValidationTimeout = Duration(seconds: 10);
  static const Duration _guestRegistrationTimeout = Duration(seconds: 20);
  final StartupGateService _startupGate = sl<StartupGateService>();
  late Future<String?> _nextRouteFuture;
  bool _isStartupBlocked = false;
  bool _isRetryingStartup = false;

  @override
  void initState() {
    super.initState();
    _nextRouteFuture = _resolveNextRoute();
    _runSplashFlow();
  }

  Future<void> _runSplashFlow({bool includeDelay = true}) async {
    if (includeDelay) {
      await Future.delayed(_splashDelay);
    }
    if (!mounted) return;

    final nextRoute = await _nextRouteFuture;
    if (!mounted) return;
    await _startupGate.waitForRelease();
    if (!mounted) return;
    if (nextRoute == null) {
      setState(() {
        _isStartupBlocked = true;
        _isRetryingStartup = false;
      });
      return;
    }
    context.go(nextRoute);
  }

  Future<String?> _resolveNextRoute() async {
    // Double safety: allow static screens mode only outside production.
    if (!AppConfig.instance.flavor.isProduction &&
        AppConfig.instance.staticScreensMode) {
      return AppRouter.login;
    }

    final secureCache = sl<SecureCacheHelper>();
    final cachedToken = (await secureCache.getData(key: 'token'))?.trim() ?? '';
    final loginMethod =
        ((await secureCache.getData(key: 'authLoginMethod')) ?? '')
            .trim()
            .toLowerCase();
    final isCustomerSession = _isCustomerLoginMethod(loginMethod);

    if (cachedToken.isNotEmpty) {
      final tokenIsUsable = await _validateCachedToken(cachedToken)
          .timeout(_cachedTokenValidationTimeout, onTimeout: () => false);
      if (tokenIsUsable) {
        final deepLinkRoute = sl<AppsFlyerService>().consumePendingRoute();
        if (deepLinkRoute != null) {
          return deepLinkRoute;
        }
        await secureCache.saveData(key: _continueAsGuestEverKey, value: 'true');
        return AppRouter.selectingFromBottomNavBar;
      }

      if (isCustomerSession) {
        await _clearInvalidCustomerSession();
        return AppRouter.login;
      }

      await _clearInvalidGuestSession();
      final recoveredGuest = await _createGuestTokenIfMissing(
        forceRefresh: true,
      );
      if (recoveredGuest) {
        final deepLinkRoute = sl<AppsFlyerService>().consumePendingRoute();
        if (deepLinkRoute != null) {
          return deepLinkRoute;
        }
        await secureCache.saveData(key: _continueAsGuestEverKey, value: 'true');
        return AppRouter.selectingFromBottomNavBar;
      }
      return null;
    }

    if (isCustomerSession) {
      await _clearInvalidCustomerSession();
      return AppRouter.login;
    }

    final created = await _createGuestTokenIfMissing();
    if (created) {
      final deepLinkRoute = sl<AppsFlyerService>().consumePendingRoute();
      if (deepLinkRoute != null) {
        return deepLinkRoute;
      }
      await secureCache.saveData(key: _continueAsGuestEverKey, value: 'true');
      return AppRouter.selectingFromBottomNavBar;
    }

    final deepLinkRoute = sl<AppsFlyerService>().consumePendingRoute();
    if (deepLinkRoute != null) {
      return deepLinkRoute;
    }
    return null;
  }

  bool _isCustomerLoginMethod(String loginMethod) {
    return const <String>{
      'email',
      'phone',
      'google',
      'facebook',
      'apple',
    }.contains(loginMethod);
  }

  Future<bool> _validateCachedToken(String token) async {
    try {
      final response = await sl<Dio>().post<dynamic>(
        EndPoints.graphql,
        data: const <String, dynamic>{
          'query': HomeGraphqlQueries.customerDashboardCounts,
          'variables': <String, dynamic>{},
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'x-suppress-error-toast': 'true',
            'x-suppress-backend-unavailable': 'true',
          },
          extra: const <String, dynamic>{'skipUnauthorizedRecovery': true},
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) return false;

      final body = response.data;
      if (body is! Map) return false;
      final map = body.map((key, value) => MapEntry(key.toString(), value));
      if (_hasGraphqlError(map['errors'])) return false;

      final data = map['data'];
      if (data is! Map) return false;
      final dataMap = data.map((key, value) => MapEntry(key.toString(), value));
      return dataMap.containsKey('getCustomerCartCount') &&
          dataMap.containsKey('getCustomerWishlistCount') &&
          _isCountValue(dataMap['getCustomerCartCount']) &&
          _isCountValue(dataMap['getCustomerWishlistCount']);
    } catch (_) {
      return false;
    }
  }

  bool _hasGraphqlError(dynamic errors) {
    if (errors is! List) return false;
    if (errors.isEmpty) return false;
    for (final error in errors) {
      if (error is! Map) continue;
      final map = error.map((key, value) => MapEntry(key.toString(), value));
      final message = (map['message'] ?? '').toString().toLowerCase();
      final extensions = map['extensions'];
      final code = extensions is Map
          ? (extensions['code'] ?? '').toString().toUpperCase()
          : '';
      final originalError = extensions is Map
          ? extensions['originalError']
          : null;
      final statusCode = originalError is Map
          ? int.tryParse((originalError['statusCode'] ?? '').toString())
          : null;

      if (code == 'UNAUTHENTICATED' ||
          code == 'FORBIDDEN' ||
          statusCode == 401 ||
          statusCode == 403 ||
          message.contains('unauthorized') ||
          message.contains('unauthenticated') ||
          message.contains('forbidden') ||
          message.contains('invalid token') ||
          message.contains('token expired')) {
        return true;
      }
    }
    return true;
  }

  bool _isCountValue(dynamic value) {
    if (value is num) return true;
    if (value is String) return int.tryParse(value.trim()) != null;
    return false;
  }

  Future<void> _clearInvalidGuestSession() async {
    final secureCache = sl<SecureCacheHelper>();
    final keys = <String>[
      'token',
      'authSessionToken',
      'authLoginMethod',
      'guestUUID',
    ];
    for (final key in keys) {
      await secureCache.removeData(key: key);
    }
  }

  Future<void> _clearInvalidCustomerSession() async {
    final secureCache = sl<SecureCacheHelper>();
    final keys = <String>[
      'token',
      'authSessionToken',
      'authLoginMethod',
      'id',
      'userRole',
      'email',
      'userName',
      'phoneNumber',
      'countryCode',
      'guestUUID',
      'authRuntimeEnvironmentMarkerV1',
    ];
    for (final key in keys) {
      await secureCache.removeData(key: key);
    }
  }

  Future<bool> _createGuestTokenIfMissing({bool forceRefresh = false}) async {
    final guestCubit = GuestAuthCubit(sl<AuthRepository>());
    try {
      await guestCubit
          .registerGuest(forceRefresh: forceRefresh)
          .timeout(_guestRegistrationTimeout);
      final state = guestCubit.state;
      if (state is GuestAuthLoaded && state.token.trim().isNotEmpty) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      await guestCubit.close();
    }
  }

  void _retryStartup() {
    if (_isRetryingStartup) return;
    setState(() {
      _isStartupBlocked = false;
      _isRetryingStartup = true;
      _nextRouteFuture = _resolveNextRoute();
    });
    _runSplashFlow(includeDelay: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.primaryColor),
          Image.asset(_splashImagePath, fit: BoxFit.cover),
          if (_isStartupBlocked || _isRetryingStartup)
            _StartupRetryOverlay(
              isRetrying: _isRetryingStartup,
              onRetry: _retryStartup,
            ),
        ],
      ),
    );
  }
}

class _StartupRetryOverlay extends StatelessWidget {
  const _StartupRetryOverlay({required this.isRetrying, required this.onRetry});

  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRetrying) ...[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Preparing your session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait a moment and try again. We could not reach the server yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isRetrying ? null : onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      disabledBackgroundColor: AppColors.primaryColor
                          .withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isRetrying ? 'Trying again...' : 'Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
