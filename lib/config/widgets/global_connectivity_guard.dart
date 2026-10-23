import 'dart:async';
import 'dart:io';

import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GlobalConnectivityGuard extends StatefulWidget {
  const GlobalConnectivityGuard({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalConnectivityGuard> createState() =>
      _GlobalConnectivityGuardState();
}

class _GlobalConnectivityGuardState extends State<GlobalConnectivityGuard> {
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _isOffline = false;
  bool _isBackendUnavailable = false;
  bool _isChecking = false;
  int _reloadTick = 0;

  @override
  void initState() {
    super.initState();
    _isBackendUnavailable =
        BackendUnavailableNotifier.isBackendUnavailable.value;
    BackendUnavailableNotifier.isBackendUnavailable.addListener(
      _onBackendUnavailableChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _evaluateConnectivity();
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      _,
    ) async {
      await _evaluateConnectivity();
    });
  }

  @override
  void dispose() {
    BackendUnavailableNotifier.isBackendUnavailable.removeListener(
      _onBackendUnavailableChanged,
    );
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _onBackendUnavailableChanged() {
    if (!mounted) return;
    setState(() {
      _isBackendUnavailable =
          BackendUnavailableNotifier.isBackendUnavailable.value;
    });
  }

  Future<void> _evaluateConnectivity() async {
    if (_isChecking) return;
    _isChecking = true;
    final hasInternet = await _hasInternetAccess();
    _isChecking = false;
    if (!mounted) return;

    if (hasInternet) {
      final shouldRefresh = _isOffline;
      if (_isOffline) {
        setState(() {
          _isOffline = false;
          _reloadTick++;
        });
      }
      if (shouldRefresh) {
        RouterGenerator.mainRouting.refresh();
      }
    } else {
      if (!_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  Future<bool> _hasInternetAccess() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasNetwork = _hasConnectedTransport(connectivityResult);
    if (!hasNetwork) return false;

    try {
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasConnectedTransport(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final shouldShowOverlay = _isOffline || _isBackendUnavailable;
    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(key: ValueKey<int>(_reloadTick), child: widget.child),
        if (shouldShowOverlay) ...[
          const Positioned.fill(child: _OfflineShimmerBackdrop()),
          Center(
            child: SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dialogWidth = constraints.maxWidth.clamp(260.0, 380.0);
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    elevation: 3,
                    shadowColor: AppColors.black20,
                    child: Container(
                      width: dialogWidth,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.softPink,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.wifi_off_rounded,
                                size: 40,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isOffline
                                ? (isArabic
                                      ? 'لا يوجد اتصال بالإنترنت'
                                      : 'No Internet Connection')
                                : 'Backend Not Responding',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: AppColors.deepDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isOffline
                                ? (isArabic
                                      ? 'يرجى التحقق من اتصال الإنترنت وإعادة المحاولة.'
                                      : 'Please check your internet and retry.')
                                : 'Backend is not responding. Please try again later.',
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: AppColors.midGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_isOffline) {
                                  await _evaluateConnectivity();
                                  return;
                                }
                                BackendUnavailableNotifier.hide();
                                RouterGenerator.mainRouting.refresh();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                S.of(context).retry,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfflineShimmerBackdrop extends StatelessWidget {
  const _OfflineShimmerBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.extraLightGray,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE7E7E7),
        highlightColor: const Color(0xFFF7F7F7),
        child: SafeArea(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: const [
              _SkeletonLine(height: 22, widthFactor: 0.45, radius: 8),
              SizedBox(height: 14),
              _SkeletonLine(height: 46, widthFactor: 1, radius: 12),
              SizedBox(height: 16),
              _SkeletonLine(height: 170, widthFactor: 1, radius: 16),
              SizedBox(height: 16),
              _SkeletonLine(height: 20, widthFactor: 0.35, radius: 8),
              SizedBox(height: 12),
              _SkeletonLine(height: 110, widthFactor: 1, radius: 14),
              SizedBox(height: 12),
              _SkeletonLine(height: 110, widthFactor: 1, radius: 14),
              SizedBox(height: 12),
              _SkeletonLine(height: 110, widthFactor: 1, radius: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.height,
    required this.widthFactor,
    this.radius = 10,
  });

  final double height;
  final double widthFactor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
