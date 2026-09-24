import 'package:a3traf/core/data/local_database.dart';
import 'package:a3traf/features/appointments/data/appointment_repository.dart';
import 'package:a3traf/features/appointments/domain/appointment.dart';
import 'package:a3traf/features/auth/data/auth_repository.dart';
import 'package:a3traf/features/auth/domain/app_user.dart';
import 'package:a3traf/features/care/data/care_repository.dart';
import 'package:a3traf/features/care/domain/pastoral_care.dart';
import 'package:a3traf/features/notifications/data/notification_repository.dart';
import 'package:a3traf/features/priests/data/father_transfer_repository.dart';
import 'package:a3traf/features/priests/data/priest_repository.dart';
import 'package:a3traf/features/priests/domain/father_transfer.dart';
import 'package:a3traf/features/priests/domain/priest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase db;
  late FatherTransferRepository transfers;
  late AppointmentRepository appointments;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = LocalDatabase(prefs);
    await db.saveUsers([
      const AppUser(
        id: 'u1',
        fullName: 'ابن',
        username: 'son',
        email: 'son@ghofran.app',
        fatherId: 'p_from',
      ),
    ]);
    await db.savePriests(const [
      Priest(id: 'p_from', name: 'أبونا الحالي', churchName: 'كنيسة'),
      Priest(
        id: 'p_to',
        name: 'أبونا الجديد',
        churchName: 'كنيسة',
        uid: 'priest_to',
      ),
    ]);
    await db.saveCares(const [
      PastoralCare(userId: 'u1', priestId: 'p_from', intervalDays: 30),
    ]);
    await db.saveAppointments([]);
    await db.saveTransfers(const []);
    appointments = AppointmentRepository(db, NotificationRepository(db));
    transfers = FatherTransferRepository(
      db,
      AuthRepository(db, null, null),
      CareRepository(null, db),
      appointments,
      NotificationRepository(db),
      PriestRepository(db.priests()),
    );
  });

  test('both priests must approve before the father changes', () async {
    final request = await transfers.request(
      userId: 'u1',
      fromPriestId: 'p_from',
      toPriestId: 'p_to',
    );
    final afterCurrent = await transfers.respond(
      transferId: request.id,
      actorPriestId: 'p_from',
      approve: true,
    );
    expect(afterCurrent.status, FatherTransferStatus.pending);
    expect(db.users().first.fatherId, 'p_from');

    final done = await transfers.respond(
      transferId: request.id,
      actorPriestId: 'p_to',
      approve: true,
    );
    expect(done.status, FatherTransferStatus.approved);
    expect(db.users().first.fatherId, 'p_to');
    expect(db.cares().first.priestId, 'p_to');
  });

  test('admin can approve a transfer immediately', () async {
    final request = await transfers.request(
      userId: 'u1',
      fromPriestId: 'p_from',
      toPriestId: 'p_to',
    );
    final done = await transfers.respond(
      transferId: request.id,
      actorPriestId: '',
      approve: true,
      asAdmin: true,
    );
    expect(done.status, FatherTransferStatus.approved);
    expect(db.users().first.fatherId, 'p_to');
  });

  test('a priest rejection keeps the current father', () async {
    final request = await transfers.request(
      userId: 'u1',
      fromPriestId: 'p_from',
      toPriestId: 'p_to',
    );
    final done = await transfers.respond(
      transferId: request.id,
      actorPriestId: 'p_to',
      approve: false,
    );
    expect(done.status, FatherTransferStatus.rejected);
    expect(db.users().first.fatherId, 'p_from');
  });

  test('pending bookings with the old father are cancelled', () async {
    final starts = DateTime.now().add(const Duration(days: 10));
    await appointments.book(
      userId: 'u1',
      priestId: 'p_from',
      startsAt: DateTime(starts.year, starts.month, starts.day, 16),
    );
    final request = await transfers.request(
      userId: 'u1',
      fromPriestId: 'p_from',
      toPriestId: 'p_to',
    );
    await transfers.respond(
      transferId: request.id,
      actorPriestId: '',
      approve: true,
      asAdmin: true,
    );
    expect(db.appointments().first.status, AppointmentStatus.cancelled);
  });

  test('a second pending request is rejected', () async {
    await transfers.request(
      userId: 'u1',
      fromPriestId: 'p_from',
      toPriestId: 'p_to',
    );
    expect(
      () => transfers.request(
        userId: 'u1',
        fromPriestId: 'p_from',
        toPriestId: 'p_to',
      ),
      throwsA(isA<TransferPendingException>()),
    );
  });
}
