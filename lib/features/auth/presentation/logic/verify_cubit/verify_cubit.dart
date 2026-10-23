import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/notifications/push_notification.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/features/auth/data/models/customer_auth/customer_auth_response.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:camion/features/auth/utils/country_code_normalizer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'verify_state.dart';

class VerifyCubit extends Cubit<VerifyState> {
  VerifyCubit(this.authRepository) : super(VerifyInitial());
  final AuthRepository authRepository;

  Future<void> verify({required String code}) async {
    final cache = sl<SecureCacheHelper>();
    final sessionToken = await cache.getData(key: 'authSessionToken');
    final loginMethod = await cache.getData(key: 'authLoginMethod');

    if (isClosed) return;
    if (sessionToken == null || sessionToken.trim().isEmpty) {
      await sl<AppsFlyerService>().logConversionEvent(
        'otp_failed',
        eventParams: {
          'error_code': 'missing_session_token',
          'error_stage': 'otp_verify',
        },
      );
      emit(
        VerifyError(
          error: ApiErrorModel(
            message: "We're working on it. Please wait a moment and try again.",
          ),
        ),
      );
      return;
    }
    if (sessionToken.trim().startsWith('static-')) {
      await cache.removeData(key: 'authSessionToken');
      await sl<AppsFlyerService>().logConversionEvent(
        'otp_failed',
        eventParams: {
          'error_code': 'invalid_session_token',
          'error_stage': 'otp_verify',
        },
      );
      emit(
        VerifyError(
          error: ApiErrorModel(
            message:
                'Verification failed: invalid session token. Please login again.',
          ),
        ),
      );
      return;
    }

    emit(VerifyLoading());
    final firebaseDeviceToken = await _resolveFirebaseDeviceToken();
    appLog(
      '[AUTH][VERIFY] firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
    );

    final result = await authRepository.verify(
      sessionToken: sessionToken,
      secret: code,
      usePhoneVerification: loginMethod == 'phone',
      firebaseDeviceToken: firebaseDeviceToken,
    );

    if (isClosed) return;

    result.fold((l) async {
      await sl<AppsFlyerService>().logConversionEvent(
        'otp_failed',
        eventParams: {
          'error_code': (l.statusCode ?? '').toString(),
          'error_stage': 'otp_verify',
        },
      );
      if (_requiresRelogin(l)) {
        await _clearAuthVerificationSession();
        emit(
          VerifyError(
            error: ApiErrorModel(
              message:
                  'Your login session has expired or is active on another device. Please login again.',
              statusCode: l.statusCode,
            ),
          ),
        );
        return;
      }
      emit(VerifyError(error: l));
    }, _cacheVerifiedSessionAndEmit);
  }

  Future<void> resend() async {
    final cache = sl<SecureCacheHelper>();
    final loginMethod = await cache.getData(key: 'authLoginMethod');
    final email = await cache.getData(key: 'email');
    final countryCode = await cache.getData(key: 'countryCode');
    final phoneNumber = await cache.getData(key: 'phoneNumber');
    final guestUUID =
        (await cache.getData(key: 'guestUUID'))?.trim() ??
        ((await cache.getData(key: 'guestId'))?.trim() ?? '');
    final firebaseDeviceToken = await _resolveFirebaseDeviceToken();
    appLog(
      '[AUTH][VERIFY_RESEND] firebaseDeviceToken=${PushNotificationsService.maskTokenForLogs(firebaseDeviceToken)}',
    );

    if (loginMethod == 'phone' &&
        countryCode != null &&
        phoneNumber != null &&
        countryCode.isNotEmpty &&
        phoneNumber.isNotEmpty) {
      final result = await authRepository.login(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        guestUUID: guestUUID,
        firebaseDeviceToken: firebaseDeviceToken,
      );
      await result.fold(
        (error) async {
          if (_requiresRelogin(error)) {
            await _clearAuthVerificationSession();
            if (!isClosed) {
              emit(
                VerifyError(
                  error: ApiErrorModel(
                    message:
                        'Your login session has expired or is active on another device. Please login again.',
                    statusCode: error.statusCode,
                  ),
                ),
              );
            }
            return;
          }
          if (!isClosed) emit(VerifyError(error: error));
        },
        (session) async {
          await cache.saveData(key: 'authSessionToken', value: session.token);
        },
      );
      return;
    }

    if (email == null || email.isEmpty) return;
    final result = await authRepository.login(
      emailAddress: email,
      guestUUID: guestUUID,
      firebaseDeviceToken: firebaseDeviceToken,
    );
    await result.fold(
      (error) async {
        if (_requiresRelogin(error)) {
          await _clearAuthVerificationSession();
          if (!isClosed) {
            emit(
              VerifyError(
                error: ApiErrorModel(
                  message:
                      'Your login session has expired or is active on another device. Please login again.',
                  statusCode: error.statusCode,
                ),
              ),
            );
          }
          return;
        }
        if (!isClosed) emit(VerifyError(error: error));
      },
      (session) async {
        await cache.saveData(key: 'authSessionToken', value: session.token);
      },
    );
  }

