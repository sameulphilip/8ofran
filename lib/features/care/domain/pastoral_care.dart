import '../../appointments/domain/appointment.dart';

class PastoralCare {
  const PastoralCare({
    required this.userId,
    required this.priestId,
    required this.intervalDays,
    this.priestUid,
  });

  final String userId;
  final String priestId;
  final int intervalDays;
  final String? priestUid;

  DateTime? dueAt(DateTime? lastVisit) {
    if (lastVisit == null) return null;
    return lastVisit.add(Duration(days: intervalDays));
  }

  bool isOverdue(DateTime now, DateTime? lastVisit) {
    if (lastVisit == null) return true;
    return now.isAfter(lastVisit.add(Duration(days: intervalDays)));
  }

  int daysSince(DateTime now, DateTime? lastVisit) {
    if (lastVisit == null) return -1;
    return now.difference(lastVisit).inDays;
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'priestId': priestId,
    'intervalDays': intervalDays,
    if (priestUid != null) 'priestUid': priestUid,
  };

  factory PastoralCare.fromJson(Map<String, dynamic> json) {
    return PastoralCare(
      userId: json['userId'] as String,
      priestId: json['priestId'] as String,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 30,
      priestUid: json['priestUid'] as String?,
    );
  }
}

enum FlockFilter { all, fresh, regular, overdue }

bool matchesFlockFilter({
  required FlockFilter filter,
  required PastoralCare care,
  required DateTime now,
  DateTime? last,
}) {
  final overdue = care.isOverdue(now, last);
  final fresh = last == null;
  return switch (filter) {
    FlockFilter.all => true,
    FlockFilter.fresh => fresh,
    FlockFilter.overdue => overdue,
    FlockFilter.regular => !fresh && !overdue,
  };
}

DateTime? lastVisitFor({
  required String userId,
  required String priestId,
  required List<Appointment> appointments,
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  DateTime? last;
  for (final item in appointments) {
    if (item.userId != userId || item.priestId != priestId) continue;
    if (!item.countsAsVisit) continue;
    if (!item.startsAt.isAfter(moment) &&
        (last == null || item.startsAt.isAfter(last))) {
      last = item.startsAt;
    }
  }
  return last;
}
