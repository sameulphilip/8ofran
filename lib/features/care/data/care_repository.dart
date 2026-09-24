import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/pastoral_care.dart';
import '../domain/spiritual_canon.dart';

class CareRepository {
  CareRepository(this._store, [this._db]);

  final FirebaseFirestore? _store;
  final LocalDatabase? _db;

  bool get _cloud => _store != null;

  Stream<PastoralCare?> watchCare(String userId) {
    if (!_cloud) {
      PastoralCare? match;
      for (final item in _db?.cares() ?? const <PastoralCare>[]) {
        if (item.userId == userId) match = item;
      }
      return Stream.value(match);
    }
    return _store!.collection('pastoral_care').doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return PastoralCare.fromJson({...doc.data()!, 'userId': doc.id});
    });
  }

  Stream<List<PastoralCare>> watchFlock(String priestId) {
    if (!_cloud) {
      return Stream.value([
        for (final care in _db?.cares() ?? const <PastoralCare>[])
          if (care.priestId == priestId) care,
      ]);
    }
    return _store!
        .collection('pastoral_care')
        .where('priestId', isEqualTo: priestId)
        .snapshots()
        .map((snapshot) {
          return [
            for (final doc in snapshot.docs)
              PastoralCare.fromJson({...doc.data(), 'userId': doc.id}),
          ];
        });
  }

  Stream<SpiritualCanon?> watchCanon(String userId) {
    if (!_cloud) {
      final items = [
        for (final canon in _db?.canons() ?? const <SpiritualCanon>[])
          if (canon.userId == userId) canon,
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(items.isEmpty ? null : items.first);
    }
    return _store!
        .collection('spiritual_canons')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = [
            for (final doc in snapshot.docs)
              SpiritualCanon.fromJson({
                ...doc.data(),
                'id': doc.id,
                'createdAt': _createdAt(doc.data()['createdAt']),
              }),
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items.isEmpty ? null : items.first;
        });
  }

  Future<void> ensureLink({
    required String userId,
    required String priestId,
    String? priestUid,
  }) async {
    if (!_cloud) {
      final db = _db;
      if (db == null) return;
      final current = db.cares();
      if (current.any((item) => item.userId == userId)) return;
      await db.saveCares([
        ...current,
        PastoralCare(
          userId: userId,
          priestId: priestId,
          intervalDays: AppConstants.defaultCadenceDays,
          priestUid: priestUid,
        ),
      ]);
      return;
    }
    final ref = _store!.collection('pastoral_care').doc(userId);
    final existing = await ref.get();
    if (existing.exists) {
      final data = existing.data() ?? {};
      if (priestUid != null && data['priestUid'] == null) {
        await ref.update({'priestUid': priestUid});
      }
      return;
    }
    await ref.set({
      'userId': userId,
      'priestId': priestId,
      'intervalDays': AppConstants.defaultCadenceDays,
      if (priestUid != null) 'priestUid': priestUid,
    });
  }

  Future<void> reassign({
    required String userId,
    required String priestId,
    String? priestUid,
  }) async {
    if (!_cloud) {
      final db = _db;
      if (db == null) return;
      PastoralCare? previous;
      for (final item in db.cares()) {
        if (item.userId == userId) previous = item;
      }
      await db.saveCares([
        for (final item in db.cares())
          if (item.userId != userId) item,
        PastoralCare(
          userId: userId,
          priestId: priestId,
          intervalDays:
              previous?.intervalDays ?? AppConstants.defaultCadenceDays,
          priestUid: priestUid,
        ),
      ]);
      return;
    }
    final ref = _store!.collection('pastoral_care').doc(userId);
    final existing = await ref.get();
    await ref.set({
      'userId': userId,
      'priestId': priestId,
      if (priestUid != null) 'priestUid': priestUid,
      if (!existing.exists) 'intervalDays': AppConstants.defaultCadenceDays,
    }, SetOptions(merge: true));
  }

  Stream<Map<String, SpiritualCanon>> watchLatestCanons(String priestId) {
    if (!_cloud) {
      final latest = <String, SpiritualCanon>{};
      final items = [..._db?.canons() ?? const <SpiritualCanon>[]]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final canon in items) {
        if (canon.priestId != priestId) continue;
        latest.putIfAbsent(canon.userId, () => canon);
      }
      return Stream.value(latest);
    }
    return _store!
        .collection('spiritual_canons')
        .where('priestId', isEqualTo: priestId)
        .snapshots()
        .map((snapshot) {
          final items = [
            for (final doc in snapshot.docs)
              SpiritualCanon.fromJson({
                ...doc.data(),
                'id': doc.id,
                'createdAt': _createdAt(doc.data()['createdAt']),
              }),
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latest = <String, SpiritualCanon>{};
          for (final canon in items) {
            latest.putIfAbsent(canon.userId, () => canon);
          }
          return latest;
        });
  }

  Future<void> clearLink(String userId) async {
    if (!_cloud) {
      final db = _db;
      if (db == null) return;
      await db.saveCares([
        for (final item in db.cares())
          if (item.userId != userId) item,
      ]);
      return;
    }
    await _store!.collection('pastoral_care').doc(userId).delete();
  }

  Future<void> setInterval({
    required String userId,
    required String priestId,
    required int intervalDays,
    String? priestUid,
  }) async {
    if (!_cloud) {
      final db = _db;
      if (db == null) return;
      await db.saveCares([
        for (final item in db.cares())
          if (item.userId != userId) item,
        PastoralCare(
          userId: userId,
          priestId: priestId,
          intervalDays: intervalDays,
          priestUid: priestUid,
        ),
      ]);
      return;
    }
    await _store!.collection('pastoral_care').doc(userId).set({
      'userId': userId,
      'priestId': priestId,
      'intervalDays': intervalDays,
      if (priestUid != null) 'priestUid': priestUid,
    }, SetOptions(merge: true));
  }

  Future<void> assignCanon({
    required String userId,
    required String priestId,
    required String rule,
    String? priestUid,
  }) async {
    final text = rule.trim();
    if (text.isEmpty) return;
    if (!_cloud) {
      final db = _db;
      if (db == null) return;
      await db.saveCanons([
        SpiritualCanon(
          id: 'canon_${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          priestId: priestId,
          priestUid: priestUid,
          rule: text,
          createdAt: DateTime.now(),
        ),
        ...db.canons(),
      ]);
      await ensureLink(
        userId: userId,
        priestId: priestId,
        priestUid: priestUid,
      );
      return;
    }
    await _store!.collection('spiritual_canons').add({
      'userId': userId,
      'priestId': priestId,
      'priestUid': priestUid,
      'rule': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ensureLink(userId: userId, priestId: priestId, priestUid: priestUid);
  }

  String _createdAt(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return DateTime.now().toIso8601String();
  }
}

final careRepositoryProvider = Provider<CareRepository>((ref) {
  return CareRepository(
    ref.watch(firestoreProvider),
    ref.watch(localDatabaseProvider),
  );
});

final myCareProvider = StreamProvider<PastoralCare?>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(careRepositoryProvider).watchCare(user.id);
});

final myCanonProvider = StreamProvider<SpiritualCanon?>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(careRepositoryProvider).watchCanon(user.id);
});

final flockProvider = StreamProvider<List<PastoralCare>>((ref) {
  final user = ref.watch(authControllerProvider);
  final priestId = user?.priestId;
  if (priestId == null) return Stream.value(const []);
  return ref.watch(careRepositoryProvider).watchFlock(priestId);
});

final directoryProvider = StreamProvider<Map<String, AppUser>>((ref) {
  final store = ref.watch(firestoreProvider);
  if (store == null) {
    final users = ref.watch(localDatabaseProvider).users();
    return Stream.value({for (final user in users) user.id: user});
  }
  return store.collection('users').snapshots().map((snapshot) {
    return {
      for (final doc in snapshot.docs)
        doc.id: AppUser.fromJson({...doc.data(), 'id': doc.id}),
    };
  });
});
