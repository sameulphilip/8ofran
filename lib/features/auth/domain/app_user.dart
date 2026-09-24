import '../../../core/constants/app_constants.dart';

enum UserRole { member, priest, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.password = '',
    this.role = UserRole.member,
    this.priestId,
    this.fatherId,
    this.churchId,
    this.isSuspended = false,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String password;
  final UserRole role;
  final String? priestId;
  final String? fatherId;
  final String? churchId;
  final bool isSuspended;

  bool get isPriest =>
      role == UserRole.priest && (priestId?.isNotEmpty ?? false);
  bool get isAdmin => role == UserRole.admin;
  bool get hasManagedChurch => churchId != null && churchId!.isNotEmpty;
  bool get isSuperAdmin =>
      isAdmin &&
      (email.trim().toLowerCase() == AppConstants.adminEmail ||
          !hasManagedChurch);
  bool get isSteward => isAdmin && hasManagedChurch && !isSuperAdmin;
  bool get canAccessAdmin => isAdmin;
  bool get hasFather => fatherId != null && fatherId!.isNotEmpty;
  bool get needsFather => role == UserRole.member && !hasFather && !isSuspended;
  bool get canBook =>
      role == UserRole.member && !isSuspended && hasFather && !isAdmin;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fullName : parts.first;
  }

  bool managesChurch(String? id) {
    if (isSuperAdmin) return true;
    if (!isSteward || id == null || id.isEmpty) return false;
    return churchId == id;
  }

  bool managesPriest(String? priestChurchId) {
    if (isSuperAdmin) return true;
    if (!isSteward) return false;
    return priestChurchId != null && priestChurchId == churchId;
  }

  AppUser copyWith({
    UserRole? role,
    String? priestId,
    String? fatherId,
    String? churchId,
    String? password,
    bool? isSuspended,
    bool clearFather = false,
    bool clearChurch = false,
  }) {
    return AppUser(
      id: id,
      fullName: fullName,
      username: username,
      email: email,
      password: password ?? this.password,
      role: role ?? this.role,
      priestId: priestId ?? this.priestId,
      fatherId: clearFather ? null : (fatherId ?? this.fatherId),
      churchId: clearChurch ? null : (churchId ?? this.churchId),
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'username': username,
    'email': email,
    'role': role.name,
    if (priestId != null) 'priestId': priestId,
    if (fatherId != null && fatherId!.isNotEmpty) 'fatherId': fatherId,
    if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
    if (isSuspended) 'isSuspended': true,
  };

  Map<String, dynamic> toLocalJson() => {...toJson(), 'password': password};

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String? ?? '',
      role: UserRole.values.byName(json['role'] as String? ?? 'member'),
      priestId: json['priestId'] as String?,
      fatherId: json['fatherId'] as String?,
      churchId: json['churchId'] as String?,
      isSuspended: json['isSuspended'] as bool? ?? false,
    );
  }
}
