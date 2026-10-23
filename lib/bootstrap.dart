import 'dart:async';
import 'dart:convert';

import 'package:camion/camion_app.dart';
import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/notifications/push_notification.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/app_update_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/currency/data/repository/currency_repo.dart';
import 'package:camion/features/currency/presentation/logic/cubit/currency_cubit.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

bool isLoggedInUser = false;
bool _bootstrapStarted = false;

Future<void> bootstrap({
  required AppFlavor flavor,
  required String envFile,
  required FirebaseOptions firebaseOptions,
}) async {
  if (_bootstrapStarted) return;
  _bootstrapStarted = true;

  await runZonedGuarded(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        await _loadEnvFile(envFile);
        AppConfig.initialize(flavor: flavor, envFile: envFile);

        await setupServiceLocator();
        await sl<CacheHelper>().init();
        await _runStartupStep(
          'runtime_environment_migration',
          _enforceRuntimeEnvironmentMigration,
        );
        await _runStartupStep(
          'clear_expired_cached_auth_token',
          _clearExpiredCachedAuthTokenIfNeeded,
        );
        await _runStartupStep('app_build_migration', _enforceAppBuildMigration);
        await _runStartupStep(
          'qatar_defaults_migration',
          _enforceQatarDefaultsMigration,
        );
        _disableConsoleLoggingForRelease();

        runApp(
          DevicePreview(
            enabled: false,
            builder: (BuildContext context) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) =>
                      LocalizationsCubit()..loadSavedLanguage(),
                ),
                BlocProvider(
                  create: (context) =>
                      CurrencyCubit(sl<CurrencyRepository>())
                        ..loadSavedCurrency(),
                ),
              ],
              child: const CamionApp(),
            ),
          ),
        );

        unawaited(_runDeferredStartupWork(firebaseOptions));
      } catch (error, stackTrace) {
        appLog(
          '[BOOTSTRAP] startup failed before runApp: $error',
          error: error,
          stackTrace: stackTrace,
        );
        runApp(
          _BootstrapFailureApp(
            error: error.toString(),
            showDetails: !flavor.isProduction,
          ),
        );
      }
    },
    (error, stackTrace) {
      appLog(
        '[BOOTSTRAP] unhandled error: $error',
        error: error,
        stackTrace: stackTrace,
      );
    },
    zoneSpecification: flavor.isProduction
        ? ZoneSpecification(print: (self, parent, zone, message) {})
        : null,
  );
}

Future<void> _runDeferredStartupWork(FirebaseOptions firebaseOptions) async {
  unawaited(
    _runStartupStep('auto_locale_from_ip', _applyAutoLocaleFromIpIfNeeded),
  );
  unawaited(
    _runStartupStep('appsflyer_initialize', sl<AppsFlyerService>().initialize),
  );
  unawaited(_postAppBootstrap(firebaseOptions));
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.error, required this.showDetails});

  final String error;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFB92123),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App failed to start',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (showDetails) ...[
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Please close and reopen the app. If this keeps happening, update to the latest version.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _loadEnvFile(String envFile) async {
  try {
    await dotenv.load(fileName: envFile);
  } catch (_) {
    throw StateError(
      'Missing environment file: $envFile. '
      'Use .env.development or .env.production for flavored runs.',
    );
  }
}

Future<void> _runStartupStep(String name, Future<void> Function() step) async {
  try {
    await step();
  } catch (error, stackTrace) {
    appLog(
      '[BOOTSTRAP] startup step failed: $name error=$error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _postAppBootstrap(FirebaseOptions firebaseOptions) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ScreenUtil.ensureScreenSize();

  await Firebase.initializeApp(options: firebaseOptions);
  final crashlyticsEnabled = AppConfig.instance.flavor.isProduction;
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    crashlyticsEnabled,
  );

  if (crashlyticsEnabled) {
    FlutterError.onError = _recordProductionFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_shouldSuppressCrashlyticsCrash(error, stack)) {
        _recordSuppressedCrashlyticsNonFatal(error, stack);
        return true;
      }
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = (error, stack) {
      return false;
    };
  }

  await PushNotificationsService.init();
  await PushNotificationsService.handleNotifications();
  await _clearStaticAuthArtifactsIfNeeded();
  await _initializeTikTok();

  final existingGuestId = await sl<SecureCacheHelper>().getData(key: 'guestId');
  if (existingGuestId == null || existingGuestId.isEmpty) {
    final newGuestId = const Uuid().v4();
    await sl<SecureCacheHelper>().saveData(key: 'guestId', value: newGuestId);
  }
  await sl<AppsFlyerService>().syncCustomerUserId();
  await sl<AppsFlyerService>().logAppOpen();

  await checkIfUserIsLoggedIn();
  unawaited(_validateCustomerSessionInBackground());
}

