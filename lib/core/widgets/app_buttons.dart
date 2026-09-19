import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _ToneButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      background: AppColors.surface,
      foreground: AppColors.primary,
      border: AppColors.border,
    );
  }
}

class TonalButton extends StatelessWidget {
  const TonalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _ToneButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      background: danger ? AppColors.danger100 : AppColors.primary50,
      foreground: danger ? AppColors.danger700 : AppColors.primary600,
      border: danger ? const Color(0xFFF6C9C9) : AppColors.primary100,
    );
  }
}

class _ToneButton extends StatelessWidget {
  const _ToneButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.border,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: context.motion(Motion.fast),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
