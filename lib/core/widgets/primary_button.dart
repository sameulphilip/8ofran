import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.busy = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final bool busy;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null && !busy;
    final fg = foregroundColor ?? AppColors.card;
    final button = Pressable(
      onTap: active ? onPressed : null,
      child: AnimatedContainer(
        duration: context.motion(Motion.fast),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onPressed == null
              ? AppColors.disabled.withValues(alpha: 0.4)
              : backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AnimatedSwitcher(
          duration: context.motion(Motion.fast),
          child: busy
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: fg,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: onPressed == null
                        ? AppColors.card.withValues(alpha: 0.7)
                        : fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
