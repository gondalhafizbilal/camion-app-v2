import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigator {
  static CartBackTarget? _cartBackTarget;

  static void rememberCartBackTarget(BuildContext context) {
    try {
      final state = GoRouterState.of(context);
      _cartBackTarget = CartBackTarget(
        location: state.uri.toString(),
        extra: state.extra,
      );
    } catch (_) {
      _cartBackTarget = null;
    }
  }

  static CartBackTarget? consumeCartBackTarget() {
    final target = _cartBackTarget;
    _cartBackTarget = null;
    return target;
  }

  /// Pops the current route if possible, otherwise navigates to [fallbackRoute]
  /// (defaults to [AppRouter.selectingFromBottomNavBar]).
  static void safePop(BuildContext context, {String? fallbackRoute}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    GoRouterState? state;
    try {
      state = GoRouterState.of(context);
    } catch (_) {}

    final fromProfile = state?.uri.queryParameters['fromProfile'] == '1';
    if (fromProfile) {
      GoRouter.of(context).go('${AppRouter.selectingFromBottomNavBar}?tab=4');
      return;
    }

    final currentPath = state?.uri.toString() ?? '';
    if (_isCategoryFlowRoute(currentPath)) {
      GoRouter.of(context).go('${AppRouter.selectingFromBottomNavBar}?tab=1');
      return;
    }
    if (_isCartFlowRoute(currentPath)) {
      GoRouter.of(context).go('${AppRouter.selectingFromBottomNavBar}?tab=3');
      return;
    }
    if (_isWishListFlowRoute(currentPath)) {
      GoRouter.of(context).go('${AppRouter.selectingFromBottomNavBar}?tab=2');
      return;
    }
    if (_isProfileFlowRoute(currentPath)) {
      GoRouter.of(context).go('${AppRouter.selectingFromBottomNavBar}?tab=4');
      return;
    }
    final smartFallback =
        fallbackRoute ??
        (currentPath.startsWith(AppRouter.confirmPayment)
            ? AppRouter.selectingFromBottomNavBarCartTab
            : AppRouter.selectingFromBottomNavBar);
    GoRouter.of(context).go(smartFallback);
  }

  static bool _isCategoryFlowRoute(String path) {
    return path.startsWith(AppRouter.category) ||
        path.startsWith(AppRouter.categoriesTab) ||
        path.startsWith(AppRouter.productByCategory);
  }

  static bool _isProfileFlowRoute(String path) {
    return path.startsWith(AppRouter.profileScreen) ||
        path.startsWith(AppRouter.myInfo) ||
        path.startsWith(AppRouter.myAddresses) ||
        path.startsWith(AppRouter.myOrders) ||
        path.startsWith(AppRouter.settings) ||
        path.startsWith(AppRouter.changeLanuage) ||
        path.startsWith(AppRouter.changeCurrency) ||
        path.startsWith(AppRouter.accountSettings) ||
        path.startsWith(AppRouter.help) ||
        path.startsWith(AppRouter.chatbot) ||
        path.startsWith(AppRouter.feedBackScreen) ||
        path.startsWith(AppRouter.privacyScreen) ||
        path.startsWith(AppRouter.myWallet) ||
        path.startsWith(AppRouter.affiliateCheckScreen) ||
        path.startsWith(AppRouter.influencerCheckScreen) ||
        path.startsWith(AppRouter.walletAffiliateCheckScreen) ||
        path.startsWith(AppRouter.walletInfluencerCheckScreen);
  }

  static bool _isCartFlowRoute(String path) {
    return path.startsWith(AppRouter.myCart) ||
        path.startsWith(AppRouter.confirmPayment) ||
        path.startsWith(AppRouter.confirmAddress) ||
        path.startsWith(AppRouter.confirmShippingAddressScreen) ||
        path.startsWith(AppRouter.checkoutPaymentMethod) ||
        path.startsWith(AppRouter.addAddress) ||
        path.startsWith(AppRouter.orderOverview) ||
        path.startsWith(AppRouter.paymentWebPage) ||
        path.startsWith(AppRouter.orderTrackingWebPage);
  }

  static bool _isWishListFlowRoute(String path) {
    return path.startsWith(AppRouter.wishListTab);
  }

  static Future<void> openNotificationsOrLogin(BuildContext context) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (!context.mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      final next = Uri.encodeComponent(AppRouter.notificationScreen);
      await GoRouter.of(context).push('${AppRouter.login}?next=$next');
      return;
    }

    final currentPath = GoRouterState.of(context).uri.toString();
    if (currentPath != AppRouter.notificationScreen) {
      await GoRouter.of(context).push(AppRouter.notificationScreen);
    }
  }

  static Future<bool> isAuthenticatedCustomer() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final loginMethod = await sl<SecureCacheHelper>().getData(
      key: 'authLoginMethod',
    );
    final hasToken = token != null && token.trim().isNotEmpty;
    final isGuest = (loginMethod ?? '').trim().toLowerCase() == 'guest';
    return hasToken && !isGuest;
  }

  static Future<bool> ensureAuthenticatedCustomer(
    BuildContext context, {
    String? nextRoute,
    String toastMessage = 'Login to continue',
  }) async {
    final isAuthenticated = await isAuthenticatedCustomer();
    if (isAuthenticated) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    AppToast.show(msg: toastMessage, gravity: ToastGravity.TOP);
    final resolvedNext = nextRoute ?? GoRouterState.of(context).uri.toString();
    final encodedNext = Uri.encodeComponent(resolvedNext);
    await GoRouter.of(context).push('${AppRouter.login}?next=$encodedNext');
    return false;
  }
}

class CartBackTarget {
  const CartBackTarget({required this.location, this.extra});

  final String location;
  final Object? extra;
}
