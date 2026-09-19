import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._db, [this._store]);

  final LocalDatabase _db;
  final FirebaseFirestore? _store;

  bool get _cloud => _store != null;

  Stream<List<AppNotification>> watchForUser(String userId) {
    if (!_cloud) {
      return Stream.value(forUser(userId));
    }
    return _store!
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = [
            for (final doc in snapshot.docs)
              AppNotification.fromJson({
                ...doc.data(),
                'id': doc.id,
                'createdAt': _createdAt(doc.data()['createdAt']),
              }),
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  List<AppNotification> forUser(String userId) {
    return _db.notificationsFor(userId)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int unreadCount(String userId) {
    return forUser(userId).where((n) => !n.read).length;
  }

  Future<void> add({
    required String userId,
    required String title,
    required String body,
  }) async {
    if (_cloud) {
      await _store!.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      return;
    }
    final items = forUser(userId);
    await _db.saveNotifications(userId, [
      AppNotification(
        id: 'n_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
      ...items,
    ]);
  }

  Future<void> markAllRead(String userId) async {
    if (_cloud) {
      final snap = await _store!
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      final batch = _store.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      return;
    }
    await _db.saveNotifications(userId, [
      for (final item in forUser(userId)) item.copyWith(read: true),
    ]);
  }

  String _createdAt(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return DateTime.now().toIso8601String();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(firestoreProvider),
  );
});
