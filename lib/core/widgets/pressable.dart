import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/motion.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.haptic = false,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool haptic;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled
            ? (_) {
                _set(false);
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap?.call();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed && enabled && !context.reduceMotion
              ? widget.pressedScale
              : 1,
          duration: Motion.instant,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