  bool _requiresRelogin(ApiErrorModel error) {
    final message = (error.message).trim().toLowerCase();
    final statusCode = error.statusCode;
    return statusCode == 401 ||
        message.contains('session has expired') ||
        message.contains('session expired') ||
        message.contains('login session has expired') ||
        message.contains('invalid token') ||
        message.contains('unauthorized');
  }

  Future<void> _clearAuthVerificationSession() async {
    final cache = sl<SecureCacheHelper>();
    await Future.wait([
      cache.removeData(key: 'authSessionToken'),
      cache.removeData(key: 'token'),
      cache.removeData(key: 'id'),
      cache.removeData(key: 'userRole'),
    ]);
  }

  Future<void> _cacheVerifiedSessionAndEmit(CustomerAuthResponse auth) async {
    final accessToken = auth.token.trim();
    if (accessToken.isEmpty) {
      emit(
        VerifyError(
          error: ApiErrorModel(
            message:
                'Verification failed: access token not returned by server.',
          ),
        ),
      );
      return;
    }
    if (accessToken.startsWith('static-')) {
      emit(
        VerifyError(
          error: ApiErrorModel(
            message:
                'Verification failed: invalid access token received. Please try again.',
          ),
        ),
      );
      return;
    }

    final cache = sl<SecureCacheHelper>();
    final loginMethod = ((await cache.getData(key: 'authLoginMethod')) ?? '')
        .trim()
        .toLowerCase();
    final cachedEmail = ((await cache.getData(key: 'email')) ?? '').trim();
    final resolvedEmail = loginMethod == 'email' && cachedEmail.isNotEmpty
        ? cachedEmail
        : auth.customer.emailAddress.trim();
    final existingCountryCode =
        (await cache.getData(key: 'countryCode'))?.trim() ?? '';
    final inferredCountryCode = _extractDialCode(auth.customer.phoneNumber);
    final normalizedCountryCode = inferredCountryCode.isNotEmpty
        ? inferredCountryCode
        : normalizeCountryCode(existingCountryCode);

    await Future.wait([
      cache.saveData(key: 'token', value: accessToken),
      cache.saveData(key: 'id', value: auth.customer.uuid),
      cache.saveData(key: 'userRole', value: auth.customer.role),
      if (resolvedEmail.isNotEmpty)
        cache.saveData(key: 'email', value: resolvedEmail),
      cache.saveData(key: 'phoneNumber', value: auth.customer.phoneNumber),
      cache.saveData(key: 'userName', value: auth.customer.fullName),
      if (normalizedCountryCode.isNotEmpty)
        cache.saveData(key: 'countryCode', value: normalizedCountryCode),
      cache.removeData(key: 'authSessionToken'),
    ]);

    await sl<AppsFlyerService>().syncCustomerUserId(
      customerUserId: auth.customer.uuid,
    );
    await _trackAppsFlyerLogin();
    await _trackTikTokLogin(auth);
    emit(VerifyLoaded(response: auth));
  }

  String _extractDialCode(String phone) {
    final match = RegExp(r'^\+\d{1,4}').firstMatch(phone.trim());
    return match?.group(0) ?? '';
  }

  Future<String?> _resolveFirebaseDeviceToken() async {
    return PushNotificationsService.resolveAuthFlowToken();
  }

  Future<void> _trackTikTokLogin(CustomerAuthResponse auth) async {
    try {
      final customer = auth.customer;
      await TikTokBusinessService.identify(
        externalId: customer.uuid.trim().isEmpty ? null : customer.uuid.trim(),
        externalUserName: customer.fullName.trim().isEmpty
            ? null
            : customer.fullName.trim(),
        phoneNumber: customer.phoneNumber.trim().isEmpty
            ? null
            : customer.phoneNumber.trim(),
        email: customer.emailAddress.trim().isEmpty
            ? null
            : customer.emailAddress.trim(),
      );
      await TikTokBusinessService.login();
    } catch (error, stackTrace) {
      appLog('[TIKTOK][LOGIN] tracking failed: $error');
      appLog(stackTrace.toString());
    }
  }

  Future<void> _trackAppsFlyerLogin() async {
    try {
      await sl<AppsFlyerService>().logUserLogin();
    } catch (error, stackTrace) {
      appLog('[APPSFLYER][LOGIN] tracking failed: $error');
      appLog(stackTrace.toString());
    }
  }
}
