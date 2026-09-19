class SpiritualCanon {
  const SpiritualCanon({
    required this.id,
    required this.userId,
    required this.priestId,
    required this.rule,
    required this.createdAt,
    this.priestUid,
  });

  final String id;
  final String userId;
  final String priestId;
  final String rule;
  final DateTime createdAt;
  final String? priestUid;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'priestId': priestId,
    'rule': rule,
    'createdAt': createdAt.toIso8601String(),
    if (priestUid != null) 'priestUid': priestUid,
  };

  factory SpiritualCanon.fromJson(Map<String, dynamic> json) {
    return SpiritualCanon(
      id: json['id'] as String,
      userId: json['userId'] as String,
      priestId: json['priestId'] as String,
      rule: json['rule'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      priestUid: json['priestUid'] as String?,
    );
  }
}
