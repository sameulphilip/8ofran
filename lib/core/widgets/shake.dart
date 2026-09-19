import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';

class Shake extends StatelessWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (trigger == 0 || context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      builder: (_, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}
