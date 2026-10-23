import 'package:camion/core/config/app_config.dart';

class EndPoints {
  static const String _orderTrackingApiVersion = String.fromEnvironment(
    'ORDER_TRACKING_API_VERSION',
    defaultValue: 'v1',
  );

  static String get baseUrl {
    return AppConfig.instance.baseUrl;
  }

  static String get chatbotBaseUrl {
    return AppConfig.instance.chatbotBaseUrl;
  }

  static String get customerRegister => '$baseUrl/v1/auth/customer/register';
  static String get customerLoginWithEmail =>
      '$baseUrl/v1/auth/customer/login/email-address';
  static String get customerLoginWithPhone =>
      '$baseUrl/v1/auth/customer/login/phone-number';
  static String get customerGoogleOauthLogin =>
      '$baseUrl/v1/auth/customer/oauth/google';
  static String get customerFacebookOauthLogin =>
      '$baseUrl/v1/auth/customer/oauth/facebook';
  static String get customerAppleOauthLogin =>
      '$baseUrl/v1/auth/customer/oauth/apple';
  static String get customerVerifyEmail =>
      '$baseUrl/v1/auth/customer/verify/email-address';
  static String get customerVerifyPhone =>
      '$baseUrl/v1/auth/customer/verify/phone-number';
  static String get customerLogout => '$baseUrl/v1/auth/customer/logout';
  static String get customerSelf => '$baseUrl/v1/auth/customer/self';
  static String get customerDeleteMe => '$baseUrl/v1/customers/me';
  static String get customerCancelDeletion =>
      '$baseUrl/v1/customers/me/cancel-deletion';
  static String get customerSelfEmail =>
      '$baseUrl/v1/auth/customer/self/email-address';
  static String get customerAddresses => '$baseUrl/v1/customer-addresses';
  static String orderByUuid(String orderUuid) =>
      '$baseUrl/v1/orders/$orderUuid';
  static String retryOrderPayment(String orderUuid) =>
      '$baseUrl/v1/orders/$orderUuid/retry-payment';
  static String orderTrackingByUuid(String orderUuid) =>
      '$baseUrl/$_orderTrackingApiVersion/orders/$orderUuid/tracking';
  static String get returnRequests => '$baseUrl/v1/return-requests';
  static String get guestRegister => '$baseUrl/v1/auth/guest/register';
  static String get graphql => '$baseUrl/graphql';

  static String get products => 'products';
  static String get stories => 'stories';
}
