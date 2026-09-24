import 'package:a3traf/features/appointments/domain/appointment.dart';
import 'package:a3traf/features/care/domain/pastoral_care.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final care = const PastoralCare(
    userId: 'u1',
    priestId: 'p_youhanna',
    intervalDays: 30,
  );

  test('overdue when last visit is older than the interval', () {
    final last = DateTime(2026, 1, 1);
    final now = DateTime(2026, 2, 10);
    expect(care.isOverdue(now, last), isTrue);
    expect(care.daysSince(now, last), 40);
  });

  test('not overdue inside the interval', () {
    final last = DateTime(2026, 2, 1);
    final now = DateTime(2026, 2, 10);
    expect(care.isOverdue(now, last), isFalse);
  });

  test('never visited is overdue', () {
    expect(care.isOverdue(DateTime.now(), null), isTrue);
    expect(care.daysSince(DateTime.now(), null), -1);
  });

  test('flock filters split new, regular, and overdue members', () {
    final now = DateTime(2026, 3, 1);
    expect(
      matchesFlockFilter(
        filter: FlockFilter.fresh,
        care: care,
        now: now,
        last: null,
      ),
      isTrue,
    );
    expect(
      matchesFlockFilter(
        filter: FlockFilter.regular,
        care: care,
        now: now,
        last: DateTime(2026, 2, 20),
      ),
      isTrue,
    );
    expect(
      matchesFlockFilter(
        filter: FlockFilter.overdue,
        care: care,
        now: now,
        last: DateTime(2026, 1, 1),
      ),
      isTrue,
    );
  });

  test('last visit uses past confirmed appointments only', () {
    final now = DateTime(2026, 3, 1, 12);
    final items = [
      Appointment(
        id: 'a1',
        userId: 'u1',
        priestId: 'p_youhanna',
        startsAt: DateTime(2026, 1, 10, 17),
        status: AppointmentStatus.confirmed,
      ),
      Appointment(
        id: 'a2',
        userId: 'u1',
        priestId: 'p_youhanna',
        startsAt: DateTime(2026, 2, 10, 17),
        status: AppointmentStatus.cancelled,
      ),
      Appointment(
        id: 'a3',
        userId: 'u1',
        priestId: 'p_youhanna',
        startsAt: DateTime(2026, 4, 1, 17),
        status: AppointmentStatus.confirmed,
      ),
      Appointment(
        id: 'a4',
        userId: 'u1',
        priestId: 'p_youhanna',
        startsAt: DateTime(2026, 2, 20, 17),
        status: AppointmentStatus.completed,
      ),
    ];
    expect(
      lastVisitFor(
        userId: 'u1',
        priestId: 'p_youhanna',
        appointments: items,
        now: now,
      ),
      DateTime(2026, 2, 20, 17),
    );
  });
}
