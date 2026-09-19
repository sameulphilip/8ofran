import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/booking_stepper.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/time_slot_chip.dart';
import '../../../core/widgets/week_strip.dart';
import '../../appointments/data/appointment_repository.dart';
import 'booking_controller.dart';

class SelectSlotScreen extends ConsumerStatefulWidget {
  const SelectSlotScreen({super.key});

  @override
  ConsumerState<SelectSlotScreen> createState() => _SelectSlotScreenState();
}

class _SelectSlotScreenState extends ConsumerState<SelectSlotScreen> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nearest = _nearestDay();
      if (nearest != null && mounted) setState(() => _selected = nearest);
    });
  }

  DateTime? _nearestDay() {
    final draft = ref.read(bookingControllerProvider);
    final priest = draft.priest;
    if (priest == null) return null;
    final repo = ref.read(appointmentRepositoryProvider);
    final items = ref.read(allAppointmentsProvider);
    for (var i = 0; i < 60; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final day = DateTime(date.year, date.month, date.day);
      if (!priest.worksOn(day)) continue;
      final open = repo.availableSlots(
        priestId: priest.id,
        date: day,
        ignoreAppointmentId: draft.rescheduleId,
        items: items,
      );
      if (open.isNotEmpty) return day;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingControllerProvider);
    final priest = draft.priest;
    if (priest == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final booked = ref.watch(allAppointmentsProvider);
    final slots = priest.worksOn(_selected)
        ? ref
              .watch(appointmentRepositoryProvider)
              .daySlots(
                priestId: priest.id,
                date: _selected,
                ignoreAppointmentId: draft.rescheduleId,
                items: booked,
              )
        : const [];
    final hasOpen = slots.any((slot) => slot.selectable);
    final nearest = !hasOpen ? _nearestDay() : null;
    final nextLabel = draft.startsAt == null
        ? AppStrings.next
        : '${DateFormatters.longDate(draft.startsAt!)} · ${DateFormatters.time(draft.startsAt!)}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.selectSlot),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: BookingStepper(step: 2),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              children: [
                Row(
                  children: [
                    PriestAvatar(
                      name: priest.name,
                      seed: priest.id.hashCode,
                      size: 64,
                      heroTag: 'priest-${priest.id}',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        priest.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                WeekStrip(
                  selected: _selected,
                  onSelect: (date) {
                    setState(() => _selected = date);
                    ref.read(bookingControllerProvider.notifier).clearSlot();
                  },
                  isEnabled: (date) {
                    final today = DateTime.now();
                    final todayDate = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );
                    return !date.isBefore(todayDate) && priest.worksOn(date);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppStrings.availableSlots,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!hasOpen) ...[
                  Text(
                    AppStrings.noSlots,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (nearest != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TonalButton(
                      label:
                          '${AppStrings.nearestAvailable}: ${DateFormatters.longDate(nearest)}',
                      onPressed: () => setState(() => _selected = nearest),
                    ),
                  ],
                ] else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: slots.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisExtent: 48,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      return TimeSlotChip(
                        label: DateFormatters.time(slot.time),
                        selected: draft.startsAt == slot.time,
                        enabled: !slot.past,
                        taken: slot.taken,
                        onTap: () => ref
                            .read(bookingControllerProvider.notifier)
                            .selectSlot(slot.time),
                      );
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: PrimaryButton(
                label: nextLabel,
                onPressed: draft.startsAt == null
                    ? null
                    : () => context.push('/booking/confirm'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
