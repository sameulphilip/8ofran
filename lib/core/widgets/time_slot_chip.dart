import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

class TimeSlotChip extends StatelessWidget {
  const TimeSlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.taken = false,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = !enabled || taken
        ? AppColors.slotTaken
        : selected
        ? AppColors.primary
        : AppColors.surface;
    final fg = !enabled || taken
        ? AppColors.text500
        : selected
        ? AppColors.card
        : AppColors.textPrimary;

    return Pressable(
      haptic: true,
      onTap: enabled && !taken ? onTap : null,
      child: Semantics(
        selected: selected,
        label: taken ? '$label، محجوز' : label,
        child: AnimatedContainer(
          duration: context.motion(Motion.fast),
          curve: Motion.standard,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: context.motion(Motion.fast),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              decoration: taken ? TextDecoration.lineThrough : null,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
