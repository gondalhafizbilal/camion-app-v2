import 'package:camion/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_factory.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:camion/features/auth/data/models/customer_auth/auth_session_token_model.dart';
import 'package:camion/features/auth/data/models/customer_auth/customer_auth_payloads.dart';
import 'package:camion/features/auth/data/models/customer_auth/customer_auth_response.dart';
import 'package:camion/features/auth/data/models/customer_auth/customer_model.dart';
import 'package:camion/features/auth/utils/country_code_normalizer.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class GuestRegisterResult {
  const GuestRegisterResult({required this.token, required this.guestUUID});

  final String token;
  final String guestUUID;
}

class AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  static const int _guestRegisterMaxAttempts = 3;
  static const List<Duration> _guestRegisterRetryDelays = <Duration>[
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
  ];

  AuthRepository({required this.authRemoteDataSource});

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-'
    r'[0-9a-fA-F]{12}$',
  );

  String _normalizedGuestUuidOrEmpty(String? rawGuestUUID) {
    final candidate = (rawGuestUUID ?? '').trim();
    if (candidate.isEmpty) return '';
    return _uuidRegex.hasMatch(candidate) ? candidate : '';
  }

  Future<Either<ApiErrorModel, CustomerAuthResponse>> register({
    required String fullName,
    required String emailAddress,
    required String countryCode,
    required String phoneNumber,
    String? guestUUID,
    String? firebaseDeviceToken,
  }) async {
    try {
      final normalizedGuestUUID = _normalizedGuestUuidOrEmpty(guestUUID);
      final response = await authRemoteDataSource.registerCustomer(
        payload: RegisterCustomerPayload(
          fullName: fullName.trim(),
          emailAddress: emailAddress.trim(),
          countryCode: normalizeCountryCode(countryCode),
          phoneNumber: phoneNumber.trim(),
          guestUUID: normalizedGuestUUID,
          firebaseDeviceToken: firebaseDeviceToken?.trim(),
        ),
      );
      return Right(CustomerAuthResponse.fromJson(_asMap(response.data)));
    } catch (e) {
      appLog("repoooo${e.toString()}");
      if (e is DioException) {
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode >= 500) {
          return left(
            ApiErrorModel(
              message: ApiErrorFactory.maintenanceMessage,
              statusCode: statusCode,
            ),
          );
        }
      }
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, AuthSessionTokenModel>> login({
    String? emailAddress,
    String? countryCode,
    String? phoneNumber,
    String? guestUUID,
    String? firebaseDeviceToken,
  }) async {
    try {
      final hasPhone =
          countryCode != null &&
          countryCode.trim().isNotEmpty &&
          phoneNumber != null &&
          phoneNumber.trim().isNotEmpty;
      final hasEmail = emailAddress != null && emailAddress.trim().isNotEmpty;
      final normalizedCountryCode = countryCode?.trim();
      final normalizedPhoneNumber = phoneNumber?.trim();
      final normalizedEmailAddress = emailAddress?.trim();
      final normalizedGuestUUID = _normalizedGuestUuidOrEmpty(guestUUID);

      if (!hasPhone && !hasEmail) {
        return left(
          ApiErrorModel(message: 'Email address or phone number is required'),
        );
      }

      if (hasPhone) {
        final response = await authRemoteDataSource.loginWithPhone(
          payload: LoginWithPhonePayload(
            countryCode: normalizeCountryCode(normalizedCountryCode),
            phoneNumber: normalizedPhoneNumber ?? '',
            guestUUID: normalizedGuestUUID,
            firebaseDeviceToken: firebaseDeviceToken?.trim(),
          ),
        );
        return Right(AuthSessionTokenModel.fromJson(_asMap(response.data)));
      }

      final response = await authRemoteDataSource.loginWithEmail(
        payload: LoginWithEmailPayload(
          emailAddress: normalizedEmailAddress ?? '',
          guestUUID: normalizedGuestUUID,
          firebaseDeviceToken: firebaseDeviceToken?.trim(),
        ),
      );
      return Right(AuthSessionTokenModel.fromJson(_asMap(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, CustomerAuthResponse>> loginWithGoogleIdToken({
    required String idToken,
    String? guestUUID,
    String? firebaseDeviceToken,
  }) async {
    final normalizedIdToken = idToken.trim();
    if (normalizedIdToken.isEmpty) {
      return left(ApiErrorModel(message: 'Google ID token is required'));
    }

    try {
      final response = await authRemoteDataSource.loginWithGoogleOauth(
        payload: GoogleOauthPayload(
          idToken: normalizedIdToken,
          guestUUID: _normalizedGuestUuidOrEmpty(guestUUID),
          firebaseDeviceToken: firebaseDeviceToken?.trim(),
        ),
      );
      return Right(CustomerAuthResponse.fromJson(_asMap(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, CustomerAuthResponse>>
  loginWithFacebookAccessToken({
    required String accessToken,
    String? guestUUID,
    String? firebaseDeviceToken,
  }) async {
    final normalizedAccessToken = accessToken.trim();
    if (kDebugMode) {
      debugPrint(
        '[AUTH][FACEBOOK][REPO] loginWithFacebookAccessToken() called tokenLength=${normalizedAccessToken.length}',
      );
    }
    if (normalizedAccessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[AUTH][FACEBOOK][REPO] rejected: empty access token after trim',
        );
      }
      return left(ApiErrorModel(message: 'Facebook access token is required'));
    }

    try {
      if (kDebugMode) {
        debugPrint('[AUTH][FACEBOOK][REPO] calling remote data source');
      }
      final response = await authRemoteDataSource.loginWithFacebookOauth(
        payload: FacebookOauthPayload(
          accessToken: normalizedAccessToken,
          guestUUID: _normalizedGuestUuidOrEmpty(guestUUID),
          firebaseDeviceToken: firebaseDeviceToken?.trim(),
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[AUTH][FACEBOOK][REPO] remote success status=${response.statusCode}',
        );
      }
      final mapped = CustomerAuthResponse.fromJson(_asMap(response.data));
      if (kDebugMode) {
        debugPrint(
          '[AUTH][FACEBOOK][REPO] mapped response tokenLength=${mapped.token.trim().length} customerUuid=${mapped.customer.uuid} role=${mapped.customer.role}',
        );
      }
      return Right(mapped);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH][FACEBOOK][REPO] exception: $e');
      }
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, CustomerAuthResponse>> loginWithAppleIdToken({
    required String identityToken,
    String? guestUUID,
    String? authorizationCode,
    String? fullName,
    String? firebaseDeviceToken,
  }) async {
    final normalizedIdentityToken = identityToken.trim();
    if (normalizedIdentityToken.isEmpty) {
      return left(ApiErrorModel(message: 'Apple identity token is required'));
    }

    try {
      final response = await authRemoteDataSource.loginWithAppleOauth(
        payload: AppleOauthPayload(
          identityToken: normalizedIdentityToken,
          guestUUID: _normalizedGuestUuidOrEmpty(guestUUID),
          authorizationCode: authorizationCode?.trim(),
          fullName: fullName?.trim(),
          firebaseDeviceToken: firebaseDeviceToken?.trim(),
        ),
      );
      return Right(CustomerAuthResponse.fromJson(_asMap(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, GuestRegisterResult>> registerGuest({
    required String deviceId,
    required String token,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _guestRegisterMaxAttempts; attempt++) {
      try {
        final response = await authRemoteDataSource.registerGuest(
          payload: RegisterGuestPayload(
            deviceId: deviceId.trim(),
            token: token.trim(),
          ),
        );
        final data = _asMap(response.data);
        final resolvedToken = _extractToken(data);
        final resolvedGuestUUID = _extractGuestUUID(data);
        if (resolvedToken.isEmpty) {
          return left(
            ApiErrorModel(
              message: 'Guest session token was not returned by API',
            ),
          );
        }
        if (resolvedGuestUUID.isEmpty) {
          return left(
            ApiErrorModel(
              message:
                  'Guest UUID was not returned by API (customer.uuid missing)',
            ),
          );
        }
        return Right(
          GuestRegisterResult(
            token: resolvedToken,
            guestUUID: resolvedGuestUUID,
          ),
        );
      } catch (e) {
        lastError = e;
        final shouldRetry =
            attempt < _guestRegisterMaxAttempts && _isBackendNotResponding(e);
        if (!shouldRetry) {
          if (_isBackendNotResponding(e)) {
            return left(
              ApiErrorModel(
                message:
                    'Server is not responding right now. Please try again later.',
                statusCode: 503,
              ),
            );
          }
          return left(ApiErrorHandler.handle(e));
        }

        final delay = _guestRegisterRetryDelays[attempt - 1];
        await Future<void>.delayed(delay);
      }
    }

    if (_isBackendNotResponding(lastError)) {
      return left(
        ApiErrorModel(
          message:
              'Server is not responding right now. Please try again later.',
          statusCode: 503,
        ),
      );
    }
    return left(ApiErrorHandler.handle(lastError));
  }

  bool _isBackendNotResponding(Object? error) {
    if (error is! DioException) return false;

    final statusCode = error.response?.statusCode;
    if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
      return true;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return error.response == null;
      default:
        return false;
    }
  }

  Future<Either<ApiErrorModel, CustomerAuthResponse>> verify({
    required String sessionToken,
    required String secret,
    required bool usePhoneVerification,
    String? firebaseDeviceToken,
  }) async {
    try {
      final payload = VerifyCustomerPayload(
        token: sessionToken.trim(),
        secret: secret.trim(),
        firebaseDeviceToken: firebaseDeviceToken?.trim(),
      );
      final response = usePhoneVerification
          ? await authRemoteDataSource.verifyPhone(payload: payload)
          : await authRemoteDataSource.verifyEmail(payload: payload);
      return Right(CustomerAuthResponse.fromJson(_asMap(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, void>> logout({
    required String accessToken,
  }) async {
    try {
      await authRemoteDataSource.logoutCustomer(accessToken: accessToken);
      return const Right(null);
    } catch (e) {
      return left(ApiErrorHandler.handle(e, showNoDataPopup: false));
    }
  }

  Future<Either<ApiErrorModel, CustomerModel>> updateCustomerProfile({
    required String accessToken,
    required String fullName,
  }) async {
    try {
      final response = await authRemoteDataSource.updateCustomerProfile(
        accessToken: accessToken,
        payload: UpdateCustomerProfilePayload(fullName: fullName.trim()),
      );
      return Right(CustomerModel.fromJson(_asMap(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, CustomerModel>> updateCustomerEmailAddress({
    required String accessToken,
    required String emailAddress,
  }) async {
    try {
      final response = await authRemoteDataSource.updateCustomerEmailAddress(
        accessToken: accessToken,
        payload: UpdateCustomerEmailPayload(emailAddress: emailAddress.trim()),
      );
      return Right(CustomerModel.fromJson(_asMap(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> sendUserShippingAddress({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String postcode,
    required String country,
    required String shippingFirstName,
    required String shippingLastName,
    required String shippingEmail,
    required String shippingPhone,
    required String shippingAddress1,
    required String shippingAddress2,
    required String shippingCity,
    required String shippingState,
    required String shippingPostcode,
    required String shippingCountry,
  }) async {
    try {
      final resolvedPostcode = postcode.trim().isEmpty
          ? '0000'
          : postcode.trim();
      final resolvedShippingPostcode = shippingPostcode.trim().isEmpty
          ? '0000'
          : shippingPostcode.trim();
      final response = await authRemoteDataSource.sendUserShippingAddress(
        token: token,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address1: address1,
        address2: address2,
        city: city,
        state: state,
        postcode: resolvedPostcode,
        country: country,
        shippingFirstName: shippingFirstName,
        shippingLastName: shippingLastName,
        shippingEmail: shippingEmail,
        shippingPhone: shippingPhone,
        shippingAddress1: shippingAddress1,
        shippingAddress2: shippingAddress2,
        shippingCity: shippingCity,
        shippingState: shippingState,
        shippingPostcode: resolvedShippingPostcode,
        shippingCountry: shippingCountry,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const FormatException('Unexpected response format');
  }

  String _extractToken(Map<String, dynamic> data) {
    final direct = data['token']?.toString() ?? '';
    if (direct.trim().isNotEmpty) return direct.trim();

    final accessToken = data['accessToken']?.toString() ?? '';
    if (accessToken.trim().isNotEmpty) return accessToken.trim();

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      final nested = nestedData['token']?.toString() ?? '';
      if (nested.trim().isNotEmpty) return nested.trim();
    }

    final nestedGuest = data['guest'];
    if (nestedGuest is Map<String, dynamic>) {
      final guestToken = nestedGuest['token']?.toString() ?? '';
      if (guestToken.trim().isNotEmpty) return guestToken.trim();
    }

    return '';
  }

  String _extractGuestUUID(Map<String, dynamic> data) {
    final customer = data['customer'];
    if (customer is Map<String, dynamic>) {
      final uuid = customer['uuid']?.toString() ?? '';
      if (uuid.trim().isNotEmpty) return uuid.trim();
    }

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      final nestedCustomer = nestedData['customer'];
      if (nestedCustomer is Map<String, dynamic>) {
        final uuid = nestedCustomer['uuid']?.toString() ?? '';
        if (uuid.trim().isNotEmpty) return uuid.trim();
      }
    }

    return '';
  }
}