void _recordProductionFlutterError(FlutterErrorDetails details) {
  if (_shouldSuppressCrashlyticsCrash(details.exception, details.stack)) {
    _recordSuppressedCrashlyticsNonFatal(details.exception, details.stack);
    return;
  }
  FirebaseCrashlytics.instance.recordFlutterFatalError(details);
}

bool _shouldSuppressCrashlyticsCrash(Object error, StackTrace? stack) {
  final errorText = error.toString();
  final stackText = stack?.toString() ?? '';
  final combined = '$errorText\n$stackText';

  return _isRenderFlexOverflowReport(combined) ||
      _isTransientNetworkImageReport(combined);
}

bool _isRenderFlexOverflowReport(String report) {
  return report.contains('RenderFlex overflowed') ||
      report.contains('A RenderFlex overflowed');
}

bool _isTransientNetworkImageReport(String report) {
  final isImageStreamError =
      report.contains('MultiImageStreamCompleter') ||
      report.contains('ImageStreamCompleter') ||
      report.contains('cached_network_image');
  if (!isImageStreamError) return false;

  final isNetworkFailure =
      report.contains('ClientException') ||
      report.contains('SocketException') ||
      report.contains('Connection closed while receiving data') ||
      report.contains('Connection reset by peer') ||
      report.contains('Failed host lookup');
  return isNetworkFailure;
}

void _recordSuppressedCrashlyticsNonFatal(Object error, StackTrace? stack) {
  final normalizedStack = stack ?? StackTrace.current;
  unawaited(
    FirebaseCrashlytics.instance.recordError(
      error,
      normalizedStack,
      fatal: false,
    ),
  );
}

Future<void> _initializeTikTok() async {
  if (defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  try {
    debugPrint('[TIKTOK][BOOTSTRAP] initialize() start');
    await TikTokBusinessService.initialize();
    debugPrint('[TIKTOK][BOOTSTRAP] initialize() done');
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('[TIKTOK][BOOTSTRAP] requestTrackingAuthorization() start');
      await TikTokBusinessService.requestTrackingAuthorization();
      debugPrint('[TIKTOK][BOOTSTRAP] requestTrackingAuthorization() done');
    }
    debugPrint('[TIKTOK][BOOTSTRAP] launchApp() start');
    await TikTokBusinessService.launchApp();
    debugPrint('[TIKTOK][BOOTSTRAP] launchApp() done');
  } catch (error, stackTrace) {
    debugPrint('[TIKTOK][BOOTSTRAP] initialization failed: $error');
    debugPrint(stackTrace.toString());
  }
}

void _disableConsoleLoggingForRelease() {
  if (!AppConfig.instance.flavor.isProduction) {
    return;
  }
  debugPrint = (String? message, {int? wrapWidth}) {};
}

Future<void> _clearStaticAuthArtifactsIfNeeded() async {
  final secureCache = sl<SecureCacheHelper>();
  final token = (await secureCache.getData(key: 'token'))?.trim() ?? '';
  final authSessionToken =
      (await secureCache.getData(key: 'authSessionToken'))?.trim() ?? '';

  if (token.startsWith('static-')) {
    await secureCache.removeData(key: 'token');
  }
  if (authSessionToken.startsWith('static-')) {
    await secureCache.removeData(key: 'authSessionToken');
  }
}

Future<void> _enforceRuntimeEnvironmentMigration() async {
  final cache = sl<CacheHelper>();
  final secureCache = sl<SecureCacheHelper>();
  final currentRuntimeMarker = AppConfig.instance.runtimeEnvironmentMarker;
  final previousRuntimeMarker = cache.getDataString(
    key: 'runtimeEnvironmentMarkerV1',
  );
  final previousBuildMarker = cache.getDataString(
    key: 'installedAppBuildMarkerV1',
  );
  final currentFlavorPrefix = '${AppConfig.instance.flavor.name}:';

  final runtimeChanged =
      previousRuntimeMarker != null &&
      previousRuntimeMarker != currentRuntimeMarker;
  final legacyFlavorChanged =
      previousRuntimeMarker == null &&
      previousBuildMarker != null &&
      !previousBuildMarker.startsWith(currentFlavorPrefix);

  if (runtimeChanged || legacyFlavorChanged) {
    await _clearAuthArtifactsForRuntimeEnvironmentMigration(secureCache);
  }
  await _clearStaleAuthArtifactsForCurrentRuntime(
    secureCache,
    currentRuntimeMarker,
  );

  await cache.saveData(
    key: 'runtimeEnvironmentMarkerV1',
    value: currentRuntimeMarker,
  );
}

