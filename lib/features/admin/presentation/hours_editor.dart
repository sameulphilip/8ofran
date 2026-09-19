import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatters.dart';

class HoursEditor extends StatelessWidget {
  const HoursEditor({
    super.key,
    required this.firstHour,
    required this.lastHour,
    required this.slotMinutes,
    required this.onFirstHour,
    required this.onLastHour,
    required this.onSlotMinutes,
  });

  final int firstHour;
  final int lastHour;
  final int slotMinutes;
  final ValueChanged<int> onFirstHour;
  final ValueChanged<int> onLastHour;
  final ValueChanged<int> onSlotMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _HourDropdown(
                label: AppStrings.hoursFrom,
                value: firstHour,
                onChanged: onFirstHour,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HourDropdown(
                label: AppStrings.hoursTo,
                value: lastHour,
                onChanged: onLastHour,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.lastSlotHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: slotMinutes,
          decoration: const InputDecoration(labelText: AppStrings.slotLength),
          items: [
            for (final minutes in AppConstants.slotMinuteOptions)
              DropdownMenuItem(
                value: minutes,
                child: Text(AppStrings.minutesLabel(minutes)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onSlotMinutes(value);
          },
        ),
      ],
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final hour in AppConstants.hourOptions)
          DropdownMenuItem(
            value: hour,
            child: Text(DateFormatters.hourOfDay(hour)),
          ),
      ],
      onChanged: (hour) {
        if (hour != null) onChanged(hour);
      },
    );
  }
}
