import 'package:a3traf/core/data/local_database.dart';
import 'package:a3traf/features/admin/domain/church.dart';
import 'package:a3traf/features/appointments/data/appointment_repository.dart';
import 'package:a3traf/features/auth/domain/app_user.dart';
import 'package:a3traf/features/notifications/data/notification_repository.dart';
import 'package:a3traf/features/priests/domain/priest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('church json keeps name and city', () {
    const church = Church(id: 'ch1', name: 'مار مرقس', city: 'القاهرة');
    final roundtrip = Church.fromJson(church.toJson());
    expect(roundtrip.name, 'مار مرقس');
    expect(roundtrip.city, 'القاهرة');
  });

  test('priest skips configured off weekdays', () {
    const priest = Priest(
      id: 'p1',
      name: 'أبونا',
      churchName: 'القاهرة',
      offWeekdays: {DateTime.friday},
    );
    expect(priest.worksOn(DateTime(2026, 3, 6)), isFalse);
    expect(priest.worksOn(DateTime(2026, 3, 7)), isTrue);
  });

  test('admin role is distinct from priest', () {
    const admin = AppUser(
      id: 'u_admin',
      fullName: 'إدارة',
      username: 'admin',
      email: 'admin@ghofran.app',
      role: UserRole.admin,
    );
    expect(admin.isAdmin, isTrue);
    expect(admin.isPriest, isFalse);
  });

  test('slot list follows a priest hours window', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = LocalDatabase(prefs);
    await db.saveAppointments([]);
    final repository = AppointmentRepository(db, NotificationRepository(db));
    const priest = Priest(
      id: 'p_hours',
      name: 'أبونا',
      churchName: 'القاهرة',
      firstSlotHour: 9,
      lastSlotHour: 10,
      slotMinutes: 30,
    );
    final day = DateTime(2026, 3, 2);
    final slots = repository.availableSlots(
      priestId: priest.id,
      date: day,
      priest: priest,
    );
    expect(slots, [
      DateTime(2026, 3, 2, 9),
      DateTime(2026, 3, 2, 9, 30),
      DateTime(2026, 3, 2, 10),
    ]);
  });
}
