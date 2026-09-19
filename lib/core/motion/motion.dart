import 'package:flutter/material.dart';

abstract class Motion {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const hero = Duration(milliseconds: 600);
  static const stagger = Duration(milliseconds: 60);

  static const standard = Curves.easeInOutCubicEmphasized;
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const celebrate = Curves.elasticOut;
}

extension MotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  Duration motion(Duration duration) =>
      reduceMotion ? Duration.zero : duration;
}
