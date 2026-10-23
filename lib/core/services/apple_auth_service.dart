import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthResult {
  final String identityToken;
  final String? authorizationCode;
  final String? fullName;

  AppleAuthResult({
    required this.identityToken,
    this.authorizationCode,
    this.fullName,
  });
}

class AppleAuthService {
  /// Returns Apple auth payload to be sent to backend.
  Future<AppleAuthResult?> signInAndGetAuthPayload() async {
    final available = await SignInWithApple.isAvailable();
    if (!available) return null;

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      return null;
    }

    final givenName = credential.givenName?.trim();
    final familyName = credential.familyName?.trim();
    final nameParts = [
      givenName,
      familyName,
    ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();
    final fullName = nameParts.isEmpty ? null : nameParts.join(' ');

    final authorizationCode = credential.authorizationCode.isEmpty
        ? null
        : credential.authorizationCode;

    return AppleAuthResult(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      fullName: fullName,
    );
  }
}
