import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../motion/motion.dart';

CustomTransitionPage<T> sharedAxisPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.normal,
    reverseTransitionDuration: Motion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (context.reduceMotion) return child;
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final begin = Offset(isRtl ? -0.08 : 0.08, 0);
      final slide = Tween(
        begin: begin,
        end: Offset.zero,
      ).chain(CurveTween(curve: Motion.enter));
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: animation.drive(slide), child: child),
      );
    },
  );
}
