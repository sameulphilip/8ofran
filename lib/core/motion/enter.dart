import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'motion.dart';

extension EnterAnimation on Widget {
  Widget enter(BuildContext context, {int index = 0}) {
    if (context.reduceMotion) return this;
    final i = index.clamp(0, 8);
    return animate(delay: (Motion.stagger.inMilliseconds * i).ms)
        .fadeIn(duration: Motion.normal, curve: Motion.enter)
        .slideY(begin: 0.06, end: 0, duration: Motion.normal, curve: Motion.enter);
  }
}
