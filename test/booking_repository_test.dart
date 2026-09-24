import 'package:a3traf/core/data/local_database.dart';
import 'package:a3traf/features/appointments/data/appointment_repository.dart';
import 'package:a3traf/features/appointments/domain/appointment.dart';
import 'package:a3traf/features/auth/domain/app_user.dart';
import 'package:a3traf/features/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppointmentRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = LocalDatabase(prefs);
    await db.saveUsers([
      const AppUser(
        id: 'u1',
        fullName: 'مستخدم',
        username: 'user',
        email: 'a@b.c',
        password: '12345678',
      ),
    ]);
    await db.saveAppointments([]);
    repository = AppointmentRepository(db, NotificationRepository(db));
  });

  test('first booking wins the slot', () async {
    final starts = DateTime.now().add(const Duration(days: 21));
    final slot = DateTime(starts.year, starts.month, starts.day, 17);
    final first = await repository.book(
      userId: 'u1',
      priestId: 'p_botros',
      startsAt: slot,
    );
    expect(first.status, AppointmentStatus.pending);
    expect(
      () => repository.book(userId: 'u1', priestId: 'p_botros', startsAt: slot),
      throwsA(isA<SlotTakenException>()),
    );
  });

  test('cancelled slot can be booked again', () async {
    final starts = DateTime.now().add(const Duration(days: 30));
    final slot = DateTime(starts.year, starts.month, starts.day, 16, 30);
    final first = await repository.book(
      userId: 'u1',
      priestId: 'p_mina',
      startsAt: slot,
    );
    await repository.cancel(first.id);
    final second = await repository.book(
      userId: 'u1',
      priestId: 'p_mina',
      startsAt: slot,
    );
    expect(second.status, AppointmentStatus.pending);
  });

  test('cancel is blocked inside the 12 hour window', () async {
    final starts = DateTime.now().add(const Duration(hours: 6));
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: starts,
    );
    await repository.respond(appointmentId: booked.id, approve: true);
    expect(repository.canModify(booked.startsAt), isFalse);
    expect(
      () => repository.cancel(booked.id),
      throwsA(isA<CancelWindowException>()),
    );
  });

  test('priest approval confirms a pending request', () async {
    final starts = DateTime.now().add(const Duration(days: 18));
    final slot = DateTime(starts.year, starts.month, starts.day, 16);
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: slot,
    );
    expect(booked.status, AppointmentStatus.pending);
    await repository.respond(appointmentId: booked.id, approve: true);
    expect(repository.byId(booked.id)?.status, AppointmentStatus.confirmed);
  });

  test('priest rejection stores an organizational reason', () async {
    final starts = DateTime.now().add(const Duration(days: 11));
    final slot = DateTime(starts.year, starts.month, starts.day, 16);
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: slot,
    );
    await repository.respond(
      appointmentId: booked.id,
      approve: false,
      rejectReason: 'اختَر وقتًا آخر من الجدول',
    );
    expect(repository.byId(booked.id)?.status, AppointmentStatus.cancelled);
    expect(repository.byId(booked.id)?.rejectReason, 'اختَر وقتًا آخر من الجدول');
  });

  test('priest rejection frees the slot', () async {
    final starts = DateTime.now().add(const Duration(days: 19));
    final slot = DateTime(starts.year, starts.month, starts.day, 17);
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_mina',
      startsAt: slot,
    );
    await repository.respond(appointmentId: booked.id, approve: false);
    expect(repository.byId(booked.id)?.status, AppointmentStatus.cancelled);
    final again = await repository.book(
      userId: 'u1',
      priestId: 'p_mina',
      startsAt: slot,
    );
    expect(again.status, AppointmentStatus.pending);
  });

  test('pending requests can be cancelled inside the 12 hour window', () async {
    final starts = DateTime.now().add(const Duration(hours: 6));
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: starts,
    );
    await repository.cancel(booked.id);
    expect(repository.byId(booked.id)?.status, AppointmentStatus.cancelled);
  });

  test('booking stores remind preference', () async {
    final starts = DateTime.now().add(const Duration(days: 12));
    final slot = DateTime(starts.year, starts.month, starts.day, 16);
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: slot,
      remind: false,
    );
    expect(booked.remind, isFalse);
    expect(repository.byId(booked.id)?.remind, isFalse);
  });

  test('priest can mark a started visit completed', () async {
    final starts = DateTime.now().subtract(const Duration(minutes: 15));
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: starts,
    );
    await repository.respond(appointmentId: booked.id, approve: true);
    await repository.complete(booked.id);
    expect(repository.byId(booked.id)?.status, AppointmentStatus.completed);
  });

  test('cannot complete a future confirmed visit too early', () async {
    final starts = DateTime.now().add(const Duration(days: 4));
    final slot = DateTime(starts.year, starts.month, starts.day, 16);
    final booked = await repository.book(
      userId: 'u1',
      priestId: 'p_youhanna',
      startsAt: slot,
    );
    await repository.respond(appointmentId: booked.id, approve: true);
    expect(
      () => repository.complete(booked.id),
      throwsA(isA<CompleteWindowException>()),
    );
  });

  test('priest availability list excludes taken slots', () async {
    final day = DateTime.now().add(const Duration(days: 14));
    await repository.book(
      userId: 'u1',
      priestId: 'p_kyrillos',
      startsAt: DateTime(day.year, day.month, day.day, 15),
    );
    final slots = repository.availableSlots(priestId: 'p_kyrillos', date: day);
    expect(slots, isNot(contains(DateTime(day.year, day.month, day.day, 15))));
    expect(slots, contains(DateTime(day.year, day.month, day.day, 15, 30)));
  });
}
