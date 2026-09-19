import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/utils/slot_id.dart';
import '../../notifications/data/notification_repository.dart';
import '../domain/appointment.dart';

class AppointmentRepository {
  AppointmentRepository(this._db, this._notifications, [this._store]);

  final LocalDatabase _db;
  final NotificationRepository _notifications;
  final FirebaseFirestore? _store;

  bool get _cloud => _store != null;

  Stream<List<Appointment>> watchAll() {
    if (!_cloud) {
      return Stream.value(_db.appointments());
    }
    return _store!.collection('appointments').snapshots().map((snapshot) {
      return [for (final doc in snapshot.docs) _fromDoc(doc)];
    });
  }

  List<Appointment> all() => _db.appointments();

  Appointment _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final starts = data['startsAt'];
    final iso = starts is Timestamp
        ? starts.toDate().toIso8601String()
        : (data['startsAtIso'] as String? ?? starts.toString());
    return Appointment.fromJson({...data, 'id': doc.id, 'startsAt': iso});
  }

  List<Appointment> forUser(String userId) {
    return all().where((a) => a.userId == userId).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  Appointment? byId(String id) {
    return all().cast<Appointment?>().firstWhere(
      (a) => a!.id == id,
      orElse: () => null,
    );
  }

  bool isSlotTaken(String slotId, {String? ignoreId, List<Appointment>? items}) {
    final source = items ?? all();
    return source.any((a) => a.id == slotId && a.isActive && a.id != ignoreId);
  }

  List<DateTime> availableSlots({
    required String priestId,
    required DateTime date,
    String? ignoreAppointmentId,
    List<Appointment>? items,
  }) {
    final slots = <DateTime>[];
    var cursor = DateTime(
      date.year,
      date.month,
      date.day,
      AppConstants.firstSlotHour,
    );
    final last = DateTime(
      date.year,
      date.month,
      date.day,
      AppConstants.lastSlotHour,
    );
    while (!cursor.isAfter(last)) {
      final id = SlotId.build(
        priestId: priestId,
        date: date,
        time: TimeOfDayLike.fromDateTime(cursor),
      );
      if (!isSlotTaken(id, ignoreId: ignoreAppointmentId, items: items)) {
        slots.add(cursor);
      }
      cursor = cursor.add(const Duration(minutes: AppConstants.slotMinutes));
    }
    return slots;
  }

  List<DaySlot> daySlots({
    required String priestId,
    required DateTime date,
    String? ignoreAppointmentId,
    List<Appointment>? items,
  }) {
    final slots = <DaySlot>[];
    var cursor = DateTime(
      date.year,
      date.month,
      date.day,
      AppConstants.firstSlotHour,
    );
    final last = DateTime(
      date.year,
      date.month,
      date.day,
      AppConstants.lastSlotHour,
    );
    final now = DateTime.now();
    while (!cursor.isAfter(last)) {
      final id = SlotId.build(
        priestId: priestId,
        date: date,
        time: TimeOfDayLike.fromDateTime(cursor),
      );
      slots.add(
        DaySlot(
          time: cursor,
          taken: isSlotTaken(id, ignoreId: ignoreAppointmentId, items: items),
          past: cursor.isBefore(now),
        ),
      );
      cursor = cursor.add(const Duration(minutes: AppConstants.slotMinutes));
    }
    return slots;
  }

  Future<Appointment> book({
    required String userId,
    required String priestId,
    required DateTime startsAt,
    String notes = '',
    String? rescheduleId,
  }) async {
    final id = SlotId.build(
      priestId: priestId,
      date: startsAt,
      time: TimeOfDayLike.fromDateTime(startsAt),
    );
    final appointment = Appointment(
      id: id,
      userId: userId,
      priestId: priestId,
      startsAt: startsAt,
      status: AppointmentStatus.confirmed,
      notes: notes,
    );

    if (_cloud) {
      await _store!.runTransaction((tx) async {
        final ref = _store.collection('appointments').doc(id);
        final snap = await tx.get(ref);
        final existing = snap.data();
        final taken =
            snap.exists &&
            existing != null &&
            existing['status'] != AppointmentStatus.cancelled.name &&
            id != rescheduleId;
        if (taken) throw const SlotTakenException();
        if (rescheduleId != null) {
          tx.update(_store.collection('appointments').doc(rescheduleId), {
            'status': AppointmentStatus.cancelled.name,
          });
        }
        tx.set(ref, {
          ...appointment.toJson(),
          'startsAt': Timestamp.fromDate(startsAt),
          'startsAtIso': startsAt.toIso8601String(),
        });
      });
    } else {
      final current = _db.appointments();
      if (isSlotTaken(id, ignoreId: rescheduleId, items: current)) {
        throw const SlotTakenException();
      }
      var next = current.where((item) => item.id != id).toList();
      if (rescheduleId != null) {
        next = [
          for (final item in next)
            if (item.id == rescheduleId)
              item.copyWith(status: AppointmentStatus.cancelled)
            else
              item,
        ];
      }
      await _db.saveAppointments([...next, appointment]);
    }

    await _notifications.add(
      userId: userId,
      title: AppStrings.bookingConfirmedTitle,
      body: AppStrings.bookingConfirmedBody,
    );
    return appointment;
  }

  Future<void> cancel(String appointmentId) async {
    Appointment? appointment;
    if (_cloud) {
      final snap = await _store!
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (!snap.exists) return;
      appointment = _fromDoc(snap);
    } else {
      appointment = byId(appointmentId);
    }
    if (appointment == null) return;
    _ensureWindow(appointment.startsAt);

    if (_cloud) {
      await _store!.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.name,
      });
    } else {
      await _db.saveAppointments([
        for (final item in all())
          if (item.id == appointmentId)
            item.copyWith(status: AppointmentStatus.cancelled)
          else
            item,
      ]);
    }

    await _notifications.add(
      userId: appointment.userId,
      title: AppStrings.bookingCancelledTitle,
      body: AppStrings.bookingCancelledBody,
    );
  }

  void _ensureWindow(DateTime startsAt) {
    final deadline = startsAt.subtract(
      const Duration(hours: AppConstants.cancelDeadlineHours),
    );
    if (DateTime.now().isAfter(deadline)) {
      throw const CancelWindowException();
    }
  }

  bool canModify(DateTime startsAt) {
    try {
      _ensureWindow(startsAt);
      return true;
    } on CancelWindowException {
      return false;
    }
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(firestoreProvider),
  );
});
