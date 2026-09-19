enum AppointmentStatus { pending, confirmed, cancelled, completed }

class Appointment {
  const Appointment({
    required this.id,
    required this.userId,
    required this.priestId,
    required this.startsAt,
    required this.status,
    this.notes = '',
  });

  final String id;
  final String userId;
  final String priestId;
  final DateTime startsAt;
  final AppointmentStatus status;
  final String notes;

  bool get isActive =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get isUpcoming =>
      isActive &&
      startsAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)));

  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? startsAt,
    String? id,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId,
      priestId: priestId,
      startsAt: startsAt ?? this.startsAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'priestId': priestId,
    'startsAt': startsAt.toIso8601String(),
    'status': status.name,
    'notes': notes,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      priestId: json['priestId'] as String,
      startsAt: _parseDate(json['startsAt'] ?? json['startsAtIso']),
      status: AppointmentStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.parse(value.toString());
  }
}

class DaySlot {
  const DaySlot({required this.time, required this.taken, required this.past});

  final DateTime time;
  final bool taken;
  final bool past;

  bool get selectable => !taken && !past;
}

class SlotTakenException implements Exception {
  const SlotTakenException();
}

class CancelWindowException implements Exception {
  const CancelWindowException();
}
