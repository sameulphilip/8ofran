import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.step, this.total = 3});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'الخطوة $step من $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++) ...[
            AnimatedContainer(
              duration: context.motion(Motion.normal),
              curve: Motion.standard,
              width: i == step ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i < step
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : i == step
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            if (i != total) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
