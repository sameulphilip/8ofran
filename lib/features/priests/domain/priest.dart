class Priest {
  const Priest({
    required this.id,
    required this.name,
    required this.churchName,
    this.isAvailable = true,
    this.slotMinutes = 30,
    this.offWeekdays = const {},
  });

  final String id;
  final String name;
  final String churchName;
  final bool isAvailable;
  final int slotMinutes;
  final Set<int> offWeekdays;

  bool worksOn(DateTime date) => !offWeekdays.contains(date.weekday);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'churchName': churchName,
    'isAvailable': isAvailable,
    'slotMinutes': slotMinutes,
    'offWeekdays': offWeekdays.toList(),
  };

  factory Priest.fromJson(Map<String, dynamic> json) {
    return Priest(
      id: json['id'] as String,
      name: json['name'] as String,
      churchName: json['churchName'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      slotMinutes: json['slotMinutes'] as int? ?? 30,
      offWeekdays: {
        for (final day in json['offWeekdays'] as List<dynamic>? ?? [])
          (day as num).toInt(),
      },
    );
  }
}
