import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

Future<void> initFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase init pending: $error');
  }
}
