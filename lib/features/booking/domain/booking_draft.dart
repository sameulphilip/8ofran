import '../../priests/domain/priest.dart';

class BookingDraft {
  const BookingDraft({this.priest, this.startsAt, this.rescheduleId});

  final Priest? priest;
  final DateTime? startsAt;
  final String? rescheduleId;

  bool get canConfirm => priest != null && startsAt != null;

  BookingDraft copyWith({
    Priest? priest,
    DateTime? startsAt,
    String? rescheduleId,
    bool clearReschedule = false,
  }) {
    return BookingDraft(
      priest: priest ?? this.priest,
      startsAt: startsAt ?? this.startsAt,
      rescheduleId: clearReschedule
          ? null
          : (rescheduleId ?? this.rescheduleId),
    );
  }
}
