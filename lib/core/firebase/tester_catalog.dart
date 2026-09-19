import '../../features/appointments/domain/appointment.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/care/domain/pastoral_care.dart';
import '../../features/care/domain/spiritual_canon.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/priests/domain/priest.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../utils/slot_id.dart';
import 'seed_catalog.dart';

class TesterAccount {
  const TesterAccount({
    required this.id,
    required this.label,
    required this.fullName,
    required this.username,
    required this.email,
    this.role = UserRole.member,
    this.priestId,
    this.fatherId,
  });

  final String id;
  final String label;
  final String fullName;
  final String username;
  final String email;
  final UserRole role;
  final String? priestId;
  final String? fatherId;

  String get password => AppConstants.demoPassword;

  AppUser toUser() {
    return AppUser(
      id: id,
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      role: role,
      priestId: priestId,
      fatherId: fatherId,
    );
  }
}

class TesterCatalog {
  TesterCatalog._();

  static const admin = TesterAccount(
    id: 'u_admin',
    label: AppStrings.testerAdmin,
    fullName: 'إدارة غفران',
    username: 'admin',
    email: AppConstants.adminEmail,
    role: UserRole.admin,
  );

  static const youhanna = TesterAccount(
    id: 'u_youhanna',
    label: AppStrings.testerPriestSchedule,
    fullName: 'أبونا يوحنا',
    username: 'youhanna',
    email: 'youhanna@ghofran.app',
    role: UserRole.priest,
    priestId: 'p_youhanna',
  );

  static const mina = TesterAccount(
    id: 'u_mina',
    label: AppStrings.testerPriestMorning,
    fullName: 'أبونا مينا',
    username: 'mina',
    email: 'mina@ghofran.app',
    role: UserRole.priest,
    priestId: 'p_mina',
  );

  static const ramzi = TesterAccount(
    id: 'u_ramzi',
    label: AppStrings.testerUpcoming,
    fullName: 'رمزى مكرم',
    username: AppConstants.demoUsername,
    email: 'ramzi@ghofran.app',
    fatherId: 'p_youhanna',
  );

  static const empty = TesterAccount(
    id: 'u_empty',
    label: AppStrings.testerEmpty,
    fullName: 'مريم جديد',
    username: 'empty',
    email: 'empty@ghofran.app',
    fatherId: 'p_youhanna',
  );

  static const overdue = TesterAccount(
    id: 'u_overdue',
    label: AppStrings.testerOverdue,
    fullName: 'يوسف المتأخر',
    username: 'overdue',
    email: 'overdue@ghofran.app',
    fatherId: 'p_youhanna',
  );

  static const ruled = TesterAccount(
    id: 'u_ruled',
    label: AppStrings.testerRule,
    fullName: 'سارة القانون',
    username: 'ruled',
    email: 'ruled@ghofran.app',
    fatherId: 'p_youhanna',
  );

  static const locked = TesterAccount(
    id: 'u_locked',
    label: AppStrings.testerLocked,
    fullName: 'حنا القريب',
    username: 'locked',
    email: 'locked@ghofran.app',
    fatherId: 'p_youhanna',
  );

  static const logins = [
    admin,
    youhanna,
    mina,
    ramzi,
    empty,
    overdue,
    ruled,
    locked,
  ];

  static List<Priest> priests() {
    return [
      for (final priest in seedPriests)
        switch (priest.id) {
          'p_youhanna' => priest.copyWith(uid: youhanna.id),
          'p_mina' => priest.copyWith(
            uid: mina.id,
            firstSlotHour: 9,
            lastSlotHour: 12,
            offWeekdays: {DateTime.friday},
          ),
          'p_dawoud' => priest.copyWith(isAvailable: false),
          'p_bishoy' => priest.copyWith(
            firstSlotHour: 16,
            lastSlotHour: 20,
            slotMinutes: 45,
          ),
          _ => priest,
        },
    ];
  }
}

class TesterWorld {
  TesterWorld([DateTime? now]) : now = now ?? DateTime.now();

  final DateTime now;

  List<AppUser> users() => [
    for (final tester in TesterCatalog.logins) tester.toUser(),
  ];

  List<Priest> priests() => TesterCatalog.priests();

  List<Appointment> appointments() {
    final upcoming = _nextSaturdayAt(17, 0);
    final recent = now.subtract(const Duration(days: 10));
    final old = now.subtract(const Duration(days: 60));
    final soon = now.add(const Duration(hours: 6));
    return [
      _slot(
        userId: TesterCatalog.ramzi.id,
        priestId: 'p_youhanna',
        startsAt: upcoming,
        status: AppointmentStatus.pending,
      ),
      _slot(
        userId: TesterCatalog.ramzi.id,
        priestId: 'p_youhanna',
        startsAt: recent,
        status: AppointmentStatus.completed,
      ),
      _slot(
        userId: TesterCatalog.overdue.id,
        priestId: 'p_youhanna',
        startsAt: old,
        status: AppointmentStatus.completed,
      ),
      _slot(
        userId: TesterCatalog.ruled.id,
        priestId: 'p_youhanna',
        startsAt: recent,
        status: AppointmentStatus.completed,
      ),
      _slot(
        userId: TesterCatalog.locked.id,
        priestId: 'p_youhanna',
        startsAt: soon,
        status: AppointmentStatus.confirmed,
      ),
    ];
  }

  List<PastoralCare> cares() {
    return [
      PastoralCare(
        userId: TesterCatalog.ramzi.id,
        priestId: 'p_youhanna',
        intervalDays: 30,
        priestUid: TesterCatalog.youhanna.id,
      ),
      PastoralCare(
        userId: TesterCatalog.overdue.id,
        priestId: 'p_youhanna',
        intervalDays: 30,
        priestUid: TesterCatalog.youhanna.id,
      ),
      PastoralCare(
        userId: TesterCatalog.ruled.id,
        priestId: 'p_youhanna',
        intervalDays: 30,
        priestUid: TesterCatalog.youhanna.id,
      ),
      PastoralCare(
        userId: TesterCatalog.locked.id,
        priestId: 'p_youhanna',
        intervalDays: 30,
        priestUid: TesterCatalog.youhanna.id,
      ),
    ];
  }

  List<SpiritualCanon> canons() {
    return [
      SpiritualCanon(
        id: 'canon_ruled',
        userId: TesterCatalog.ruled.id,
        priestId: 'p_youhanna',
        priestUid: TesterCatalog.youhanna.id,
        rule: 'مزمور كل مساء، وصلاة يسوع بهدوء.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  Map<String, List<AppNotification>> notifications() {
    return {
      TesterCatalog.ramzi.id: [
        AppNotification(
          id: 'n_ramzi_1',
          title: AppStrings.bookingRequestedTitle,
          body: AppStrings.bookingRequestedBody,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: 'n_ramzi_2',
          title: AppStrings.reminderOneDayTitle,
          body: AppStrings.reminderAppointmentBody,
          createdAt: now.subtract(const Duration(hours: 5)),
          read: true,
        ),
      ],
    };
  }

  Appointment _slot({
    required String userId,
    required String priestId,
    required DateTime startsAt,
    required AppointmentStatus status,
  }) {
    return Appointment(
      id: SlotId.build(
        priestId: priestId,
        date: startsAt,
        time: TimeOfDayLike.fromDateTime(startsAt),
      ),
      userId: userId,
      priestId: priestId,
      startsAt: startsAt,
      status: status,
    );
  }

  DateTime _nextSaturdayAt(int hour, int minute) {
    var date = now.add(const Duration(days: 1));
    while (date.weekday != DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
