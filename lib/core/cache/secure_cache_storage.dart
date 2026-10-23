import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCacheHelper {
  static const AndroidOptions _androidOptions = AndroidOptions(
    resetOnError: true,
  );
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
  );
  static const String _androidResetOnErrorMessage = 'Data has been reset';
  static const String _authRuntimeEnvironmentMarkerKey =
      'authRuntimeEnvironmentMarkerV1';

  //! Save data securely
  Future<void> saveData({
    required String key,
    required String value, // flutter_secure_storage بيخزن Strings بس
  }) async {
    await _secureStorage.write(key: key, value: value);
    await _saveAuthRuntimeMarkerIfNeeded(key, value);
    await _notifyIfAuthTokenChanged(key);
  }

  //! Get data securely
  Future<String?> getData({required String key}) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value == _androidResetOnErrorMessage) {
        return null;
      }
      return value;
    } on PlatformException catch (error) {
      if (!_isRecoverableSecureStorageReadError(error)) rethrow;
      await _resetUnreadableSecureStorage();
      return null;
    }
  }

  //! Remove specific key
  Future<void> removeData({required String key}) async {
    await _secureStorage.delete(key: key);
    await _removeAuthRuntimeMarkerIfNeeded(key);
    await _notifyIfAuthTokenChanged(key);
  }

  //! Check if key exists
  Future<bool> containsKey({required String key}) async {
    return (await getData(key: key)) != null;
  }

  //! Clear all secure data
  Future<void> clearData() async {
    await _secureStorage.deleteAll();
    await _notifyAuthSession();
  }

  //! Write any dynamic value by converting it to string
  Future<void> put({required String key, required dynamic value}) async {
    final stringValue = value.toString();
    await _secureStorage.write(key: key, value: stringValue);
    await _saveAuthRuntimeMarkerIfNeeded(key, stringValue);
    await _notifyIfAuthTokenChanged(key);
  }

  //! Read and parse as needed
  Future<int?> getInt(String key) async {
    final value = await getData(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  Future<bool?> getBool(String key) async {
    final value = await getData(key: key);
    return value == 'true'
        ? true
        : value == 'false'
        ? false
        : null;
  }

  Future<double?> getDouble(String key) async {
    final value = await getData(key: key);
    return value != null ? double.tryParse(value) : null;
  }

  Future<void> _notifyIfAuthTokenChanged(String key) async {
    if (key != 'token' && key != 'authLoginMethod') return;
    await _notifyAuthSession();
  }

  Future<void> _saveAuthRuntimeMarkerIfNeeded(String key, String value) async {
    if (key != 'token' && key != 'authSessionToken') return;
    if (value.trim().isEmpty) return;
    final marker = _currentRuntimeMarker();
    if (marker.isEmpty) return;
    await _secureStorage.write(
      key: _authRuntimeEnvironmentMarkerKey,
      value: marker,
    );
  }

  Future<void> _removeAuthRuntimeMarkerIfNeeded(String key) async {
    if (key != 'token') return;
    await _secureStorage.delete(key: _authRuntimeEnvironmentMarkerKey);
  }

  String _currentRuntimeMarker() {
    try {
      return AppConfig.instance.runtimeEnvironmentMarker;
    } catch (_) {
      return '';
    }
  }

  Future<void> _notifyAuthSession() async {
    if (!sl.isRegistered<AuthSessionNotifier>()) return;
    await sl<AuthSessionNotifier>().syncFromCache();
  }

  bool _isRecoverableSecureStorageReadError(PlatformException error) {
    final text = '${error.code} ${error.message} ${error.details}'
        .toLowerCase();
    return text.contains('badpaddingexception') ||
        text.contains('bad_decrypt') ||
        text.contains('illegalblocksizeexception') ||
        text.contains('aeadbadtagexception') ||
        text.contains('invalidkeyexception') ||
        text.contains('failed to unwrap key');
  }

  Future<void> _resetUnreadableSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {
      // If Android cannot decrypt restored values, startup should still recover.
    }
  }
}
