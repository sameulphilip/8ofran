import 'package:a3traf/features/admin/domain/admin_scope.dart';
import 'package:a3traf/features/admin/domain/church.dart';
import 'package:a3traf/features/appointments/domain/appointment.dart';
import 'package:a3traf/features/auth/domain/app_user.dart';
import 'package:a3traf/features/priests/domain/priest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const superAdmin = AppUser(
    id: 'a1',
    fullName: 'إدارة',
    username: 'admin',
    email: 'admin@ghofran.app',
    role: UserRole.admin,
  );
  const steward = AppUser(
    id: 'a2',
    fullName: 'أمين',
    username: 'steward',
    email: 'steward@ghofran.app',
    role: UserRole.admin,
    churchId: 'ch_cairo',
  );
  const churches = [
    Church(id: 'ch_cairo', name: 'القاهرة'),
    Church(id: 'ch_alex', name: 'الإسكندرية', isActive: false),
  ];
  const priests = [
    Priest(
      id: 'p1',
      name: 'أبونا يوحنا',
      churchId: 'ch_cairo',
      churchName: 'القاهرة',
    ),
    Priest(
      id: 'p2',
      name: 'أبونا مينا',
      churchId: 'ch_alex',
      churchName: 'الإسكندرية',
    ),
  ];
  const members = [
    AppUser(
      id: 'u1',
      fullName: 'ابن القاهرة',
      username: 'cairo',
      email: 'c@ghofran.app',
      fatherId: 'p1',
    ),
    AppUser(
      id: 'u2',
      fullName: 'ابن الإسكندرية',
      username: 'alex',
      email: 'a@ghofran.app',
      fatherId: 'p2',
    ),
    AppUser(
      id: 'u3',
      fullName: 'بدون أب',
      username: 'free',
      email: 'f@ghofran.app',
    ),
  ];

  test('super admin sees every church and member', () {
    expect(churchesForAdmin(superAdmin, churches), hasLength(2));
    expect(membersForAdmin(superAdmin, members, priests), hasLength(3));
    expect(superAdmin.isSuperAdmin, isTrue);
    expect(steward.isSteward, isTrue);
  });

  test('church steward is limited to their church scope', () {
    expect(churchesForAdmin(steward, churches).single.id, 'ch_cairo');
    expect(priestsForAdmin(steward, priests).single.id, 'p1');
    final scoped = membersForAdmin(steward, members, priests);
    expect(scoped.map((item) => item.id), containsAll(['u1', 'u3']));
    expect(scoped.map((item) => item.id), isNot(contains('u2')));
  });

  test('paused churches hide priests from booking', () {
    final bookable = bookablePriests(priests, churches);
    expect(bookable.map((item) => item.id), ['p1']);
  });

  test('admin stats use the scoped flock only', () {
    final now = DateTime(2026, 3, 10, 12);
    final appointments = [
      Appointment(
        id: 'a1',
        userId: 'u1',
        priestId: 'p1',
        startsAt: DateTime(2026, 3, 10, 16),
        status: AppointmentStatus.pending,
      ),
      Appointment(
        id: 'a2',
        userId: 'u2',
        priestId: 'p2',
        startsAt: DateTime(2026, 3, 10, 17),
        status: AppointmentStatus.confirmed,
      ),
    ];
    final stats = buildAdminStats(
      actor: steward,
      users: members,
      appointments: appointments,
      priests: priests,
      churches: churches,
      now: now,
    );
    expect(stats.members, 2);
    expect(stats.pendingBookings, 1);
    expect(stats.todayAppointments, 1);
    expect(stats.availablePriests, 1);
  });

  test('member search matches name email and username', () {
    expect(matchesMemberQuery(members.first, 'القاهرة'), isTrue);
    expect(matchesMemberQuery(members.first, 'c@ghofran'), isTrue);
    expect(matchesMemberQuery(members.first, 'cairo'), isTrue);
    expect(matchesMemberQuery(members.first, 'mina'), isFalse);
  });

  test('super admin account list includes every role', () {
    final all = [
      ...members,
      superAdmin,
      const AppUser(
        id: 'p_user',
        fullName: 'كاهن',
        username: 'priest',
        email: 'priest@ghofran.app',
        role: UserRole.priest,
        priestId: 'p1',
      ),
    ];
    expect(accountsForAdmin(superAdmin, all, priests), hasLength(5));
    expect(accountsForAdmin(steward, all, priests).length, lessThan(5));
  });
}
