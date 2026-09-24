import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'seed_catalog.dart';

export 'seed_catalog.dart';

const _oldChurchNames = {
  'القاهرة',
  'الإسكندرية',
  'المنيا',
  'أسيوط',
  'طنطا',
};

Future<void> seedFirestoreIfNeeded() async {
  if (Firebase.apps.isEmpty) return;
  try {
    final store = FirebaseFirestore.instance;
    await _seedChurches(store);
    await _seedPriests(store);
  } catch (error) {
    debugPrint('Firestore seed skipped: $error');
  }
}

Future<void> _seedChurches(FirebaseFirestore store) async {
  final churchesSnap = await store.collection('churches').get();
  final existing = {for (final doc in churchesSnap.docs) doc.id: doc};
  final batch = store.batch();
  var writes = 0;
  for (final church in seedChurches) {
    final doc = existing[church.id];
    if (doc == null) {
      batch.set(store.collection('churches').doc(church.id), church.toJson());
      writes++;
      continue;
    }
    final data = doc.data();
    final address = data['address'] as String? ?? '';
    final name = data['name'] as String? ?? '';
    if (address.isEmpty || _oldChurchNames.contains(name)) {
      batch.set(doc.reference, church.toJson(), SetOptions(merge: true));
      writes++;
    }
  }
  if (writes > 0) await batch.commit();
}

Future<void> _seedPriests(FirebaseFirestore store) async {
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
  final byId = {for (final priest in seedPriests) priest.id: priest};
  for (final doc in priestsSnap.docs) {
    final data = doc.data();
    final seed = byId[doc.id];
    final updates = <String, Object>{};
    if ((data['churchId'] as String?)?.isEmpty ?? true) {
      final match = churchByName(data['churchName'] as String? ?? '');
      if (match != null) updates['churchId'] = match.id;
    }
    if (seed != null &&
        _oldChurchNames.contains(data['churchName'] as String? ?? '')) {
      updates['churchName'] = seed.churchName;
      updates['churchId'] = seed.churchId;
    }
    if (updates.isEmpty) continue;
    batch.update(doc.reference, updates);
    writes++;
  }
  if (writes > 0) await batch.commit();
}
