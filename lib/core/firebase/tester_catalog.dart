import '../../features/auth/domain/app_user.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

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

  static const member = TesterAccount(
    id: 'u_member',
    label: AppStrings.testerMember,
    fullName: 'سامي يوسف',
    username: 'user',
    email: 'user@ghofran.app',
    fatherId: 'p_youhanna',
  );

  static const priest = TesterAccount(
    id: 'u_youhanna',
    label: AppStrings.testerPriestSchedule,
    fullName: 'أبونا يوحنا',
    username: 'youhanna',
    email: 'youhanna@ghofran.app',
    role: UserRole.priest,
    priestId: 'p_youhanna',
  );

  static const logins = [admin];

  static const disposable = [
    TesterAccount(
      id: 'u_mina',
      label: AppStrings.testerPriestMorning,
      fullName: 'أبونا مينا',
      username: 'mina',
      email: 'mina@ghofran.app',
      role: UserRole.priest,
      priestId: 'p_mina',
    ),
    TesterAccount(
      id: 'u_ramzi',
      label: AppStrings.testerUpcoming,
      fullName: 'رمزى مكرم',
      username: AppConstants.demoUsername,
      email: 'ramzi@ghofran.app',
      fatherId: 'p_youhanna',
    ),
    TesterAccount(
      id: 'u_empty',
      label: AppStrings.testerEmpty,
      fullName: 'مريم جديد',
      username: 'empty',
      email: 'empty@ghofran.app',
      fatherId: 'p_youhanna',
    ),
    TesterAccount(
      id: 'u_overdue',
      label: AppStrings.testerOverdue,
      fullName: 'يوسف المتأخر',
      username: 'overdue',
      email: 'overdue@ghofran.app',
      fatherId: 'p_youhanna',
    ),
    TesterAccount(
      id: 'u_ruled',
      label: AppStrings.testerRule,
      fullName: 'سارة القانون',
      username: 'ruled',
      email: 'ruled@ghofran.app',
      fatherId: 'p_youhanna',
    ),
    TesterAccount(
      id: 'u_locked',
      label: AppStrings.testerLocked,
      fullName: 'حنا القريب',
      username: 'locked',
      email: 'locked@ghofran.app',
      fatherId: 'p_youhanna',
    ),
  ];

  static bool isDisposableEmail(String email) {
    final query = email.trim().toLowerCase();
    return disposable.any((item) => item.email == query);
  }
}
