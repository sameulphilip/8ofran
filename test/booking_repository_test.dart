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
    expect(first.status, AppointmentStatus.confirmed);
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
    expect(second.status, AppointmentStatus.confirmed);
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
