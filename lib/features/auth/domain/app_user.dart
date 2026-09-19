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
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String password;
  final UserRole role;
  final String? priestId;
  final String? fatherId;

  bool get isPriest =>
      role == UserRole.priest && (priestId?.isNotEmpty ?? false);
  bool get isAdmin => role == UserRole.admin;
  bool get hasFather => fatherId != null && fatherId!.isNotEmpty;
  bool get needsFather => role == UserRole.member && !hasFather;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fullName : parts.first;
  }

  AppUser copyWith({
    UserRole? role,
    String? priestId,
    String? fatherId,
    String? password,
  }) {
    return AppUser(
      id: id,
      fullName: fullName,
      username: username,
      email: email,
      password: password ?? this.password,
      role: role ?? this.role,
      priestId: priestId ?? this.priestId,
      fatherId: fatherId ?? this.fatherId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'username': username,
    'email': email,
    'role': role.name,
    if (priestId != null) 'priestId': priestId,
    if (fatherId != null) 'fatherId': fatherId,
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
    );
  }
}
