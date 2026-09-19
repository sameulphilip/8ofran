import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_database.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../care/data/care_repository.dart';
import '../../care/data/reminder_dispatcher.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
import '../../priests/domain/priest.dart';
import '../domain/booking_draft.dart';

class BookingController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void start({Priest? priest, String? rescheduleId}) {
    state = BookingDraft(priest: priest, rescheduleId: rescheduleId);
  }

  void selectPriest(Priest priest) {
    state = state.copyWith(priest: priest);
  }

  void selectSlot(DateTime startsAt) {
    state = state.copyWith(startsAt: startsAt);
  }

  void clearSlot() {
    state = BookingDraft(
      priest: state.priest,
      rescheduleId: state.rescheduleId,
    );
  }

  Future<Appointment> confirm({String notes = ''}) async {
    final user = ref.read(authControllerProvider);
    final draft = state;
    if (user == null || !draft.canConfirm) {
      throw StateError('incomplete booking');
    }
    if (user.hasFather && draft.priest!.id != user.fatherId) {
      throw StateError('wrong father');
    }
    final appointment = await ref
        .read(appointmentRepositoryProvider)
        .book(
          userId: user.id,
          priestId: draft.priest!.id,
          startsAt: draft.startsAt!,
          notes: notes,
          rescheduleId: draft.rescheduleId,
          priestUid: draft.priest!.uid,
        );
    await ref
        .read(careRepositoryProvider)
        .ensureLink(
          userId: user.id,
          priestId: draft.priest!.id,
          priestUid: draft.priest!.uid,
        );
    ref.invalidate(appointmentsStreamProvider);
    ref.invalidate(userNotificationsProvider);
    return appointment;
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingDraft>(BookingController.new);

final appointmentsStreamProvider = StreamProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchAll();
});

final allAppointmentsProvider = Provider<List<Appointment>>((ref) {
  return ref.watch(appointmentsStreamProvider).value ?? const [];
});

final userAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return [];
  return [
    for (final item in ref.watch(allAppointmentsProvider))
      if (item.userId == user.id) item,
  ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
});

final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationRepositoryProvider).watchForUser(user.id);
});

final unreadCountProvider = Provider<int>((ref) {
  final items =
      ref.watch(userNotificationsProvider).value ?? const <AppNotification>[];
  return items.where((item) => !item.read).length;
});

final reminderSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null || user.isPriest) return;
  final db = ref.watch(localDatabaseProvider);
  final care = await ref.watch(myCareProvider.future);
  await ReminderDispatcher(ref.read(notificationRepositoryProvider)).sync(
    userId: user.id,
    appointments: ref.watch(allAppointmentsProvider),
    care: care,
    enabled: db.remindersEnabled(),
  );
});
