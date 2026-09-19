import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../priests/domain/priest.dart';
import '../domain/church.dart';

class AdminRepository {
  AdminRepository(this._db, this._auth, this._store);

  final LocalDatabase _db;
  final AuthRepository _auth;
  final FirebaseFirestore? _store;

  bool get _cloud => _store != null;

  Future<void> saveChurch(Church church) async {
    if (_cloud) {
      await _store!.collection('churches').doc(church.id).set(church.toJson());
      final priests = await _store
          .collection('priests')
          .where('churchId', isEqualTo: church.id)
          .get();
      if (priests.docs.isEmpty) return;
      final batch = _store.batch();
      for (final doc in priests.docs) {
        batch.update(doc.reference, {'churchName': church.name});
      }
      await batch.commit();
      return;
    }
    final churches = [
      for (final item in _db.churches())
        if (item.id != church.id) item,
      church,
    ];
    await _db.saveChurches(churches);
    await _db.savePriests([
      for (final priest in _db.priests())
        if (priest.churchId == church.id)
          priest.copyWith(churchName: church.name)
        else
          priest,
    ]);
  }

  Future<void> savePriest(Priest priest) async {
    final email = priest.email.trim().toLowerCase();
    final saved = priest.copyWith(email: email);
    if (_cloud) {
      await _store!
          .collection('priests')
          .doc(saved.id)
          .set(saved.toJson(), SetOptions(merge: true));
      return;
    }
    await _db.savePriests([
      for (final item in _db.priests())
        if (item.id != saved.id) item,
      saved,
    ]);
  }

  Future<Priest> createPriestAccount({
    required Priest priest,
    required String password,
  }) async {
    if (password.length < 8) {
      throw const AuthException(AppStrings.shortPassword);
    }
    final uid = await _auth.createUserAsAdmin(
      fullName: priest.name,
      email: priest.email,
      password: password,
      role: UserRole.priest,
      priestId: priest.id,
    );
    final linked = priest.copyWith(
      uid: uid,
      email: priest.email.trim().toLowerCase(),
    );
    await savePriest(linked);
    return linked;
  }

  Future<void> sendPriestReset(String email) {
    return _auth.sendPasswordReset(email);
  }
}

String newCatalogId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

final churchesStreamProvider = StreamProvider<List<Church>>((ref) {
  final store = ref.watch(firestoreProvider);
  if (store == null) {
    return Stream.value(ref.watch(localDatabaseProvider).churches());
  }
  return store.collection('churches').snapshots().map((snapshot) {
    return [
      for (final doc in snapshot.docs)
        Church.fromJson({'id': doc.id, ...doc.data()}),
    ];
  });
});

final churchesProvider = Provider<List<Church>>((ref) {
  return ref.watch(churchesStreamProvider).value ?? const [];
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(firestoreProvider),
  );
});
