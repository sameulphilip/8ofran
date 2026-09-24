import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local_database.dart';

class AppLockStore {
  AppLockStore(this._prefs);

  final SharedPreferences _prefs;
  final _auth = LocalAuthentication();

  static const _enabledKey = 'app_lock_enabled';
  static const _pinHashKey = 'app_lock_pin_hash';
  static const _salt = 'ghofran_local_lock_v1';

  bool get isEnabled =>
      (_prefs.getBool(_enabledKey) ?? false) && pinHash != null;

  String? get pinHash => _prefs.getString(_pinHashKey);

  String hashPin(String pin) {
    final bytes = utf8.encode('$_salt:${pin.trim()}');
    return sha256.convert(bytes).toString();
  }

  bool verifyPin(String pin) {
    final saved = pinHash;
    if (saved == null) return false;
    return saved == hashPin(pin);
  }

  Future<void> enableWithPin(String pin) async {
    await _prefs.setString(_pinHashKey, hashPin(pin));
    await _prefs.setBool(_enabledKey, true);
  }

  Future<void> disable() async {
    await _prefs.setBool(_enabledKey, false);
    await _prefs.remove(_pinHashKey);
  }

  Future<bool> canUseBiometric() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometric({required String reason}) async {
    if (!await canUseBiometric()) return false;
    try {
      return _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final appLockStoreProvider = Provider<AppLockStore>((ref) {
  return AppLockStore(ref.watch(sharedPreferencesProvider));
});

class AppLockController extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(appLockStoreProvider);
    return !store.isEnabled;
  }

  void unlock() => state = true;

  void lock() {
    if (ref.read(appLockStoreProvider).isEnabled) {
      state = false;
    }
  }

  void refreshGate() {
    final store = ref.read(appLockStoreProvider);
    state = !store.isEnabled;
  }
}

final appLockUnlockedProvider =
    NotifierProvider<AppLockController, bool>(AppLockController.new);
