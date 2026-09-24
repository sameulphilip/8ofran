import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/status_badge.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../booking/presentation/booking_nav.dart';
import '../../priests/data/priest_repository.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    final items = ref.watch(userAppointmentsProvider);
    final upcoming = items.where((a) => a.isUpcoming).toList();
    final past = items.where((a) => !a.isUpcoming).toList().reversed.toList();
    final visible = _tab == 0 ? upcoming : past;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.myAppointments),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: SegmentedTabs(
              index: _tab,
              onChanged: (index) => setState(() => _tab = index),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: EmptyState(
                      title: _tab == 0
                          ? AppStrings.emptyUpcoming
                          : AppStrings.emptyPast,
                      body: AppStrings.bookFromHomeHint,
                      actionLabel: _tab == 0
                          ? AppStrings.bookNewAppointment
                          : null,
                      onAction: _tab == 0
                          ? () => openMemberBooking(context, ref)
                          : null,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardGap),
                    itemBuilder: (context, index) {
                      final appointment = visible[index];
                      final priest = ref
                          .watch(priestRepositoryProvider)
                          .byId(appointment.priestId);
                      if (priest == null) return const SizedBox.shrink();
                      return AppCard(
                        key: ValueKey(appointment.id),
                        onTap: () =>
                            context.push('/appointment/${appointment.id}'),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                PriestAvatar(
                                  name: priest.name,
                                  seed: priest.id.hashCode,
                                  heroTag:
                                      'priest-${priest.id}-${appointment.id}',
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    priest.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: appointment.status),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_outlined,
                                  size: 16,
                                  color: AppColors.primary600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormatters.longDate(appointment.startsAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: AppColors.primary600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormatters.time(appointment.startsAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (_tab == 0 && appointment.isActive) ...[
                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: TonalButton(
                                      label: AppStrings.reschedule,
                                      onPressed: () => openMemberBooking(
                                        context,
                                        ref,
                                        rescheduleId: appointment.id,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TonalButton(
                                      danger: true,
                                      label: AppStrings.cancelAppointment,
                                      onPressed: () =>
                                          _cancel(appointment, priest.name),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ).enter(context, index: index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(Appointment appointment, String priestName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cancelConfirmTitle),
        content: Text(
          AppStrings.cancelBodyFor(
            priestName,
            DateFormatters.longDate(appointment.startsAt),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.keepAppointment),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger700),
            child: const Text(AppStrings.yesCancel),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(appointmentRepositoryProvider).cancel(appointment.id);
      ref.invalidate(appointmentsStreamProvider);
      ref.invalidate(userNotificationsProvider);
    } on CancelWindowException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.cancelTooLate)));
      }
    }
  }
}
