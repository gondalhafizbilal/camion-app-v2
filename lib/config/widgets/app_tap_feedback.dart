import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTapFeedback extends StatefulWidget {
  const AppTapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.customBorder,
    this.padding,
    this.alignment,
    this.pressedOpacity = 0.94,
    this.pressedScale = 0.975,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double pressedOpacity;
  final double pressedScale;
  final bool enableHaptics;

  @override
  State<AppTapFeedback> createState() => _AppTapFeedbackState();
}

class _AppTapFeedbackState extends State<AppTapFeedback> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = widget.borderRadius ?? BorderRadius.circular(12);
    final isInteractive = widget.onTap != null || widget.onLongPress != null;
    final theme = Theme.of(context);
    Widget content = widget.child;
    if (widget.alignment != null) {
      content = Align(alignment: widget.alignment!, child: content);
    }
    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: (value) {
          if (_isPressed == value) {
            return;
          }
          setState(() {
            _isPressed = value;
          });
        },
        borderRadius: widget.customBorder == null ? resolvedRadius : null,
        customBorder: widget.customBorder,
        splashFactory: theme.splashFactory,
        splashColor: theme.splashColor,
        highlightColor: theme.highlightColor,
        hoverColor: theme.hoverColor,
        child: AnimatedScale(
          scale: _isPressed && isInteractive ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isPressed && isInteractive ? widget.pressedOpacity : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: content,
          ),
        ),
      ),
    );
  }
}
