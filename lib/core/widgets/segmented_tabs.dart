import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.index,
    required this.onChanged,
    this.labels = const [AppStrings.upcoming, AppStrings.past],
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: context.motion(Motion.normal),
            curve: Motion.standard,
            alignment: index == 0
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md - 4),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: context.motion(Motion.fast),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: i == index ? AppColors.card : AppColors.primary,
                        ),
                        child: Text(labels[i]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
