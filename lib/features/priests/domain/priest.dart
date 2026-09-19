import '../../../core/constants/app_constants.dart';

class Priest {
  const Priest({
    required this.id,
    required this.name,
    required this.churchName,
    this.churchId = '',
    this.email = '',
    this.uid,
    this.isAvailable = true,
    this.slotMinutes = AppConstants.slotMinutes,
    this.firstSlotHour = AppConstants.firstSlotHour,
    this.lastSlotHour = AppConstants.lastSlotHour,
    this.offWeekdays = const {},
  });

  final String id;
  final String name;
  final String churchName;
  final String churchId;
  final String email;
  final String? uid;
  final bool isAvailable;
  final int slotMinutes;
  final int firstSlotHour;
  final int lastSlotHour;
  final Set<int> offWeekdays;

  bool get hasAccount => uid != null && uid!.isNotEmpty;

  bool worksOn(DateTime date) => !offWeekdays.contains(date.weekday);

  Priest copyWith({
    String? id,
    String? name,
    String? churchName,
    String? churchId,
    String? email,
    String? uid,
    bool? isAvailable,
    int? slotMinutes,
    int? firstSlotHour,
    int? lastSlotHour,
    Set<int>? offWeekdays,
    bool clearUid = false,
  }) {
    return Priest(
      id: id ?? this.id,
      name: name ?? this.name,
      churchName: churchName ?? this.churchName,
      churchId: churchId ?? this.churchId,
      email: email ?? this.email,
      uid: clearUid ? null : (uid ?? this.uid),
      isAvailable: isAvailable ?? this.isAvailable,
      slotMinutes: slotMinutes ?? this.slotMinutes,
      firstSlotHour: firstSlotHour ?? this.firstSlotHour,
      lastSlotHour: lastSlotHour ?? this.lastSlotHour,
      offWeekdays: offWeekdays ?? this.offWeekdays,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'churchName': churchName,
    'churchId': churchId,
    'email': email,
    if (uid != null) 'uid': uid,
    'isAvailable': isAvailable,
    'slotMinutes': slotMinutes,
    'firstSlotHour': firstSlotHour,
    'lastSlotHour': lastSlotHour,
    'offWeekdays': offWeekdays.toList(),
  };

  factory Priest.fromJson(Map<String, dynamic> json) {
    return Priest(
      id: json['id'] as String,
      name: json['name'] as String,
      churchName: json['churchName'] as String? ?? '',
      churchId: json['churchId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      slotMinutes: json['slotMinutes'] as int? ?? AppConstants.slotMinutes,
      firstSlotHour:
          json['firstSlotHour'] as int? ?? AppConstants.firstSlotHour,
      lastSlotHour: json['lastSlotHour'] as int? ?? AppConstants.lastSlotHour,
      offWeekdays: {
        for (final day in json['offWeekdays'] as List<dynamic>? ?? [])
          (day as num).toInt(),
      },
    );
  }
}
