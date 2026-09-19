import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class OffDaysPicker extends StatelessWidget {
  const OffDaysPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final day in AppConstants.weekdaysSatToFri)
          FilterChip(
            label: Text(AppStrings.weekdayName(day)),
            selected: selected.contains(day),
            onSelected: (on) {
              final next = {...selected};
              if (on) {
                next.add(day);
              } else {
                next.remove(day);
              }
              onChanged(next);
            },
            selectedColor: AppColors.gold100,
            checkmarkColor: AppColors.gold700,
            labelStyle: TextStyle(
              color: selected.contains(day)
                  ? AppColors.gold700
                  : AppColors.text600,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: selected.contains(day)
                    ? AppColors.gold500
                    : AppColors.border,
              ),
            ),
          ),
      ],
    );
  }
}
