import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/app_user.dart';
import 'seed_catalog.dart';
import 'tester_catalog.dart';

const testersAuthFlag = 'ghofran_testers_auth_v2';

Future<void> seedDebugTesters() async {
  if (!kDebugMode || Firebase.apps.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(testersAuthFlag) ?? false) return;

  try {
    final secondary = FirebaseAuth.instanceFor(app: await _secondaryApp());
    final auth = FirebaseAuth.instance;
    final store = FirebaseFirestore.instance;
    final world = TesterWorld();
    final uids = <String, String>{};

    for (final tester in TesterCatalog.logins) {
      await _ensureAuth(secondary, tester);
      if (!await _signIn(auth, tester)) continue;
      final uid = auth.currentUser?.uid;
      if (uid == null) continue;
      uids[tester.id] = uid;
      try {
        await _writeProfile(store, tester, uid);
      } catch (error) {
        debugPrint('Tester profile ${tester.email}: $error');
      }
    }

    if (uids[TesterCatalog.admin.id] != null &&
        await _signIn(auth, TesterCatalog.admin)) {
      try {
        await _writeCatalogAsAdmin(store, world, uids);
      } catch (error) {
        debugPrint('Tester catalog: $error');
      }
    }

    for (final tester in TesterCatalog.logins) {
      if (tester.role != UserRole.member) continue;
      if (uids[tester.id] == null || !await _signIn(auth, tester)) continue;
      try {
        await _writeMemberData(store, world, tester, uids[tester.id]!, uids);
      } catch (error) {
        debugPrint('Tester member ${tester.email}: $error');
      }
    }

    if (uids[TesterCatalog.youhanna.id] != null &&
        await _signIn(auth, TesterCatalog.youhanna)) {
      try {
        await _writePriestData(store, world, uids);
      } catch (error) {
        debugPrint('Tester priest data: $error');
      }
    }

    await auth.signOut();
    await secondary.signOut();
    if (uids.isNotEmpty) {
      await prefs.setBool(testersAuthFlag, true);
    }
  } catch (error) {
    debugPrint('Tester seed skipped: $error');
    await FirebaseAuth.instance.signOut();
  }
}

Future<FirebaseApp> _secondaryApp() async {
  const name = 'ghofranAdmin';
  for (final app in Firebase.apps) {
    if (app.name == name) return app;
  }
  return Firebase.initializeApp(name: name, options: Firebase.app().options);
}

Future<String?> _ensureAuth(FirebaseAuth auth, TesterAccount tester) async {
  try {
    final credential = await auth.createUserWithEmailAndPassword(
      email: tester.email,
      password: tester.password,
    );
    await credential.user?.updateDisplayName(tester.fullName);
    return credential.user?.uid;
  } on FirebaseAuthException catch (error) {
    if (error.code != 'email-already-in-use') {
      debugPrint('Tester ${tester.email}: ${error.code}');
      return null;
    }
    if (!await _signIn(auth, tester)) return null;
    return auth.currentUser?.uid;
  }
}

Future<bool> _signIn(FirebaseAuth auth, TesterAccount tester) async {
  try {
    await auth.signInWithEmailAndPassword(
      email: tester.email,
      password: tester.password,
    );
    return auth.currentUser != null;
  } on FirebaseAuthException catch (error) {
    debugPrint('Tester login ${tester.email}: ${error.code}');
    return false;
  }
}

Future<void> _writeProfile(
  FirebaseFirestore store,
  TesterAccount tester,
  String uid,
) async {
  await store.collection('users').doc(uid).set({
    ...tester.toUser().toJson(),
    'id': uid,
  }, SetOptions(merge: true));
  try {
    await store.collection('usernames').doc(tester.username.toLowerCase()).set({
      'uid': uid,
      'email': tester.email,
    });
  } catch (error) {
    debugPrint('Tester username ${tester.username}: $error');
  }
}

Future<void> _writeCatalogAsAdmin(
  FirebaseFirestore store,
  TesterWorld world,
  Map<String, String> uids,
) async {
  final batch = store.batch();
  for (final church in seedChurches) {
    batch.set(store.collection('churches').doc(church.id), church.toJson());
  }
  for (final priest in world.priests()) {
    final mappedUid = priest.uid == null ? null : uids[priest.uid!];
    batch.set(store.collection('priests').doc(priest.id), {
      ...priest.toJson(),
      if (mappedUid != null) 'uid': mappedUid,
    }, SetOptions(merge: true));
  }
  for (final appointment in world.appointments()) {
    final userId = uids[appointment.userId];
    if (userId == null) continue;
    batch.set(
      store.collection('appointments').doc(appointment.id),
      {
        ...appointment.toJson(),
        'userId': userId,
        'startsAt': Timestamp.fromDate(appointment.startsAt),
        'startsAtIso': appointment.startsAt.toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
  await batch.commit();
}

Future<void> _writeMemberData(
  FirebaseFirestore store,
  TesterWorld world,
  TesterAccount tester,
  String uid,
  Map<String, String> uids,
) async {
  final notes = world.notifications()[tester.id] ?? const [];
  for (final note in notes) {
    await store.collection('notifications').doc(note.id).set({
      'userId': uid,
      'title': note.title,
      'body': note.body,
      'createdAt': Timestamp.fromDate(note.createdAt),
      'read': note.read,
    });
  }

  for (final care in world.cares()) {
    if (care.userId != tester.id) continue;
    await store.collection('pastoral_care').doc(uid).set({
      ...care.toJson(),
      'userId': uid,
      'priestUid': uids[TesterCatalog.youhanna.id],
    }, SetOptions(merge: true));
  }
}

Future<void> _writePriestData(
  FirebaseFirestore store,
  TesterWorld world,
  Map<String, String> uids,
) async {
  final priestUid = uids[TesterCatalog.youhanna.id];
  if (priestUid == null) return;
  for (final canon in world.canons()) {
    final memberUid = uids[canon.userId];
    if (memberUid == null) continue;
    final ref = store.collection('spiritual_canons').doc(canon.id);
    if ((await ref.get()).exists) continue;
    await ref.set({
      ...canon.toJson(),
      'userId': memberUid,
      'priestUid': priestUid,
      'createdAt': Timestamp.fromDate(canon.createdAt),
    });
  }
}
