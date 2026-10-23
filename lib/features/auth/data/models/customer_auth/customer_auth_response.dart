import 'package:camion/features/auth/data/models/customer_auth/customer_model.dart';

class CustomerAuthResponse {
  const CustomerAuthResponse({required this.token, required this.customer});

  final String token;
  final CustomerModel customer;

  factory CustomerAuthResponse.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'];
    if (customerJson is! Map<String, dynamic>) {
      throw const FormatException('Missing customer payload');
    }

    return CustomerAuthResponse(
      token: (json['token'] ?? '').toString(),
      customer: CustomerModel.fromJson(customerJson),
    );
  }
}
