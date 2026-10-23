import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter/foundation.dart';

class DashboardBadgeCountsNotifier extends ChangeNotifier {
  DashboardBadgeCountsNotifier({
    required HomeRepository homeRepository,
    required SecureCacheHelper secureCacheHelper,
    required AuthSessionNotifier authSessionNotifier,
  }) : _homeRepository = homeRepository,
       _secureCacheHelper = secureCacheHelper,
       _authSessionNotifier = authSessionNotifier {
    _authSessionNotifier.addListener(_handleAuthStateChanged);
  }

  final HomeRepository _homeRepository;
  final SecureCacheHelper _secureCacheHelper;
  final AuthSessionNotifier _authSessionNotifier;

  int _cartCount = 0;
  int _wishlistCount = 0;
  int _notificationCount = 0;
  bool _isRefreshing = false;

  int get cartCount => _cartCount;
  int get wishlistCount => _wishlistCount;
  int get notificationCount => _notificationCount;
  bool get isRefreshing => _isRefreshing;

  void _handleAuthStateChanged() {
    if (!_authSessionNotifier.hasSession) {
      if (_cartCount != 0 || _wishlistCount != 0 || _notificationCount != 0) {
        _cartCount = 0;
        _wishlistCount = 0;
        _notificationCount = 0;
        notifyListeners();
      }
      return;
    }
    refresh();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      if (!_authSessionNotifier.hasSession) {
        if (_cartCount != 0 || _wishlistCount != 0 || _notificationCount != 0) {
          _cartCount = 0;
          _wishlistCount = 0;
          _notificationCount = 0;
          notifyListeners();
        }
        return;
      }

      final token = await _secureCacheHelper.getData(key: 'token');
      if (token == null || token.trim().isEmpty) {
        if (_cartCount != 0 || _wishlistCount != 0 || _notificationCount != 0) {
          _cartCount = 0;
          _wishlistCount = 0;
          _notificationCount = 0;
          notifyListeners();
        }
        return;
      }

      final previousCart = _cartCount;
      final previousWishlist = _wishlistCount;
      final previousNotification = _notificationCount;

      final countsResult = await _homeRepository.getDashboardCountsGraphql(
        token: token,
      );
      final customerResult = await _homeRepository.getCurrentCustomerGraphql(
        token: token,
      );
      countsResult.fold((_) {}, (counts) {
        _cartCount = counts.cartCount;
        _wishlistCount = counts.wishlistCount;
      });
      customerResult.fold((_) {}, (customer) {
        _notificationCount = customer.unreadNotificationCount;
      });
      final changed =
          _cartCount != previousCart ||
          _wishlistCount != previousWishlist ||
          _notificationCount != previousNotification;
      if (changed) {
        notifyListeners();
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
