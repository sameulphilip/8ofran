import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get isFirebaseReady => Firebase.apps.isNotEmpty;

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (!isFirebaseReady) return null;
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (!isFirebaseReady) return null;
  return FirebaseFirestore.instance;
});
