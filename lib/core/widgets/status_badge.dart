import 'package:flutter/material.dart';

import '../../features/appointments/domain/appointment.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg, icon) = switch (status) {
      AppointmentStatus.confirmed => (
        AppStrings.confirmed,
        AppColors.success700,
        AppColors.success100,
        Icons.check_circle_outline_rounded,
      ),
      AppointmentStatus.pending => (
        AppStrings.pending,
        AppColors.warning700,
        AppColors.warning100,
        Icons.hourglass_bottom_rounded,
      ),
      AppointmentStatus.cancelled => (
        AppStrings.cancelled,
        AppColors.danger700,
        AppColors.danger100,
        Icons.close_rounded,
      ),
      AppointmentStatus.completed => (
        AppStrings.completed,
        AppColors.primary,
        AppColors.primary100,
        Icons.done_all_rounded,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
