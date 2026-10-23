import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/api_error_factory.dart';
import 'package:camion/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:camion/features/auth/data/models/customer_auth/customer_auth_payloads.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepository', () {
    test('login parses the email login session token', () async {
      final repository = AuthRepository(
        authRemoteDataSource: StubAuthRemoteDataSource(
          emailLoginResponse: _response(data: {'token': 'session-token'}),
        ),
      );

      final result = await repository.login(emailAddress: 'user@camion.app');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected a successful login response'),
        (session) => expect(session.token, 'session-token'),
      );
    });

    test('verify parses the customer auth response', () async {
      final repository = AuthRepository(
        authRemoteDataSource: StubAuthRemoteDataSource(
          verifyPhoneResponse: _response(
            data: {
              'token': 'access-token',
              'customer': {
                'uuid': 'customer-uuid',
                'fullName': 'Camion Customer',
                'emailAddress': 'customer@camion.app',
                'phoneNumber': '+974 12345678',
                'role': 'customer',
              },
            },
          ),
        ),
      );

      final result = await repository.verify(
        sessionToken: 'session-token',
        secret: '123456',
        usePhoneVerification: true,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected a successful verification response'),
        (response) {
          expect(response.token, 'access-token');
          expect(response.customer.uuid, 'customer-uuid');
          expect(response.customer.emailAddress, 'customer@camion.app');
        },
      );
    });

    test('register returns a safe message when server responds with 500', () async {
      final repository = AuthRepository(
        authRemoteDataSource: StubAuthRemoteDataSource(
          registerError: DioException(
            requestOptions: RequestOptions(path: '/v1/auth/customer/register'),
            response: Response(
              requestOptions: RequestOptions(
                path: '/v1/auth/customer/register',
              ),
              statusCode: 500,
              data: {'message': 'Internal Server Error'},
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      );

      final result = await repository.register(
        fullName: 'Camion Customer',
        emailAddress: 'customer@camion.app',
        countryCode: 'QA',
        phoneNumber: '12345678',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, ApiErrorFactory.maintenanceMessage),
        (_) => fail('Expected a safe error response'),
      );
    });

    test('verify returns a safe message when response payload changes', () async {
      final repository = AuthRepository(
        authRemoteDataSource: StubAuthRemoteDataSource(
          verifyEmailResponse: _response(data: {'unexpected': true}),
        ),
      );

      final result = await repository.verify(
        sessionToken: 'session-token',
        secret: '123456',
        usePhoneVerification: false,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, ApiErrorFactory.maintenanceMessage),
        (_) => fail('Expected a safe parsing fallback'),
      );
    });

    test('registerGuest extracts token and guest uuid from customer payload', () async {
      final repository = AuthRepository(
        authRemoteDataSource: StubAuthRemoteDataSource(
          registerGuestResponse: _response(
            data: {
              'token': 'guest-access-token',
              'customer': {'uuid': 'guest-uuid-123'},
            },
          ),
        ),
      );

      final result = await repository.registerGuest(
        deviceId: 'device-id',
        token: 'fcm-token',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected a successful guest registration response'),
        (guestSession) {
          expect(guestSession.token, 'guest-access-token');
          expect(guestSession.guestUUID, 'guest-uuid-123');
        },
      );
    });
  });
}

class StubAuthRemoteDataSource extends AuthRemoteDataSource {
  StubAuthRemoteDataSource({
    this.registerResponse,
    this.emailLoginResponse,
    this.phoneLoginResponse,
    this.verifyEmailResponse,
    this.verifyPhoneResponse,
    this.registerGuestResponse,
    this.registerError,
  }) : super(apiConsumer: _NoopApiConsumer());

  final Response<dynamic>? registerResponse;
  final Response<dynamic>? emailLoginResponse;
  final Response<dynamic>? phoneLoginResponse;
  final Response<dynamic>? verifyEmailResponse;
  final Response<dynamic>? verifyPhoneResponse;
  final Response<dynamic>? registerGuestResponse;
  final Object? registerError;

  @override
  Future<Response> registerCustomer({
    required RegisterCustomerPayload payload,
  }) async {
    if (registerError != null) {
      throw registerError!;
    }
    return registerResponse ?? _response(data: {});
  }

  @override
  Future<Response> loginWithEmail({
    required LoginWithEmailPayload payload,
  }) async {
    return emailLoginResponse ?? _response(data: {});
  }

  @override
  Future<Response> loginWithPhone({
    required LoginWithPhonePayload payload,
  }) async {
    return phoneLoginResponse ?? _response(data: {});
  }

  @override
  Future<Response> verifyEmail({
    required VerifyCustomerPayload payload,
  }) async {
    return verifyEmailResponse ?? _response(data: {});
  }

  @override
  Future<Response> verifyPhone({
    required VerifyCustomerPayload payload,
  }) async {
    return verifyPhoneResponse ?? _response(data: {});
  }

  @override
  Future<Response> registerGuest({
    required RegisterGuestPayload payload,
  }) async {
    return registerGuestResponse ?? _response(data: {});
  }
}

class _NoopApiConsumer implements ApiConsumer {
  @override
  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }
}

Response<dynamic> _response({required Map<String, dynamic> data}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/test'),
    data: data,
    statusCode: 200,
  );
}
