import '../../../core/constants/app_strings.dart';
import '../../appointments/domain/appointment.dart';
import '../../notifications/data/notification_repository.dart';
import '../domain/pastoral_care.dart';

class ReminderDispatcher {
  ReminderDispatcher(this._notifications);

  final NotificationRepository _notifications;

  Future<void> sync({
    required String userId,
    required List<Appointment> appointments,
    PastoralCare? care,
    required bool enabled,
  }) async {
    if (!enabled) return;
    final now = DateTime.now();
    for (final appointment in appointments) {
      if (appointment.userId != userId ||
          appointment.status != AppointmentStatus.confirmed ||
          !appointment.remind ||
          !appointment.isUpcoming) {
        continue;
      }
      await _maybeRemind(
        appointment: appointment,
        now: now,
        days: 2,
        title: AppStrings.reminderTwoDaysTitle,
      );
      await _maybeRemind(
        appointment: appointment,
        now: now,
        days: 1,
        title: AppStrings.reminderOneDayTitle,
      );
    }

    if (care == null) return;
    final last = lastVisitFor(
      userId: userId,
      priestId: care.priestId,
      appointments: appointments,
      now: now,
    );
    if (!care.isOverdue(now, last)) return;
    final stamp = DateTime(now.year, now.month, now.day).toIso8601String();
    await _notifications.upsert(
      id: 'cadence_${userId}_$stamp',
      userId: userId,
      title: AppStrings.cadenceReminderTitle,
      body: AppStrings.cadenceReminderBody,
    );
  }

  Future<void> _maybeRemind({
    required Appointment appointment,
    required DateTime now,
    required int days,
    required String title,
  }) async {
    final window = appointment.startsAt.subtract(Duration(days: days));
    if (now.isBefore(window) || !now.isBefore(appointment.startsAt)) return;
    await _notifications.upsert(
      id: 'r${days}_${appointment.id}',
      userId: appointment.userId,
      title: title,
      body: AppStrings.reminderAppointmentBody,
    );
  }
}
