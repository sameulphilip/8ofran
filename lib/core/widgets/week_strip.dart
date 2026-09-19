import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/date_formatters.dart';

class WeekStrip extends StatefulWidget {
  const WeekStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.isEnabled,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime date) isEnabled;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  late DateTime _month;
  late final PageController _pageController;

  static const _center = 24;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selected.year, widget.selected.month);
    _pageController = PageController(initialPage: _center);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _weekStartFor(int page) {
    final selected = DateTime(
      widget.selected.year,
      widget.selected.month,
      widget.selected.day,
    );
    final base = _saturdayStart(selected);
    return base.add(Duration(days: (page - _center) * 7));
  }

  DateTime _saturdayStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: (day.weekday + 1) % 7));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _monthButton(
              icon: Icons.chevron_right_rounded,
              onTap: () {
                setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                });
              },
            ),
            Expanded(
              child: Text(
                DateFormatters.monthYear(_month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _monthButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 78,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (_) => setState(() {}),
            itemBuilder: (context, page) {
              final start = _weekStartFor(page);
              return Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(child: _dayCell(start.add(Duration(days: i)))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _monthButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.primary50,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: AppSpacing.touch,
          height: AppSpacing.touch,
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime date) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final day = DateTime(date.year, date.month, date.day);
    final selected = DateTime(
      widget.selected.year,
      widget.selected.month,
      widget.selected.day,
    );
    final isSelected = day == selected;
    final isToday = day == todayDate;
    final enabled = widget.isEnabled(day);

    return Semantics(
      selected: isSelected,
      button: true,
      enabled: enabled,
      label: DateFormatters.longDate(day),
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onSelect(day);
                setState(() => _month = DateTime(day.year, day.month));
              }
            : null,
        child: Column(
          children: [
            Text(
              AppStrings.weekdays[(day.weekday + 1) % 7],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabled ? AppColors.text600 : AppColors.disabled,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: context.motion(Motion.fast),
              curve: Motion.standard,
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: !enabled
                      ? AppColors.disabled
                      : isSelected
                      ? AppColors.card
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