Future<void> _clearAuthArtifactsForRuntimeEnvironmentMigration(
  SecureCacheHelper secureCache,
) async {
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
    'guestId',
    'x-guest-id',
  ];
  for (final key in keys) {
    await secureCache.removeData(key: key);
  }
}

Future<void> _clearStaleAuthArtifactsForCurrentRuntime(
  SecureCacheHelper secureCache,
  String currentRuntimeMarker,
) async {
  final token = (await secureCache.getData(key: 'token'))?.trim() ?? '';
  final authSessionToken =
      (await secureCache.getData(key: 'authSessionToken'))?.trim() ?? '';
  if (token.isEmpty && authSessionToken.isEmpty) return;

  final authRuntimeMarker =
      (await secureCache.getData(
        key: 'authRuntimeEnvironmentMarkerV1',
      ))?.trim() ??
      '';
  if (authRuntimeMarker == currentRuntimeMarker) return;

  await _clearAuthSessionArtifacts(secureCache);
}

Future<void> _clearExpiredCachedAuthTokenIfNeeded() async {
  final secureCache = sl<SecureCacheHelper>();
  final token = (await secureCache.getData(key: 'token'))?.trim() ?? '';
  if (token.isEmpty) return;
  if (!_isJwtExpired(token)) return;
  await _clearAuthSessionArtifacts(secureCache);
}

Future<void> _enforceAppBuildMigration() async {
  final cache = sl<CacheHelper>();
  final secureCache = sl<SecureCacheHelper>();
  final packageInfo = await PackageInfo.fromPlatform();
  final currentBuildMarker =
      '${AppConfig.instance.flavor.name}:${packageInfo.version}+${packageInfo.buildNumber}';
  final previousBuildMarker = cache.getDataString(
    key: 'installedAppBuildMarkerV1',
  );

  if (previousBuildMarker == currentBuildMarker) return;

  if (await _hasGuestSession(secureCache)) {
    await _clearGuestAuthArtifactsForBuildMigration(secureCache);
  }
  await sl<AppUpdateService>().clearStartupCache();
  await cache.saveData(
    key: 'installedAppBuildMarkerV1',
    value: currentBuildMarker,
  );
}

Future<bool> _hasGuestSession(SecureCacheHelper secureCache) async {
  final loginMethod =
      ((await secureCache.getData(key: 'authLoginMethod')) ?? '')
          .trim()
          .toLowerCase();
  return loginMethod == 'guest';
}

Future<void> _clearGuestAuthArtifactsForBuildMigration(
  SecureCacheHelper secureCache,
) async {
  await _clearAuthSessionArtifacts(secureCache, includeCustomerProfile: false);
}

Future<void> _clearAuthSessionArtifacts(
  SecureCacheHelper secureCache, {
  bool includeCustomerProfile = true,
}) async {
  final keys = <String>[
    'token',
    'authSessionToken',
    'authLoginMethod',
    'guestUUID',
    'authRuntimeEnvironmentMarkerV1',
    if (includeCustomerProfile) ...[
      'id',
      'userRole',
      'email',
      'userName',
      'phoneNumber',
      'countryCode',
    ],
  ];
  for (final key in keys) {
    await secureCache.removeData(key: key);
  }
}

Future<void> checkIfUserIsLoggedIn() async {
  final token = (await sl<SecureCacheHelper>().getData(key: 'token'))?.trim();
  isLoggedInUser = token != null && token.isNotEmpty;
}

Future<void> _validateCustomerSessionInBackground() async {
  final secureCache = sl<SecureCacheHelper>();
  final token = (await secureCache.getData(key: 'token'))?.trim() ?? '';
  if (token.isEmpty) return;

  final loginMethod =
      ((await secureCache.getData(key: 'authLoginMethod')) ?? '')
          .trim()
          .toLowerCase();
  if (loginMethod == 'guest') return;

  try {
    await sl<ApiConsumer>().post(
      EndPoints.graphql,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'x-suppress-backend-unavailable': 'true',
      },
      data: const <String, dynamic>{
        'query': '''
query GetCurrentCustomer {
  getCurrentCustomer {
    uuid
  }
}
''',
        'variables': <String, dynamic>{},
      },
    );
  } catch (_) {
    // UnauthorizedRecoveryInterceptor owns clearing and redirecting on auth
    // failures. Network/offline failures should not eagerly log users out.
  }
}

