import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../care/data/care_repository.dart';
import '../../priests/data/priest_repository.dart';
import '../../priests/domain/priest.dart';
import '../domain/admin_scope.dart';
import '../domain/church.dart';

class AdminRepository {
  AdminRepository(this._db, this._auth, this._care, this._store);

  final LocalDatabase _db;
  final AuthRepository _auth;
  final CareRepository _care;
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

  Future<void> unlinkPriestAccount(Priest priest) async {
    final cleared = priest.copyWith(clearUid: true);
    if (_cloud) {
      await _store!.collection('priests').doc(priest.id).set({
        ...cleared.toJson(),
        'uid': FieldValue.delete(),
      }, SetOptions(merge: true));
      return;
    }
    await savePriest(cleared);
  }

  Future<void> sendPriestReset(String email) {
    return _auth.sendPasswordReset(email);
  }

  Future<void> assignMemberFather({
    required String userId,
    required String fatherId,
    String? priestUid,
  }) async {
    await _auth.writeFatherId(userId, fatherId);
    await _care.reassign(
      userId: userId,
      priestId: fatherId,
      priestUid: priestUid,
    );
  }

  Future<void> unlinkMemberFather(String userId) async {
    await _auth.clearFatherId(userId);
    await _care.clearLink(userId);
  }

  Future<void> setMemberSuspended(String userId, bool suspended) {
    return _auth.setSuspended(userId, suspended);
  }

  Future<String> createSteward({
    required String fullName,
    required String email,
    required String password,
    required String churchId,
  }) {
    if (churchId.trim().isEmpty) {
      throw const AuthException(AppStrings.chooseChurchError);
    }
    if (password.length < 8) {
      throw const AuthException(AppStrings.shortPassword);
    }
    return _auth.createUserAsAdmin(
      fullName: fullName,
      email: email,
      password: password,
      role: UserRole.admin,
      churchId: churchId,
    );
  }

  Future<String> createMemberAccount({
    required String fullName,
    required String email,
    required String password,
    String? fatherId,
  }) async {
    if (password.length < 8) {
      throw const AuthException(AppStrings.shortPassword);
    }
    final uid = await _auth.createUserAsAdmin(
      fullName: fullName,
      email: email,
      password: password,
      role: UserRole.member,
    );
    if (fatherId != null && fatherId.isNotEmpty) {
      await assignMemberFather(userId: uid, fatherId: fatherId);
    }
    return uid;
  }

  Future<void> deleteChurch(String churchId) async {
    if (_cloud) {
      await _store!.collection('churches').doc(churchId).delete();
      return;
    }
    await _db.saveChurches([
      for (final church in _db.churches())
        if (church.id != churchId) church,
    ]);
  }

  Future<void> deletePriest(String priestId) async {
    if (_cloud) {
      final store = _store!;
      await store.collection('priests').doc(priestId).delete();
      final linked = await store
          .collection('users')
          .where('fatherId', isEqualTo: priestId)
          .get();
      if (linked.docs.isNotEmpty) {
        final batch = store.batch();
        for (final doc in linked.docs) {
          batch.update(doc.reference, {'fatherId': FieldValue.delete()});
        }
        await batch.commit();
      }
      return;
    }
    await _db.savePriests([
      for (final priest in _db.priests())
        if (priest.id != priestId) priest,
    ]);
  }

  Future<void> deleteAccount({
    required String userId,
    required String actorId,
    required String email,
  }) async {
    if (userId == actorId) {
      throw const AuthException(AppStrings.cannotDeleteSelf);
    }
    if (email.trim().toLowerCase() == AppConstants.adminEmail) {
      throw const AuthException(AppStrings.cannotDeleteSeedAdmin);
    }
    if (_cloud) {
      final store = _store!;
      final doc = await store.collection('users').doc(userId).get();
      final username = doc.data()?['username'] as String?;
      await store.collection('users').doc(userId).delete();
      if (username != null && username.isNotEmpty) {
        await store
            .collection('usernames')
            .doc(username.toLowerCase())
            .delete();
      }
      try {
        await store.collection('pastoral_care').doc(userId).delete();
      } catch (_) {}
      return;
    }
    await _db.saveUsers([
      for (final user in _db.users())
        if (user.id != userId) user,
    ]);
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
    ref.watch(careRepositoryProvider),
    ref.watch(firestoreProvider),
  );
});

final scopedChurchesProvider = Provider<List<Church>>((ref) {
  final actor = ref.watch(authControllerProvider);
  final churches = ref.watch(churchesProvider);
  if (actor == null || !actor.isAdmin) return const [];
  return churchesForAdmin(actor, churches);
});

final scopedPriestsProvider = Provider<List<Priest>>((ref) {
  final actor = ref.watch(authControllerProvider);
  final priests = ref.watch(priestsProvider);
  if (actor == null || !actor.isAdmin) return const [];
  return priestsForAdmin(actor, priests);
});

final scopedMembersProvider = Provider<List<AppUser>>((ref) {
  final actor = ref.watch(authControllerProvider);
  final people = ref.watch(directoryProvider).value ?? const {};
  final priests = ref.watch(priestsProvider);
  if (actor == null || !actor.isAdmin) return const [];
  return accountsForAdmin(actor, people.values.toList(), priests);
});

final adminStatsProvider = Provider<AdminStats?>((ref) {
  final actor = ref.watch(authControllerProvider);
  if (actor == null || !actor.isAdmin) return null;
  final people = ref.watch(directoryProvider).value ?? const {};
  return buildAdminStats(
    actor: actor,
    users: people.values.toList(),
    appointments: ref.watch(allAppointmentsProvider),
    priests: ref.watch(priestsProvider),
    churches: ref.watch(churchesProvider),
  );
});
