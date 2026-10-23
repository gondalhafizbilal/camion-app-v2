import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/apple_auth_service.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/core/services/facebook_auth_service.dart';
import 'package:camion/core/services/startup_gate_service.dart';
import 'package:camion/core/services/transient_extras_store.dart';
import 'package:camion/core/services/service_locator.dart' show sl;
import 'package:camion/core/services/google_auth_service.dart';
import 'package:dio/dio.dart';

Future<void> initCore() async {
  sl.registerSingleton<Dio>(Dio());
  sl.registerSingleton<CacheHelper>(CacheHelper());
  sl.registerSingleton<SecureCacheHelper>(SecureCacheHelper());
  sl.registerSingleton<AuthSessionNotifier>(
    AuthSessionNotifier(secureCacheHelper: sl<SecureCacheHelper>()),
  );
  sl.registerSingleton<StartupGateService>(StartupGateService());
  sl.registerSingleton<TransientExtrasStore>(TransientExtrasStore());
  sl.registerLazySingleton<AppsFlyerService>(() => AppsFlyerService());
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  sl.registerLazySingleton<FacebookAuthService>(() => FacebookAuthService());
  sl.registerLazySingleton<AppleAuthService>(() => AppleAuthService());
  await sl<AuthSessionNotifier>().syncFromCache();
}