bool _isJwtExpired(String token) {
  final payload = _decodeJwtPayload(token);
  if (payload == null) return false;

  final exp = payload['exp'];
  final expiresAtSeconds = exp is int
      ? exp
      : exp is num
      ? exp.toInt()
      : int.tryParse(exp?.toString() ?? '');
  if (expiresAtSeconds == null) return false;

  final expiresAt = DateTime.fromMillisecondsSinceEpoch(
    expiresAtSeconds * 1000,
    isUtc: true,
  );
  return !expiresAt.isAfter(DateTime.now().toUtc());
}

Map<String, dynamic>? _decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;

  try {
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = jsonDecode(decoded);
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map(
        (key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
  } catch (_) {}
  return null;
}

Future<void> _enforceQatarDefaultsMigration() async {
  final cache = sl<CacheHelper>();
  final alreadyMigrated =
      cache.getData(key: 'qatarDefaultsMigrationV1') == true;

  if (!alreadyMigrated) {
    await cache.saveData(
      key: 'languageCode',
      value: AppDefaults.defaultLanguageCode,
    );
    await cache.saveData(
      key: 'currencyCode',
      value: AppDefaults.defaultCurrencyCode,
    );
    await cache.saveData(
      key: 'currencySymbol',
      value: AppDefaults.defaultCurrencySymbol,
    );
    await cache.saveData(key: 'qatarDefaultsMigrationV1', value: true);
    return;
  }

  if ((cache.getDataString(key: 'languageCode') ?? '').isEmpty) {
    await cache.saveData(
      key: 'languageCode',
      value: AppDefaults.defaultLanguageCode,
    );
  }
  if ((cache.getDataString(key: 'currencyCode') ?? '').isEmpty) {
    await cache.saveData(
      key: 'currencyCode',
      value: AppDefaults.defaultCurrencyCode,
    );
  }
  if ((cache.getDataString(key: 'currencySymbol') ?? '').isEmpty) {
    await cache.saveData(
      key: 'currencySymbol',
      value: AppDefaults.defaultCurrencySymbol,
    );
  }
}

Future<void> _applyAutoLocaleFromIpIfNeeded() async {
  final cache = sl<CacheHelper>();
  final languageSelectionSource =
      (cache.getDataString(key: 'languageSelectionSourceV1') ?? '')
          .trim()
          .toLowerCase();
  final currencySelectionSource =
      (cache.getDataString(key: 'currencySelectionSourceV1') ?? '')
          .trim()
          .toLowerCase();

  final languageAlreadyResolved =
      cache.getData(key: 'languageAutoResolvedV1') == true;
  final currencyAlreadyResolved =
      cache.getData(key: 'currencyAutoResolvedV1') == true;
  final savedLanguageCode = (cache.getDataString(key: 'languageCode') ?? '')
      .trim()
      .toLowerCase();
  final savedCurrencyCode = (cache.getDataString(key: 'currencyCode') ?? '')
      .trim()
      .toUpperCase();
  final languageSelectionIsManual =
      languageSelectionSource == 'manual' ||
      (languageSelectionSource.isEmpty &&
          savedLanguageCode.isNotEmpty &&
          savedLanguageCode != AppDefaults.defaultLanguageCode);
  final currencySelectionIsManual =
      currencySelectionSource == 'manual' ||
      (currencySelectionSource.isEmpty &&
          savedCurrencyCode.isNotEmpty &&
          savedCurrencyCode != AppDefaults.defaultCurrencyCode);

  if (languageSelectionIsManual && currencySelectionIsManual) {
    return;
  }
  if (languageAlreadyResolved && currencyAlreadyResolved) {
    return;
  }

  final countryCode = await _detectCountryCodeFromIp();
  final normalizedCountryCode = (countryCode ?? '').trim().toUpperCase();

  if (!languageSelectionIsManual && !languageAlreadyResolved) {
    final detectedLanguage = _languageCodeFromCountry(normalizedCountryCode);
    final availableLanguages = await _loadAvailableLanguageCodes();
    final selectedLanguage = availableLanguages.contains(detectedLanguage)
        ? detectedLanguage
        : AppDefaults.defaultLanguageCode.toLowerCase();
    await cache.saveData(key: 'languageCode', value: selectedLanguage);
    await cache.saveData(key: 'languageSelectionSourceV1', value: 'auto');
    await cache.saveData(key: 'languageAutoResolvedV1', value: true);
  }

  if (!currencySelectionIsManual && !currencyAlreadyResolved) {
    final detectedCurrencyCode = _currencyCodeFromCountry(
      normalizedCountryCode,
    );
    final normalizedDetected = (detectedCurrencyCode ?? '')
        .trim()
        .toUpperCase();
    final fallbackCode = AppDefaults.defaultCurrencyCode.trim().toUpperCase();

    final allCodes = await _loadAvailableCurrencyCodes();
    final selectedCode = allCodes.contains(normalizedDetected)
        ? normalizedDetected
        : fallbackCode;

    await cache.saveData(key: 'currencyCode', value: selectedCode);
    await cache.saveData(key: 'currencySymbol', value: selectedCode);
    await cache.saveData(key: 'currencySelectionSourceV1', value: 'auto');
    await cache.saveData(key: 'currencyAutoResolvedV1', value: true);
  }
}

Future<Set<String>> _loadAvailableCurrencyCodes() async {
  final token = await sl<SecureCacheHelper>().getData(key: 'token');
  final result = await sl<CurrencyRepository>().getCurrenciesGraphql(
    token: token?.toString(),
  );
  return result.fold(
    (_) => <String>{AppDefaults.defaultCurrencyCode.toUpperCase()},
    (list) =>
        list
            .map((currency) => currency.code.trim().toUpperCase())
            .where((code) => code.isNotEmpty)
            .toSet()
          ..add(AppDefaults.defaultCurrencyCode.toUpperCase()),
  );
}

Future<Set<String>> _loadAvailableLanguageCodes() async {
  final token = await sl<SecureCacheHelper>().getData(key: 'token');
  final result = await sl<HomeRepository>().getLanguagesGraphql(
    token: token?.toString(),
  );
  return result.fold(
    (_) => <String>{AppDefaults.defaultLanguageCode.toLowerCase()},
    (list) =>
        list
            .map((language) => language.shortCode.trim().toLowerCase())
            .where((code) => code.isNotEmpty)
            .toSet()
          ..add(AppDefaults.defaultLanguageCode.toLowerCase()),
  );
}

Future<String?> _detectCountryCodeFromIp() async {
  try {
    final response = await sl<Dio>().get<dynamic>(
      'https://api.ipquery.io/?format=json',
      options: Options(
        headers: const <String, String>{'x-suppress-error-toast': 'true'},
        responseType: ResponseType.json,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final body = response.data;
    if (body is! Map) return null;
    final map = body.map((key, value) => MapEntry(key.toString(), value));

    final countryCode = _extractStringByPath(map, const [
      ['location', 'country_code'],
      ['country_code'],
      ['location', 'countryCode'],
      ['countryCode'],
    ]);
    if (countryCode == null || countryCode.trim().isEmpty) return null;
    return countryCode.trim().toUpperCase();
  } catch (_) {
    return null;
  }
}

String? _extractStringByPath(
  Map<String, dynamic> root,
  List<List<String>> paths,
) {
  for (final path in paths) {
    dynamic current = root;
    for (final segment in path) {
      if (current is! Map) {
        current = null;
        break;
      }
      current = current[segment];
    }
    final value = current?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _currencyCodeFromCountry(String countryCode) {
  const map = <String, String>{
    'AE': 'AED',
    'BH': 'BHD',
    'EG': 'EGP',
    'EU': 'EUR',
    'GB': 'GBP',
    'IN': 'INR',
    'JO': 'JOD',
    'KW': 'KWD',
    'OM': 'OMR',
    'PK': 'PKR',
    'QA': 'QAR',
    'SA': 'SAR',
    'TR': 'TRY',
    'US': 'USD',
  };
  return map[countryCode];
}

String _languageCodeFromCountry(String countryCode) {
  const arabicCountries = <String>{
    'AE',
    'BH',
    'DZ',
    'EG',
    'IQ',
    'JO',
    'KW',
    'LB',
    'LY',
    'MA',
    'OM',
    'PS',
    'QA',
    'SA',
    'SD',
    'SY',
    'TN',
    'YE',
  };
  const englishCountries = <String>{'AU', 'CA', 'GB', 'IN', 'NZ', 'US'};

  if (arabicCountries.contains(countryCode)) {
    return 'ar';
  }
  if (englishCountries.contains(countryCode)) {
    return 'en';
  }
  return AppDefaults.defaultLanguageCode;
}
