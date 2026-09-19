import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (context.reduceMotion) return box;
    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.55),
        );
  }
}
