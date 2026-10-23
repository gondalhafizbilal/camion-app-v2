class CustomerModel {
  const CustomerModel({
    required this.uuid,
    required this.fullName,
    required this.emailAddress,
    required this.phoneNumber,
    required this.role,
  });

  final String uuid;
  final String fullName;
  final String emailAddress;
  final String phoneNumber;
  final String role;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      uuid: (json['uuid'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      emailAddress: (json['emailAddress'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'fullName': fullName,
      'emailAddress': emailAddress,
      'phoneNumber': phoneNumber,
      'role': role,
    };
  }
}
