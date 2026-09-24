import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firebase_seed.dart';
import '../../../core/firebase/tester_catalog.dart';
import '../../priests/domain/priest.dart';
import '../domain/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class AuthRepository {
  AuthRepository(this._db, this._auth, this._store);

  final LocalDatabase _db;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _store;

  bool get _cloud => _auth != null && _store != null;

  Stream<AppUser?> authState() {
    if (!_cloud) {
      return Stream<AppUser?>.value(currentUser());
    }
    return _auth!.authStateChanges().asyncMap(_profileFor);
  }

  AppUser? currentUser() {
    if (_cloud) {
      final firebaseUser = _auth!.currentUser;
      if (firebaseUser == null) return null;
      return AppUser(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? '',
        username: firebaseUser.email?.split('@').first ?? '',
        email: firebaseUser.email ?? '',
      );
    }
    final id = _db.sessionUserId();
    if (id == null) return null;
    return _findLocal(id);
  }

  Future<AppUser> login({
    required String identifier,
    required String password,
    required bool remember,
  }) async {
    if (_cloud) {
      try {
        await _setPersistence(remember).timeout(const Duration(seconds: 3));
      } catch (_) {
        // Safari/iOS can hang on persistence changes — continue with default.
      }
      try {
        final email = await _resolveEmail(identifier)
            .timeout(const Duration(seconds: 8));
        final credential = await _auth!
            .signInWithEmailAndPassword(
              email: email,
              password: password,
            )
            .timeout(const Duration(seconds: 15));
        final profile = await _ensureProfile(credential.user!)
            .timeout(const Duration(seconds: 15));
        return _guardActive(profile);
      } on TimeoutException {
        throw const AuthException(AppStrings.loginTimeout);
      } on FirebaseAuthException catch (error) {
        throw AuthException(_mapAuthError(error));
      } on AuthException {
        rethrow;
      } catch (_) {
        throw const AuthException(AppStrings.loginTimeout);
      }
    }
    return _guardActive(await _localLogin(identifier, password, remember));
  }

  Future<AppUser> signup({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? fatherId,
  }) async {
    if (_cloud) {
      final name = username.trim().toLowerCase();
      final mail = email.trim().toLowerCase();
      final taken = await _store!.collection('usernames').doc(name).get();
      if (taken.exists) {
        throw const AuthException(AppStrings.usernameTaken);
      }
      try {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: mail,
          password: password,
        );
        await credential.user!.updateDisplayName(fullName.trim());
        try {
          return await _writeProfile(
            uid: credential.user!.uid,
            fullName: fullName.trim(),
            username: username.trim(),
            email: mail,
            fatherId: fatherId,
          );
        } catch (error) {
          await credential.user?.delete();
          if (error is AuthException) rethrow;
          throw AuthException(
            _mapAuthError(
              error is FirebaseAuthException
                  ? error
                  : FirebaseAuthException(code: 'internal-error'),
            ),
          );
        }
      } on FirebaseAuthException catch (error) {
        throw AuthException(_mapAuthError(error));
      }
    }
    return _localSignup(fullName, username, email, password, fatherId);
  }

  Future<AppUser?> reload() async {
    if (_cloud) return _profileFor(_auth!.currentUser);
    return currentUser();
  }

  Future<void> writeFatherId(String userId, String fatherId) async {
    final id = fatherId.trim();
    if (id.isEmpty) {
      throw const AuthException(AppStrings.chooseFatherError);
    }
    if (_cloud) {
      await _store!.collection('users').doc(userId).set({
        'fatherId': id,
      }, SetOptions(merge: true));
      return;
    }
    await _db.saveUsers([
      for (final user in _db.users())
        if (user.id == userId) user.copyWith(fatherId: id) else user,
    ]);
  }

  Future<void> clearFatherId(String userId) async {
    if (_cloud) {
      await _store!.collection('users').doc(userId).set({
        'fatherId': FieldValue.delete(),
      }, SetOptions(merge: true));
      return;
    }
    await _db.saveUsers([
      for (final user in _db.users())
        if (user.id == userId) user.copyWith(clearFather: true) else user,
    ]);
  }

  Future<void> setSuspended(String userId, bool suspended) async {
    if (_cloud) {
      await _store!.collection('users').doc(userId).set({
        if (suspended) 'isSuspended': true else 'isSuspended': FieldValue.delete(),
      }, SetOptions(merge: true));
      return;
    }
    await _db.saveUsers([
      for (final user in _db.users())
        if (user.id == userId)
          user.copyWith(isSuspended: suspended)
        else
          user,
    ]);
  }

  Future<AppUser> setFather(String fatherId) async {
    final id = fatherId.trim();
    if (id.isEmpty) {
      throw const AuthException(AppStrings.chooseFatherError);
    }
    if (_cloud) {
      final firebaseUser = _auth!.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(AppStrings.loginFailed);
      }
      final current = await _ensureProfile(firebaseUser);
      final updated = current.copyWith(fatherId: id);
      await _store!.collection('users').doc(current.id).set({
        'fatherId': id,
      }, SetOptions(merge: true));
      return updated;
    }
    final user = currentUser();
    if (user == null) {
      throw const AuthException(AppStrings.loginFailed);
    }
    final updated = user.copyWith(fatherId: id);
    await _db.saveUsers([
      for (final item in _db.users())
        if (item.id == user.id) updated else item,
    ]);
    return updated;
  }

  Future<AppUser> loginWithGoogle() async {
    if (!_cloud) {
      throw const AuthException(AppStrings.firebaseNotReady);
    }
    try {
      final provider = GoogleAuthProvider();
      final credential = kIsWeb
          ? await _auth!.signInWithPopup(provider)
          : await _auth!.signInWithProvider(provider);
      final user = credential.user;
      if (user == null) {
        throw const AuthException(AppStrings.googleMockNotice);
      }
      return _guardActive(await _ensureProfile(user));
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapAuthError(error));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_cloud) {
      throw const AuthException(AppStrings.firebaseNotReady);
    }
    try {
      await _auth!.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapAuthError(error));
    }
  }

  Future<void> logout() async {
    if (_cloud) {
      await _auth!.signOut();
    }
    await _db.setSession(null, remember: false);
  }

  Future<String> createUserAsAdmin({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? priestId,
    String? churchId,
  }) async {
    final mail = email.trim().toLowerCase();
    if (!_cloud) {
      final users = _db.users();
      if (users.any((user) => user.email.toLowerCase() == mail)) {
        throw const AuthException(AppStrings.emailTaken);
      }
      var username = mail.split('@').first;
      if (users.any((user) => user.username.toLowerCase() == username)) {
        username = '${username}_${DateTime.now().millisecondsSinceEpoch}';
      }
      final user = AppUser(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName.trim(),
        username: username,
        email: mail,
        password: password,
        role: role,
        priestId: priestId,
        churchId: churchId,
      );
      await _db.saveUsers([...users, user]);
      return user.id;
    }
    final app = await _secondaryApp();
    final secondary = FirebaseAuth.instanceFor(app: app);
    try {
      final credential = await secondary.createUserWithEmailAndPassword(
        email: mail,
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName.trim());
      try {
        var username = mail.split('@').first;
        if (username.isEmpty) username = uid.substring(0, 8);
        final taken = await _store!
            .collection('usernames')
            .doc(username.toLowerCase())
            .get();
        if (taken.exists && taken.data()?['uid'] != uid) {
          username = '${username}_${uid.substring(0, 6)}';
        }
        final user = AppUser(
          id: uid,
          fullName: fullName.trim(),
          username: username,
          email: mail,
          role: role,
          priestId: priestId,
          churchId: churchId,
        );
        await _store.collection('users').doc(uid).set(user.toJson());
        await _store.collection('usernames').doc(username.toLowerCase()).set({
          'uid': uid,
          'email': mail,
        });
      } catch (error) {
        await credential.user?.delete();
        await secondary.signOut();
        rethrow;
      }
      await secondary.signOut();
      return uid;
    } on FirebaseAuthException catch (error) {
      await secondary.signOut();
      throw AuthException(_mapAuthError(error));
    }
  }

  Future<FirebaseApp> _secondaryApp() async {
    const name = 'ghofranAdmin';
    for (final app in Firebase.apps) {
      if (app.name == name) return app;
    }
    return Firebase.initializeApp(name: name, options: Firebase.app().options);
  }

  Future<void> _setPersistence(bool remember) async {
    if (!kIsWeb || _auth == null) return;
    // SESSION hangs on many iOS Safari builds — always use LOCAL on web.
    await _auth.setPersistence(Persistence.LOCAL);
  }

  Future<String> _resolveEmail(String identifier) async {
    final query = identifier.trim();
    if (query.contains('@')) return query.toLowerCase();
    final key = query.toLowerCase();
    const aliases = {
      'user': 'user@ghofran.app',
      'admin': AppConstants.adminEmail,
      'youhanna': 'youhanna@ghofran.app',
    };
    final aliased = aliases[key];
    if (aliased != null) return aliased;
    if (key == TesterCatalog.member.username) return TesterCatalog.member.email;
    if (key == TesterCatalog.priest.username) return TesterCatalog.priest.email;
    if (key == TesterCatalog.admin.username) return TesterCatalog.admin.email;

    final doc = await _store!
        .collection('usernames')
        .doc(key)
        .get()
        .timeout(const Duration(seconds: 6));
    final email = doc.data()?['email'] as String?;
    if (!doc.exists || email == null) {
      throw const AuthException(AppStrings.loginFailed);
    }
    return email;
  }

  Future<AppUser?> _profileFor(User? firebaseUser) async {
    if (firebaseUser == null) return null;
    final user = await _ensureProfile(firebaseUser);
    if (user.isSuspended) {
      await logout();
      return null;
    }
    return user;
  }

  Future<AppUser> _ensureProfile(User firebaseUser) async {
    final store = _store;
    if (store == null) {
      throw const AuthException(AppStrings.firebaseNotReady);
    }
    final doc = await store.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      // Don't block login on catalog seed (can stall on slow mobile networks).
      unawaited(seedFirestoreIfNeeded());
      final user = AppUser.fromJson({
        ...doc.data()!,
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? doc.data()!['email'],
      });
      return _linkRoles(user);
    }
    final email = firebaseUser.email ?? '';
    var username = email.split('@').first;
    if (username.isEmpty) username = firebaseUser.uid.substring(0, 8);
    final taken = await store
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    if (taken.exists && taken.data()?['uid'] != firebaseUser.uid) {
      username = '${username}_${firebaseUser.uid.substring(0, 6)}';
    }
    final created = await _writeProfile(
      uid: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? username,
      username: username,
      email: email,
    );
    await seedFirestoreIfNeeded();
    return _linkRoles(created);
  }

  Future<AppUser> _linkRoles(AppUser user) async {
    final asAdmin = await _linkAdmin(user);
    if (asAdmin.isAdmin) return asAdmin;
    return _linkPriest(asAdmin);
  }

  Future<AppUser> _linkAdmin(AppUser user) async {
    final store = _store;
    if (store == null || user.isAdmin || !isSeedAdminEmail(user.email)) {
      return user;
    }
    final linked = AppUser(
      id: user.id,
      fullName: user.fullName,
      username: user.username,
      email: user.email,
      role: UserRole.admin,
    );
    await store.collection('users').doc(user.id).set({
      ...linked.toJson(),
      'churchId': FieldValue.delete(),
    }, SetOptions(merge: true));
    return linked;
  }

  Future<AppUser> _linkPriest(AppUser user) async {
    final store = _store;
    if (store == null || user.isAdmin) return user;
    unawaited(seedFirestoreIfNeeded());
    var match = priestByEmail(user.email);
    if (match == null) {
      try {
        final snap = await store
            .collection('priests')
            .where('email', isEqualTo: user.email.trim().toLowerCase())
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 6));
        if (snap.docs.isNotEmpty) {
          match = Priest.fromJson({
            'id': snap.docs.first.id,
            ...snap.docs.first.data(),
          });
        }
      } catch (_) {
        return user;
      }
    }
    if (match == null) return user;
    final linked = AppUser(
      id: user.id,
      fullName: user.fullName,
      username: user.username,
      email: user.email,
      role: UserRole.priest,
      priestId: match.id,
    );
    await store
        .collection('users')
        .doc(user.id)
        .set(linked.toJson(), SetOptions(merge: true));
    await store.collection('priests').doc(match.id).set({
      'uid': user.id,
      'email': match.email,
    }, SetOptions(merge: true));
    return linked;
  }

  Future<AppUser> _writeProfile({
    required String uid,
    required String fullName,
    required String username,
    required String email,
    String? fatherId,
  }) async {
    final user = AppUser(
      id: uid,
      fullName: fullName,
      username: username,
      email: email,
      fatherId: fatherId,
    );
    final store = _store;
    if (store == null) {
      throw const AuthException(AppStrings.firebaseNotReady);
    }
    await store.collection('users').doc(uid).set(user.toJson());
    await store.collection('usernames').doc(username.toLowerCase()).set({
      'uid': uid,
      'email': email,
    });
    return _linkRoles(user);
  }

  Future<AppUser> _localLogin(
    String identifier,
    String password,
    bool remember,
  ) async {
    final query = identifier.trim();
    final user = _db.users().cast<AppUser?>().firstWhere(
      (item) =>
          item!.username == query ||
          item.email.toLowerCase() == query.toLowerCase(),
      orElse: () => null,
    );
    if (user == null || user.password != password) {
      throw const AuthException(AppStrings.loginFailed);
    }
    await _db.setSession(user.id, remember: remember);
    return _guardActive(user);
  }

  Future<AppUser> _guardActive(AppUser user) async {
    if (!user.isSuspended) return user;
    await logout();
    throw const AuthException(AppStrings.suspendedBody);
  }

  Future<AppUser> _localSignup(
    String fullName,
    String username,
    String email,
    String password,
    String? fatherId,
  ) async {
    final users = _db.users();
    if (users.any((u) => u.username == username.trim())) {
      throw const AuthException(AppStrings.usernameTaken);
    }
    if (users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException(AppStrings.emailTaken);
    }
    final user = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      username: username.trim(),
      email: email.trim(),
      password: password,
      role: isSeedAdminEmail(email) ? UserRole.admin : UserRole.member,
      fatherId: fatherId,
    );
    await _db.saveUsers([...users, user]);
    await _db.setSession(user.id, remember: true);
    return user;
  }

  AppUser? _findLocal(String id) {
    return _db.users().cast<AppUser?>().firstWhere(
      (u) => u!.id == id,
      orElse: () => null,
    );
  }

  String _mapAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-email' => AppStrings.loginFailed,
      'email-already-in-use' => AppStrings.emailTaken,
      'weak-password' => AppStrings.shortPassword,
      'network-request-failed' => AppStrings.noConnection,
      'too-many-requests' => AppStrings.noConnection,
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'web-context-cancelled' => AppStrings.googleMockNotice,
      'operation-not-allowed' ||
      'unauthorized-domain' => AppStrings.firebaseNotReady,
      _ => error.message ?? AppStrings.loginFailed,
    };
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});
