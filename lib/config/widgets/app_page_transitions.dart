import 'package:flutter/material.dart';

class AppFadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppFadeSlidePageTransitionsBuilder();

  static const _duration = Duration(milliseconds: 260);
  static const _reverseDuration = Duration(milliseconds: 220);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(0.015, 0.02),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => _reverseDuration;
}
