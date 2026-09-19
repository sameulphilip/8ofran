import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../features/priests/domain/priest.dart';

const seedPriests = [
  Priest(id: 'p_youhanna', name: 'أبونا يوحنا', churchName: 'القاهرة'),
  Priest(id: 'p_mina', name: 'أبونا مينا', churchName: 'الإسكندرية'),
  Priest(id: 'p_dawoud', name: 'أبونا داود', churchName: 'المنيا'),
  Priest(id: 'p_kirollos', name: 'أبونا كيرلس', churchName: 'أسيوط'),
  Priest(id: 'p_bishoy', name: 'أبونا بيشوي', churchName: 'طنطا'),
];

Future<void> seedFirestoreIfNeeded() async {
  if (Firebase.apps.isEmpty) return;
  try {
    final store = FirebaseFirestore.instance;
    final existing = await store.collection('priests').limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = store.batch();
    for (final priest in seedPriests) {
      batch.set(store.collection('priests').doc(priest.id), priest.toJson());
    }
    await batch.commit();
  } catch (error) {
    debugPrint('Firestore seed skipped: $error');
  }
}
