enum FatherTransferStatus { pending, approved, rejected, cancelled }

class FatherTransfer {
  const FatherTransfer({
    required this.id,
    required this.userId,
    required this.fromPriestId,
    required this.toPriestId,
    required this.createdAt,
    this.status = FatherTransferStatus.pending,
    this.fromApproved = false,
    this.toApproved = false,
  });

  final String id;
  final String userId;
  final String fromPriestId;
  final String toPriestId;
  final DateTime createdAt;
  final FatherTransferStatus status;
  final bool fromApproved;
  final bool toApproved;

  bool get isPending => status == FatherTransferStatus.pending;

  bool get bothApproved => fromApproved && toApproved;

  bool needsActionFrom(String? priestId) {
    if (!isPending || priestId == null || priestId.isEmpty) return false;
    if (priestId == fromPriestId) return !fromApproved;
    if (priestId == toPriestId) return !toApproved;
    return false;
  }

  FatherTransfer copyWith({
    FatherTransferStatus? status,
    bool? fromApproved,
    bool? toApproved,
  }) {
    return FatherTransfer(
      id: id,
      userId: userId,
      fromPriestId: fromPriestId,
      toPriestId: toPriestId,
      createdAt: createdAt,
      status: status ?? this.status,
      fromApproved: fromApproved ?? this.fromApproved,
      toApproved: toApproved ?? this.toApproved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'fromPriestId': fromPriestId,
    'toPriestId': toPriestId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'fromApproved': fromApproved,
    'toApproved': toApproved,
  };

  factory FatherTransfer.fromJson(Map<String, dynamic> json) {
    return FatherTransfer(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fromPriestId: json['fromPriestId'] as String,
      toPriestId: json['toPriestId'] as String,
      createdAt: _parseDate(json['createdAt']),
      status: FatherTransferStatus.values.byName(
        json['status'] as String? ?? 'pending',
      ),
      fromApproved: json['fromApproved'] as bool? ?? false,
      toApproved: json['toApproved'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}

class TransferPendingException implements Exception {
  const TransferPendingException();
}

class TransferInvalidException implements Exception {
  const TransferInvalidException();
}
