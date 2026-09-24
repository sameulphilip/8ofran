import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tester_catalog.dart';

const testersAuthFlag = 'ghofran_testers_purged_v1';
const accountsReadyFlag = 'ghofran_accounts_ready_v2';

Future<void> seedDebugTesters() async {
  if (!kDebugMode || Firebase.apps.isEmpty) return;
  try {
    await _seedAccounts().timeout(const Duration(seconds: 12));
  } catch (error) {
    debugPrint('Debug seed skipped: $error');
  } finally {
    await FirebaseAuth.instance.signOut();
  }
}

Future<void> _seedAccounts() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(accountsReadyFlag) ?? false) return;
  await _purgeDisposableTesters();
  await _ensureAccount(TesterCatalog.admin);
  await _ensureAccount(TesterCatalog.member);
  await _ensureAccount(TesterCatalog.priest);
  await prefs.setBool(accountsReadyFlag, true);
}

Future<void> _purgeDisposableTesters() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(testersAuthFlag) ?? false) return;

  try {
    final secondary = FirebaseAuth.instanceFor(app: await _secondaryApp());
    final auth = FirebaseAuth.instance;
    final store = FirebaseFirestore.instance;
    final uids = <String>{};

    for (final tester in TesterCatalog.disposable) {
      if (!await _signIn(auth, tester)) continue;
      final uid = auth.currentUser?.uid;
      if (uid != null) uids.add(uid);
    }

    if (await _signIn(auth, TesterCatalog.admin)) {
      await _deleteFirestore(store, uids);
    }

    for (final tester in TesterCatalog.disposable) {
      if (!await _signIn(secondary, tester)) continue;
      try {
        await secondary.currentUser?.delete();
      } catch (error) {
        debugPrint('Tester auth delete ${tester.email}: $error');
        await secondary.signOut();
      }
    }

    await auth.signOut();
    await secondary.signOut();
    await prefs.setBool(testersAuthFlag, true);
  } catch (error) {
    debugPrint('Tester purge skipped: $error');
    await FirebaseAuth.instance.signOut();
  }
}

Future<void> _ensureAccount(TesterAccount account) async {
  final secondary = FirebaseAuth.instanceFor(app: await _secondaryApp());
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  try {
    try {
      await secondary.createUserWithEmailAndPassword(
        email: account.email,
        password: account.password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        debugPrint('${account.email} auth ${error.code}');
      }
    }
    if (!await _signIn(auth, account)) return;
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await store.collection('users').doc(uid).set({
      ...account.toUser().toJson(),
      'id': uid,
    }, SetOptions(merge: true));
    await store.collection('usernames').doc(account.username.toLowerCase()).set({
      'uid': uid,
      'email': account.email,
    }, SetOptions(merge: true));
  } catch (error) {
    debugPrint('${account.email} ensure skipped: $error');
  } finally {
    await auth.signOut();
    await secondary.signOut();
  }
}

Future<void> _deleteFirestore(FirebaseFirestore store, Set<String> uids) async {
  for (final tester in TesterCatalog.disposable) {
    try {
      await store.collection('usernames').doc(tester.username.toLowerCase()).delete();
    } catch (error) {
      debugPrint('Tester username ${tester.username}: $error');
    }
    final byEmail = await store
        .collection('users')
        .where('email', isEqualTo: tester.email)
        .get();
    for (final doc in byEmail.docs) {
      uids.add(doc.id);
    }
  }

  for (final uid in uids) {
    await _deleteQuery(store.collection('appointments').where('userId', isEqualTo: uid));
    await _deleteQuery(
      store.collection('notifications').where('userId', isEqualTo: uid),
    );
    await _deleteQuery(
      store.collection('spiritual_canons').where('userId', isEqualTo: uid),
    );
    await _deleteQuery(
      store.collection('spiritual_canons').where('priestUid', isEqualTo: uid),
    );
    try {
      await store.collection('pastoral_care').doc(uid).delete();
    } catch (error) {
      debugPrint('Tester care $uid: $error');
    }
    try {
      await store.collection('users').doc(uid).delete();
    } catch (error) {
      debugPrint('Tester user $uid: $error');
    }
  }

  final priests = await store.collection('priests').get();
  for (final doc in priests.docs) {
    final uid = doc.data()['uid'] as String?;
    if (uid == null || !uids.contains(uid)) continue;
    await doc.reference.update({'uid': FieldValue.delete()});
  }
}

Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
  final snap = await query.get();
  for (final doc in snap.docs) {
    await doc.reference.delete();
  }
}

Future<FirebaseApp> _secondaryApp() async {
  const name = 'ghofranAdmin';
  for (final app in Firebase.apps) {
    if (app.name == name) return app;
  }
  return Firebase.initializeApp(name: name, options: Firebase.app().options);
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
