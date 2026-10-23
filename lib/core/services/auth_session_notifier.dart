import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:flutter/foundation.dart';

class AuthSessionNotifier extends ChangeNotifier {
  AuthSessionNotifier({required SecureCacheHelper secureCacheHelper})
    : _secureCacheHelper = secureCacheHelper;

  final SecureCacheHelper _secureCacheHelper;

  bool _hasSession = false;
  bool _isGuestSession = false;

  bool get hasSession => _hasSession;
  bool get isGuestSession => _isGuestSession;
  bool get isLoggedIn => _hasSession && !_isGuestSession;

  Future<void> syncFromCache() async {
    final token = await _secureCacheHelper.getData(key: 'token');
    final loginMethod = await _secureCacheHelper.getData(key: 'authLoginMethod');
    final nextHasSession = token != null && token.trim().isNotEmpty;
    final nextIsGuest = (loginMethod ?? '').trim().toLowerCase() == 'guest';

    if (_hasSession == nextHasSession && _isGuestSession == nextIsGuest) {
      return;
    }

    _hasSession = nextHasSession;
    _isGuestSession = nextIsGuest;
    notifyListeners();
  }
}
