class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool? ?? false,
    );
  }
}
