enum UserRole { member, priest, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.password = '',
    this.role = UserRole.member,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String password;
  final UserRole role;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fullName : parts.first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'username': username,
    'email': email,
    'role': role.name,
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
    );
  }
}
