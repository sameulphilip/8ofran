import 'package:a3traf/core/constants/app_constants.dart';
import 'package:a3traf/core/firebase/tester_catalog.dart';
import 'package:a3traf/core/utils/validators.dart';
import 'package:a3traf/features/appointments/domain/appointment.dart';
import 'package:a3traf/features/auth/domain/app_user.dart';
import 'package:a3traf/features/care/domain/pastoral_care.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3, 19, 12);
  final world = TesterWorld(now);

  test('every login tester has a unique email and username', () {
    final emails = TesterCatalog.logins.map((item) => item.email).toSet();
    final usernames = TesterCatalog.logins.map((item) => item.username).toSet();
    expect(emails.length, TesterCatalog.logins.length);
    expect(usernames.length, TesterCatalog.logins.length);
    expect(emails, contains(AppConstants.adminEmail));
  });

  test('admin and priest testers have the right roles', () {
    expect(TesterCatalog.admin.toUser().isAdmin, isTrue);
    expect(TesterCatalog.youhanna.toUser().isPriest, isTrue);
    expect(TesterCatalog.ramzi.toUser().role, UserRole.member);
  });

  test('mina works mornings and is off friday', () {
    final mina = world.priests().firstWhere((item) => item.id == 'p_mina');
    expect(mina.firstSlotHour, 9);
    expect(mina.lastSlotHour, 12);
    expect(mina.worksOn(DateTime(2026, 3, 20)), isFalse);
    expect(mina.worksOn(DateTime(2026, 3, 21)), isTrue);
  });

  test('dawoud is hidden and kirollos has no account', () {
    final dawoud = world.priests().firstWhere((item) => item.id == 'p_dawoud');
    final kirollos = world.priests().firstWhere(
      (item) => item.id == 'p_kirollos',
    );
    expect(dawoud.isAvailable, isFalse);
    expect(kirollos.hasAccount, isFalse);
  });

  test('member testers choose a spiritual father', () {
    for (final tester in TesterCatalog.logins) {
      if (tester.role != UserRole.member) continue;
      expect(tester.toUser().hasFather, isTrue);
    }
    expect(
      world.appointments().any(
        (item) =>
            item.userId == TesterCatalog.ramzi.id &&
            item.status == AppointmentStatus.pending,
      ),
      isTrue,
    );
  });

  test('ramzi has an upcoming booking and is not overdue', () {
    final care = world.cares().firstWhere(
      (item) => item.userId == TesterCatalog.ramzi.id,
    );
    final last = lastVisitFor(
      userId: TesterCatalog.ramzi.id,
      priestId: 'p_youhanna',
      appointments: world.appointments(),
      now: now,
    );
    expect(
      world.appointments().any(
        (item) => item.userId == TesterCatalog.ramzi.id && item.isActive,
      ),
      isTrue,
    );
    expect(care.isOverdue(now, last), isFalse);
  });

  test('overdue tester is past the confession cadence', () {
    final care = world.cares().firstWhere(
      (item) => item.userId == TesterCatalog.overdue.id,
    );
    final last = lastVisitFor(
      userId: TesterCatalog.overdue.id,
      priestId: 'p_youhanna',
      appointments: world.appointments(),
      now: now,
    );
    expect(care.isOverdue(now, last), isTrue);
  });

  test('ruled tester has a spiritual canon', () {
    expect(
      world.canons().any((item) => item.userId == TesterCatalog.ruled.id),
      isTrue,
    );
  });

  test('empty tester has no appointments or care', () {
    expect(
      world.appointments().any((item) => item.userId == TesterCatalog.empty.id),
      isFalse,
    );
    expect(
      world.cares().any((item) => item.userId == TesterCatalog.empty.id),
      isFalse,
    );
  });

  test('locked tester appointment is inside the cancel window', () {
    final appointment = world.appointments().firstWhere(
      (item) => item.userId == TesterCatalog.locked.id,
    );
    final deadline = appointment.startsAt.subtract(
      const Duration(hours: AppConstants.cancelDeadlineHours),
    );
    expect(now.isAfter(deadline), isTrue);
    expect(appointment.status, AppointmentStatus.confirmed);
  });

  test('validators cover empty, email and password cases', () {
    expect(Validators.required(''), isNotNull);
    expect(Validators.email('not-mail'), isNotNull);
    expect(Validators.email('ok@ghofran.app'), isNull);
    expect(Validators.password('123'), isNotNull);
    expect(Validators.password(AppConstants.demoPassword), isNull);
    expect(Validators.confirmPassword('12345678', 'mismatch'), isNotNull);
  });
}
