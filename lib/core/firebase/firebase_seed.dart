import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'seed_catalog.dart';

export 'seed_catalog.dart';

Future<void> seedFirestoreIfNeeded() async {
  if (Firebase.apps.isEmpty) return;
  try {
    final store = FirebaseFirestore.instance;
    final churchesSnap = await store.collection('churches').limit(1).get();
    if (churchesSnap.docs.isEmpty) {
      final batch = store.batch();
      for (final church in seedChurches) {
        batch.set(store.collection('churches').doc(church.id), church.toJson());
      }
      await batch.commit();
    }

    final priestsSnap = await store.collection('priests').get();
    if (priestsSnap.docs.isEmpty) {
      final batch = store.batch();
      for (final priest in seedPriests) {
        batch.set(store.collection('priests').doc(priest.id), priest.toJson());
      }
      await batch.commit();
      return;
    }

    final batch = store.batch();
    var writes = 0;
    for (final doc in priestsSnap.docs) {
      final data = doc.data();
      if ((data['churchId'] as String?)?.isNotEmpty ?? false) continue;
      final match = churchByName(data['churchName'] as String? ?? '');
      if (match == null) continue;
      batch.update(doc.reference, {'churchId': match.id});
      writes++;
    }
    if (writes > 0) await batch.commit();
  } catch (error) {
    debugPrint('Firestore seed skipped: $error');
  }
}
