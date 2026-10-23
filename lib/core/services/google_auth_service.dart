import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthFlowException implements Exception {
  const GoogleAuthFlowException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  /// Optional: call this if you want to force account picker every time.
  /// In most apps keep it false to avoid annoying users.
  final bool forceAccountPicker;

  GoogleAuthService({this.forceAccountPicker = false});

  String _requiredEnv(String key) {
    final value = dotenv.env[key]?.trim() ?? '';
    if (value.isEmpty) {
      throw StateError('Missing required env key: $key');
    }
    return value;
  }

  // Android clientId is not required by google_sign_in on Android.
  // Keep it as env-driven config for diagnostics/debug screens.
  String get androidClientId => _requiredEnv('GOOGLE_ANDROID_CLIENT_ID');

  String get _serverClientId => _requiredEnv('GOOGLE_WEB_CLIENT_ID');

  String get _iosClientId => _requiredEnv('GOOGLE_IOS_CLIENT_ID');

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _googleSignIn.initialize(
      // Android ignores clientId; package/bundle + signing cert identify the app.
      // iOS requires clientId. serverClientId is used for ID token audience.
      clientId: Platform.isIOS ? _iosClientId : null,
      serverClientId: _serverClientId,
    );

    _initialized = true;
  }

  /// Returns ID token to send to backend for verification/login.
  Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();

    // Optional: force picker (useful during debugging / to avoid stale sessions)
    if (forceAccountPicker) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // ignore
      }
    }

    late final GoogleSignInAccount account;

    try {
      // You can pass scopes if needed, but for idToken + basic profile, defaults are fine.
      account = await _googleSignIn.authenticate();
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleAuthService] authenticate() threw: $e');
      }
      final raw = e.toString().toLowerCase();
      if (raw.contains('no credential available') ||
          raw.contains('no credentials available')) {
        throw const GoogleAuthFlowException(
          'No Google account is available on this device/emulator. Add a Google account in Android Settings and try again.',
        );
      }
      rethrow;
    }

    final auth = account.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google sign-in did not return an ID token');
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }

  /// Stronger than signOut: also revokes the previous consent.
  /// Use if user wants "remove this account from the app".
  Future<void> disconnect() async {
    if (!_initialized) return;
    await _googleSignIn.disconnect();
  }
}
