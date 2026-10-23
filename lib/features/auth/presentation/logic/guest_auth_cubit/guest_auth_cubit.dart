import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/notifications/push_notification.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'guest_auth_state.dart';

class GuestAuthCubit extends Cubit<GuestAuthState> {
  GuestAuthCubit(this.authRepository) : super(GuestAuthInitial());

  final AuthRepository authRepository;
  static const Uuid _uuid = Uuid();

  Future<bool> registerGuest({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (isClosed || state is GuestAuthLoading) return false;
    debugPrint(
      '[GUEST][FLOW] Continue as guest tapped. forceRefresh=$forceRefresh silent=$silent',
    );
    final cache = sl<SecureCacheHelper>();
    final existingToken = (await cache.getData(key: 'token'))?.trim() ?? '';
    final cachedGuestUUID =
        (await cache.getData(key: 'guestUUID'))?.trim() ?? '';

    if (!forceRefresh &&
        existingToken.isNotEmpty &&
        cachedGuestUUID.isNotEmpty) {
      debugPrint(
        '[GUEST][FLOW] Skip API hit: existing token + guestUUID found in cache. Reusing token.',
      );
      emit(GuestAuthLoaded(token: existingToken, isSilent: silent));
      return true;
    }
    if (!forceRefresh && existingToken.isNotEmpty && cachedGuestUUID.isEmpty) {
      debugPrint(
        '[GUEST][FLOW] Existing guest token found, but guestUUID missing. Refreshing guest register to recover guestUUID.',
      );
    }

    emit(GuestAuthLoading(isSilent: silent));

    final cachedFcmToken = (PushNotificationsService.token ?? '').trim();
    var firebaseTokenFailed = false;
    String liveFcmToken = '';
    try {
      liveFcmToken =
          (await PushNotificationsService.resolveAuthFlowToken())?.trim() ?? '';
      debugPrint(
        '[GUEST][FLOW] Firebase getToken() success. token=${_maskValue(liveFcmToken)} len=${liveFcmToken.length}',
      );
    } catch (e, st) {
      firebaseTokenFailed = true;
      debugPrint('[GUEST][FLOW] Firebase getToken() failed: $e');
      debugPrint('$st');
    }
    final resolvedFcmToken = liveFcmToken.isNotEmpty
        ? liveFcmToken
        : cachedFcmToken;
    final cachedGuestId = (await cache.getData(key: 'guestId'))?.trim() ?? '';
    final shouldUseSyntheticIdentifiers =
        firebaseTokenFailed || resolvedFcmToken.isEmpty;
    final syntheticDeviceId = shouldUseSyntheticIdentifiers
        ? 'CAM-DEVICE-${_generateEightDigitCode()}'
        : '';
    final syntheticToken = shouldUseSyntheticIdentifiers
        ? 'CAM-TOKEN-${_generateEightDigitCode()}'
        : '';
    final fcmToken = shouldUseSyntheticIdentifiers
        ? syntheticToken
        : resolvedFcmToken;
    final resolvedDeviceId = shouldUseSyntheticIdentifiers
        ? syntheticDeviceId
        : (cachedGuestId.isNotEmpty ? cachedGuestId : fcmToken);
    debugPrint(
      '[GUEST][FLOW] resolvedDeviceId=${_maskValue(resolvedDeviceId)} '
      'cachedGuestId=${_maskValue(cachedGuestId)} '
      'cachedFcm=${_maskValue(cachedFcmToken)} '
      'liveFcm=${_maskValue(liveFcmToken)} '
      'selectedFcm=${_maskValue(fcmToken)} '
      'synthetic=${shouldUseSyntheticIdentifiers ? 'yes' : 'no'}',
    );

    if (resolvedDeviceId.isEmpty) {
      debugPrint(
        '[GUEST][FLOW] Guest register blocked: Firebase token is empty, cannot call API.',
      );
      emit(
        GuestAuthError(
          error: ApiErrorModel(
            message: 'Unable to fetch Firebase token. Please try again.',
          ),
          isSilent: silent,
        ),
      );
      return false;
    }

    var activeDeviceId = resolvedDeviceId;
    debugPrint(
      '[GUEST][FLOW] Hitting guest register API: /v1/auth/guest/register '
      'deviceId=${_maskValue(activeDeviceId)} token=${_maskValue(fcmToken)}',
    );
    var result = await authRepository.registerGuest(
      deviceId: activeDeviceId,
      token: fcmToken,
    );

    // Some backends bind deviceId permanently. If the current ID was already
    // registered, retry once with a fresh unique fallback deviceId.
    if (result.isLeft()) {
      final error = result.swap().getOrElse(
        () => ApiErrorModel(message: 'Unknown guest registration error'),
      );
      if (_isDuplicateDeviceIdError(error.message)) {
        final fallbackDeviceId = _buildFallbackDeviceId(activeDeviceId);
        debugPrint(
          '[GUEST][FLOW] Duplicate deviceId detected. Retrying guest register with fallbackDeviceId=<present>',
        );
        result = await authRepository.registerGuest(
          deviceId: fallbackDeviceId,
          token: fcmToken,
        );
        if (result.isRight()) {
          activeDeviceId = fallbackDeviceId;
          await cache.saveData(key: 'guestId', value: fallbackDeviceId);
        }
      }
    }

    if (isClosed) return false;

    var isSuccess = false;
    await result.fold(
      (error) async {
        debugPrint(
          '[GUEST][FLOW] Guest register failed: ${error.message} (status: ${error.statusCode})',
        );
        final shouldSuppressToast = _isDuplicateDeviceIdError(error.message);
        emit(
          GuestAuthError(
            error: error,
            isSilent: silent || shouldSuppressToast,
          ),
        );
        isSuccess = false;
      },
      (guestToken) async {
        debugPrint(
          '[GUEST][FLOW] Guest register success. token=${_maskValue(guestToken.token)} guestUUID=${_maskValue(guestToken.guestUUID)}',
        );
        final resolvedGuestUUID = guestToken.guestUUID.trim();
        await cache.saveData(key: 'token', value: guestToken.token);
        // Keep device-scoped guest id for x-guest-id continuity across APIs.
        await cache.saveData(key: 'guestId', value: activeDeviceId);
        // Keep backend guest UUID (customer.uuid) for auth payloads.
        await cache.saveData(key: 'guestUUID', value: resolvedGuestUUID);
        await cache.saveData(key: 'authLoginMethod', value: 'guest');
        await cache.removeData(key: 'authSessionToken');
        await sl<AppsFlyerService>().syncCustomerUserId(
          customerUserId: resolvedGuestUUID.isNotEmpty
              ? resolvedGuestUUID
              : activeDeviceId,
        );
        emit(GuestAuthLoaded(token: guestToken.token, isSilent: silent));
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  bool _isDuplicateDeviceIdError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains(
          'a device using the provided device id has already been registered',
        ) ||
        normalized.contains('device id has already been registered') ||
        normalized.contains('deviceid has already been registered');
  }

  String _buildFallbackDeviceId(String base) {
    final seed = base.trim().isNotEmpty ? base.trim() : 'guest-device';
    return '$seed-${_uuid.v4()}';
  }

  String _generateEightDigitCode() {
    final seed = '${DateTime.now().microsecondsSinceEpoch}-${_uuid.v4()}';
    final number = seed.hashCode.abs() % 100000000;
    return number.toString().padLeft(8, '0');
  }

  String _maskValue(String value) {
    if (value.trim().isEmpty) return '<empty>';
    if (value.length <= 10) return value;
    return '${value.substring(0, 5)}...${value.substring(value.length - 5)}';
  }
}
