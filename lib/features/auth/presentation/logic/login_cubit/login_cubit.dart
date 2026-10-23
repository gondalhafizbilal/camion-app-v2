import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/features/auth/data/models/customer_auth/auth_session_token_model.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/notifications/push_notification.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this.authRepository) : super(LoginInitial());
  final AuthRepository authRepository;

  Future<void> login({
    String? emailAddress,
    String? countryCode,
    String? phoneNumber,
  }) async {
    if (isClosed) return;
    final hasEmail = emailAddress != null && emailAddress.trim().isNotEmpty;
    final hasPhone =
        countryCode != null &&
        countryCode.trim().isNotEmpty &&
        phoneNumber != null &&
        phoneNumber.trim().isNotEmpty;
    final normalizedEmailAddress = emailAddress?.trim();
    final normalizedCountryCode = countryCode?.trim();
    final normalizedPhoneNumber = phoneNumber?.trim();

    if (!hasEmail && !hasPhone) {
      emit(
        LoginError(
          error: ApiErrorModel(
            message: 'Enter an email address or phone number to continue.',
          ),
        ),
      );
      return;
    }

    await _clearPreviousAccessSession();
    emit(LoginLoading());
    final cache = sl<SecureCacheHelper>();
    final guestUUID =
        (await cache.getData(key: 'guestUUID'))?.trim() ??
        ((await cache.getData(key: 'guestId'))?.trim() ?? '');
    final firebaseDeviceToken = await _resolveFirebaseDeviceToken();
    appLog(
      '[AUTH][LOGIN] firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
    );

    final result = await authRepository.login(
      emailAddress: hasEmail ? normalizedEmailAddress : null,
      countryCode: hasPhone ? normalizedCountryCode : null,
      phoneNumber: hasPhone ? normalizedPhoneNumber : null,
      guestUUID: guestUUID,
      firebaseDeviceToken: firebaseDeviceToken,
    );

    if (isClosed) return;

    result.fold((l) => emit(LoginError(error: l)), _cacheSessionAndEmit);
  }

  Future<void> _cacheSessionAndEmit(AuthSessionTokenModel session) async {
    final sessionToken = session.token.trim();
    if (sessionToken.isEmpty) {
      emit(
        LoginError(
          error: ApiErrorModel(
            message: 'Login failed: session token not returned by server.',
          ),
        ),
      );
      return;
    }
    if (sessionToken.startsWith('static-')) {
      emit(
        LoginError(
          error: ApiErrorModel(
            message:
                'Login failed: invalid session token received. Please try again.',
          ),
        ),
      );
      return;
    }

    final cache = sl<SecureCacheHelper>();
    await _clearPreviousAccessSession();
    await cache.saveData(key: 'authSessionToken', value: sessionToken);
    await sl<AppsFlyerService>().logConversionEvent('otp_requested');
    emit(LoginLoaded(session: session));
  }

  Future<void> _clearPreviousAccessSession() async {
    final cache = sl<SecureCacheHelper>();

    final tasks = <Future<void>>[
      // Pre-OTP state must never keep an access token; user is authenticated
      // only after verify succeeds and writes a fresh customer token.
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
