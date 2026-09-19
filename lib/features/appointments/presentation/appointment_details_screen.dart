import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/url_actions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../booking/presentation/booking_nav.dart';
import '../../priests/data/priest_repository.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment.dart';

class AppointmentDetailsScreen extends ConsumerWidget {
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);
    final appointment = ref
        .watch(allAppointmentsProvider)
        .cast<Appointment?>()
        .firstWhere((a) => a!.id == appointmentId, orElse: () => null);
    if (appointment == null) {
      return Scaffold(
        body: Center(
          child: appointmentsAsync.isLoading
              ? const CircularProgressIndicator()
              : const Text(AppStrings.emptyUpcoming),
        ),
      );
    }
    final priest = ref
        .watch(priestRepositoryProvider)
        .byId(appointment.priestId);
    if (priest == null) {
      return Scaffold(
        body: Center(
          child: ref.watch(priestsStreamProvider).isLoading
              ? const CircularProgressIndicator()
              : const SizedBox.shrink(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.appointmentDetails),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          28,
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PriestAvatar(
                      name: priest.name,
                      seed: priest.id.hashCode,
                      size: 64,
                      heroTag: 'priest-${priest.id}-${appointment.id}',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        priest.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusBadge(status: appointment.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _row(
                  Icons.event_outlined,
                  DateFormatters.longDate(appointment.startsAt),
                ),
                const SizedBox(height: AppSpacing.sm),
                _row(
                  Icons.schedule_outlined,
                  DateFormatters.time(appointment.startsAt),
                ),
                const SizedBox(height: AppSpacing.sm),
                _row(Icons.location_on_outlined, priest.churchName),
                TextButton.icon(
                  onPressed: UrlActions.openMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(AppStrings.openMaps),
                ),
              ],
            ),
          ).enter(context),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.notes,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            appointment.notes.isEmpty
                ? AppStrings.appointmentNote
                : appointment.notes,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          if (appointment.isActive) ...[
            const SizedBox(height: AppSpacing.xxl),
            TonalButton(
              label: AppStrings.addToCalendar,
              icon: Icons.calendar_month_outlined,
              onPressed: () => UrlActions.addToCalendar(
                startsAt: appointment.startsAt,
                priestName: priest.name,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TonalButton(
              label: AppStrings.rescheduleAppointment,
              onPressed: () =>
                  openMemberBooking(context, ref, rescheduleId: appointment.id),
            ),
            const SizedBox(height: AppSpacing.sm),
            TonalButton(
              danger: true,
              label: AppStrings.cancelAppointment,
              onPressed: () => _cancel(context, ref, appointment, priest.name),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary600, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
    String priestName,
  ) async {
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
      if (context.mounted) goBack(context);
    } on CancelWindowException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.cancelTooLate)));
      }
    }
  }
}
