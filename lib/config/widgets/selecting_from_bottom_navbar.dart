import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/config/widgets/bottom_nav_bar.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SelectingFromBottomNavBar extends StatefulWidget {
  const SelectingFromBottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<SelectingFromBottomNavBar> createState() =>
      _SelectingFromBottomNavBarState();
}

class _SelectingFromBottomNavBarState extends State<SelectingFromBottomNavBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sl<DashboardBadgeCountsNotifier>().refresh();
      if (widget.navigationShell.currentIndex == 3) {
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          CartRefreshNotifier.requestRefresh();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final currentPath = GoRouterState.of(context).uri.path;
    final shouldInterceptCartRootBack =
        currentIndex == 3 && currentPath == AppRouter.myCart;
    return PopScope(
      canPop: !shouldInterceptCartRootBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !shouldInterceptCartRootBack) {
          return;
        }
        widget.navigationShell.goBranch(0);
        sl<DashboardBadgeCountsNotifier>().refresh();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(child: widget.navigationShell),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: sl<DashboardBadgeCountsNotifier>(),
                builder: (context, _) => CustomBottomNavBar(
                  currentIndex: currentIndex,
                  wishlistCount:
                      sl<DashboardBadgeCountsNotifier>().wishlistCount,
                  cartCount: sl<DashboardBadgeCountsNotifier>().cartCount,
                  onTap: (index) {
                    if (index == 0) {
                      sl<DashboardBadgeCountsNotifier>().refresh();
                    }
                    if (index == 0 && currentIndex == 0) {
                      HomeScreen.homeKey.currentState?.scrollToTopAndRefresh();
                    } else {
                      widget.navigationShell.goBranch(
                        index,
                        initialLocation: index == currentIndex,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
