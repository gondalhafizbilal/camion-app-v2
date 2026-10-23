class AuthSessionTokenModel {
  const AuthSessionTokenModel({required this.token});

  final String token;

  factory AuthSessionTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionTokenModel(token: (json['token'] ?? '').toString());
  }
}
