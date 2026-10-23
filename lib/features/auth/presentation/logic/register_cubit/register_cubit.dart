import 'dart:async';

import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/notifications/push_notification.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this.authRepository) : super(RegisterInitial());
  final AuthRepository authRepository;

  Future<void> register({
    required String fullName,
    required String emailAddress,
    required String countryCode,
    required String phoneNumber,
    String? registrationMethod,
  }) async {
    if (isClosed) return;
    await _clearPreviousAccessSession();
    emit(RegisterLoading());
    final cache = sl<SecureCacheHelper>();
    final guestUUID =
        (await cache.getData(key: 'guestUUID'))?.trim() ??
        ((await cache.getData(key: 'guestId'))?.trim() ?? '');
    final firebaseDeviceToken = await _resolveFirebaseDeviceToken();
    appLog(
      '[AUTH][REGISTER] firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
    );
    final registerResult = await authRepository.register(
      fullName: fullName,
      emailAddress: emailAddress,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      guestUUID: guestUUID,
      firebaseDeviceToken: firebaseDeviceToken,
    );

    if (isClosed) return;
    await registerResult.fold(
      (error) async => emit(RegisterError(error: error)),
      (_) async {
        await Future.wait([
          cache.saveData(key: 'email', value: emailAddress.trim()),
          cache.saveData(key: 'countryCode', value: countryCode.trim()),
          cache.saveData(key: 'phoneNumber', value: phoneNumber.trim()),
          cache.saveData(
            key: 'authLoginMethod',
            value: emailAddress.trim().isNotEmpty ? 'email' : 'phone',
          ),
        ]);
        final method = registrationMethod?.trim() ?? '';
        if (method.isNotEmpty) {
          unawaited(
            sl<AppsFlyerService>().logUserRegister(registrationMethod: method),
          );
        }
        emit(RegisterLoaded());
      },
    );
  }

  Future<void> sendVerificationOtp({
    required String method,
    required String emailAddress,
    required String countryCode,
    required String phoneNumber,
  }) async {
    if (isClosed) return;
    emit(RegisterOtpSending());
    final cache = sl<SecureCacheHelper>();
    final guestUUID =
        (await cache.getData(key: 'guestUUID'))?.trim() ??
        ((await cache.getData(key: 'guestId'))?.trim() ?? '');
    final firebaseDeviceToken = await _resolveFirebaseDeviceToken();
    appLog(
      '[AUTH][REGISTER_OTP] firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
    );

    final result = await authRepository.login(
      emailAddress: method == 'email' ? emailAddress.trim() : null,
      countryCode: method == 'phone' ? countryCode.trim() : null,
      phoneNumber: method == 'phone' ? phoneNumber.trim() : null,
      guestUUID: guestUUID,
      firebaseDeviceToken: firebaseDeviceToken,
    );

    if (isClosed) return;

    await result.fold((error) async => emit(RegisterError(error: error)), (
      session,
    ) async {
      final sessionToken = session.token.trim();
      if (sessionToken.isEmpty) {
        emit(
          RegisterError(
            error: ApiErrorModel(
              message: 'Verification failed: session token is missing.',
            ),
          ),
        );
        return;
      }
      if (sessionToken.startsWith('static-')) {
        emit(
          RegisterError(
            error: ApiErrorModel(
              message: 'Verification failed: invalid session token received.',
            ),
          ),
        );
        return;
      }

      if (method == 'email') {
        await Future.wait([
          cache.saveData(key: 'email', value: emailAddress.trim()),
          cache.saveData(key: 'phoneNumber', value: ''),
          cache.saveData(key: 'countryCode', value: ''),
          cache.saveData(key: 'authLoginMethod', value: 'email'),
          cache.saveData(key: 'authSessionToken', value: sessionToken),
        ]);
      } else {
        await Future.wait([
          cache.saveData(key: 'email', value: ''),
          cache.saveData(key: 'phoneNumber', value: phoneNumber.trim()),
          cache.saveData(key: 'countryCode', value: countryCode.trim()),
          cache.saveData(key: 'authLoginMethod', value: 'phone'),
          cache.saveData(key: 'authSessionToken', value: sessionToken),
        ]);
      }

      unawaited(sl<AppsFlyerService>().logConversionEvent('otp_requested'));
      emit(RegisterOtpSent());
    });
  }

  Future<void> _clearPreviousAccessSession() async {
    final cache = sl<SecureCacheHelper>();

    final tasks = <Future<void>>[
      // Pre-OTP state must not retain any access token.
      cache.removeData(key: 'token'),
      cache.removeData(key: 'id'),
      cache.removeData(key: 'userRole'),
      cache.removeData(key: 'authSessionToken'),
    ];
    await Future.wait(tasks);
  }

  Future<String?> _resolveFirebaseDeviceToken() async {
    return PushNotificationsService.resolveAuthFlowToken();
  }
}
