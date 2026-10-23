import 'package:camion/core/utils/app_images.dart';
import 'package:flutter/material.dart';

class AuthBackgroundScaffold extends StatelessWidget {
  const AuthBackgroundScaffold({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = false,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final bool resizeToAvoidBottomInset;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final backgroundArtHeight =
          (constraints.maxHeight * 0.42).clamp(
            240.0,
            420.0,
          );

          return ColoredBox(
            color: backgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.white)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: SizedBox(

                      child: const Image(
                        image: AssetImage(Assets.loginBack),
                        alignment: Alignment.bottomCenter,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
                SafeArea(child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}
