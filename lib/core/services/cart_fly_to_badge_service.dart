import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CartFlyToBadgeService {
  CartFlyToBadgeService._();

  static Future<void> animate({
    required BuildContext context,
    required Rect fromRect,
    required Rect toRect,
    Duration duration = const Duration(milliseconds: 920),
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);

    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CartFlyOverlay(
        fromRect: fromRect,
        toRect: toRect,
        duration: duration,
        onCompleted: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    await completer.future;
  }

  static Offset _quadraticBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    double t,
  ) {
    final u = 1 - t;
    return Offset(
      (u * u * p0.dx) + (2 * u * t * p1.dx) + (t * t * p2.dx),
      (u * u * p0.dy) + (2 * u * t * p1.dy) + (t * t * p2.dy),
    );
  }
}

class _CartFlyOverlay extends StatefulWidget {
  const _CartFlyOverlay({
    required this.fromRect,
    required this.toRect,
    required this.duration,
    required this.onCompleted,
  });

  final Rect fromRect;
  final Rect toRect;
  final Duration duration;
  final VoidCallback onCompleted;

  @override
  State<_CartFlyOverlay> createState() => _CartFlyOverlayState();
}

class _CartFlyOverlayState extends State<_CartFlyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startCenter = widget.fromRect.center;
    final endCenter = widget.toRect.center;
    final controlPoint = Offset(
      (startCenter.dx + endCenter.dx) / 2,
      math.min(startCenter.dy, endCenter.dy) - 180,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final t = _animation.value;
            final position = CartFlyToBadgeService._quadraticBezier(
              startCenter,
              controlPoint,
              endCenter,
              t,
            );
            final scale = t < 0.68
                ? ui.lerpDouble(1.08, 0.82, t / 0.68)!
                : ui.lerpDouble(0.82, 0.16, (t - 0.68) / 0.32)!;
            final rotate = ui.lerpDouble(0.12, -0.08, t)!;
            final opacity = t < 0.12
                ? t / 0.12
                : t > 0.88
                ? (1 - t) / 0.12
                : 1.0;

            return Stack(
              children: [
                Positioned(
                  left: position.dx - 18,
                  top: position.dy - 18,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: rotate,
                      child: Transform.scale(
                        scale: scale.clamp(0.0, 1.0),
child: _FlyingPaperParcel(progress: t),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FlyingPaperParcel extends StatelessWidget {
  const _FlyingPaperParcel({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final shadowOpacity = (1 - progress).clamp(0.2, 0.7);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDA3B3B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity * 0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: Center(
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 16,
                color: Color(0xFFDA3B3B),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0x22DA3B3B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
