import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../../auth/presentation/auth_controller.dart';
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
    state = BookingDraft(priest: state.priest, rescheduleId: state.rescheduleId);
  }

  Future<Appointment> confirm({String notes = ''}) async {
    final user = ref.read(authControllerProvider);
    final draft = state;
    if (user == null || !draft.canConfirm) {
      throw StateError('incomplete booking');
    }
    final appointment = await ref
        .read(appointmentRepositoryProvider)
        .book(
          userId: user.id,
          priestId: draft.priest!.id,
          startsAt: draft.startsAt!,
          notes: notes,
          rescheduleId: draft.rescheduleId,
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
      ref.watch(userNotificationsProvider).value ??
      const <AppNotification>[];
  return items.where((item) => !item.read).length;
});
