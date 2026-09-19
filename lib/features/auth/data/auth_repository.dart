import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firebase_seed.dart';
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
      await _setPersistence(remember);
      final email = await _resolveEmail(identifier);
      try {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _ensureProfile(credential.user!);
      } on FirebaseAuthException catch (error) {
        throw AuthException(_mapAuthError(error));
      }
    }
    return _localLogin(identifier, password, remember);
  }

  Future<AppUser> signup({
    required String fullName,
    required String username,
    required String email,
    required String password,
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
          );
        } catch (error) {
          await credential.user?.delete();
          if (error is AuthException) rethrow;
          throw AuthException(_mapAuthError(
            error is FirebaseAuthException
                ? error
                : FirebaseAuthException(code: 'internal-error'),
          ));
        }
      } on FirebaseAuthException catch (error) {
        throw AuthException(_mapAuthError(error));
      }
    }
    return _localSignup(fullName, username, email, password);
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
      return _ensureProfile(user);
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

  Future<void> _setPersistence(bool remember) async {
    if (!kIsWeb || _auth == null) return;
    await _auth.setPersistence(
      remember ? Persistence.LOCAL : Persistence.SESSION,
    );
  }

  Future<String> _resolveEmail(String identifier) async {
    final query = identifier.trim();
    if (query.contains('@')) return query;
    final doc = await _store!.collection('usernames').doc(query.toLowerCase()).get();
    final email = doc.data()?['email'] as String?;
    if (!doc.exists || email == null) {
      throw const AuthException(AppStrings.loginFailed);
    }
    return email;
  }

  Future<AppUser?> _profileFor(User? firebaseUser) async {
    if (firebaseUser == null) return null;
    return _ensureProfile(firebaseUser);
  }

  Future<AppUser> _ensureProfile(User firebaseUser) async {
    final store = _store;
    if (store == null) {
      throw const AuthException(AppStrings.firebaseNotReady);
    }
    final doc = await store.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      await seedFirestoreIfNeeded();
      return AppUser.fromJson({
        ...doc.data()!,
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? doc.data()!['email'],
      });
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
    return created;
  }

  Future<AppUser> _writeProfile({
    required String uid,
    required String fullName,
    required String username,
    required String email,
  }) async {
    final user = AppUser(
      id: uid,
      fullName: fullName,
      username: username,
      email: email,
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
    return user;
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
    return user;
  }

  Future<AppUser> _localSignup(
    String fullName,
    String username,
    String email,
    String password,
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
      'operation-not-allowed' || 'unauthorized-domain' =>
        AppStrings.firebaseNotReady,
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
