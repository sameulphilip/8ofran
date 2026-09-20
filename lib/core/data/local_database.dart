import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admin/domain/church.dart';
import '../../features/appointments/domain/appointment.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/care/domain/pastoral_care.dart';
import '../../features/care/domain/spiritual_canon.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/priests/domain/priest.dart';
import '../firebase/seed_catalog.dart';
import '../firebase/tester_catalog.dart';

class LocalDatabase {
  LocalDatabase(this._prefs);

  final SharedPreferences _prefs;

  static const _usersKey = 'users';
  static const _priestsKey = 'priests';
  static const _appointmentsKey = 'appointments';
  static const _notificationsKey = 'notifications';
  static const _sessionKey = 'session_user_id';
  static const _rememberKey = 'remember_me';
  static const _seededKey = 'seeded_ui_navy_v1';
  static const _churchesKey = 'churches';
  static const _careKey = 'pastoral_care';
  static const _canonsKey = 'spiritual_canons';
  static const _testersKey = 'seeded_testers_v3';
  static const _remindersKey = 'reminders_enabled';

  Future<void> seedIfNeeded() async {
    if (!(_prefs.getBool(_seededKey) ?? false)) {
      await saveUsers([
        TesterCatalog.admin.toUser(),
        TesterCatalog.member.toUser(),
      ]);
      await savePriests(seedPriests);
      await saveChurches(seedChurches);
      await saveAppointments(const []);
      await saveCares(const []);
      await saveCanons(const []);
      await _prefs.setBool(_seededKey, true);
      await _prefs.setBool(_testersKey, true);
    }
    await _purgeLocalTesters();
  }

  List<AppUser> users() => _readList(_usersKey, AppUser.fromJson);

  Future<void> saveUsers(List<AppUser> value) {
    return _writeJson(_usersKey, value.map((e) => e.toLocalJson()).toList());
  }

  List<Priest> priests() => _readList(_priestsKey, Priest.fromJson);

  Future<void> savePriests(List<Priest> value) {
    return _writeJson(_priestsKey, value.map((e) => e.toJson()).toList());
  }

  List<Church> churches() => _readList(_churchesKey, Church.fromJson);

  Future<void> saveChurches(List<Church> value) {
    return _writeJson(_churchesKey, value.map((e) => e.toJson()).toList());
  }

  List<Appointment> appointments() =>
      _readList(_appointmentsKey, Appointment.fromJson);

  Future<void> saveAppointments(List<Appointment> value) {
    return _writeJson(_appointmentsKey, value.map((e) => e.toJson()).toList());
  }

  List<AppNotification> notificationsFor(String userId) {
    return _readList('${_notificationsKey}_$userId', AppNotification.fromJson);
  }

  Future<void> saveNotifications(String userId, List<AppNotification> value) {
    return _writeJson(
      '${_notificationsKey}_$userId',
      value.map((e) => e.toJson()).toList(),
    );
  }

  String? sessionUserId() => _prefs.getString(_sessionKey);

  Future<void> setSession(String? userId, {required bool remember}) async {
    if (userId == null) {
      await _prefs.remove(_sessionKey);
    } else {
      await _prefs.setString(_sessionKey, userId);
    }
    await _prefs.setBool(_rememberKey, remember);
  }

  bool rememberMe() => _prefs.getBool(_rememberKey) ?? false;

  bool remindersEnabled() => _prefs.getBool(_remindersKey) ?? true;

  Future<void> setRemindersEnabled(bool value) {
    return _prefs.setBool(_remindersKey, value);
  }

  List<PastoralCare> cares() => _readList(_careKey, PastoralCare.fromJson);

  Future<void> saveCares(List<PastoralCare> value) {
    return _writeJson(_careKey, value.map((item) => item.toJson()).toList());
  }

  List<SpiritualCanon> canons() {
    return _readList(_canonsKey, (json) {
      return SpiritualCanon.fromJson({
        ...json,
        'id': json['id'] as String? ?? 'canon_${json['userId']}',
      });
    });
  }

  Future<void> saveCanons(List<SpiritualCanon> value) {
    return _writeJson(_canonsKey, [
      for (final item in value) {'id': item.id, ...item.toJson()},
    ]);
  }

  Future<void> _purgeLocalTesters() async {
    if (churches().isEmpty) {
      await saveChurches(seedChurches);
    }
    if (priests().isEmpty) await savePriests(seedPriests);
    final kept = [
      for (final user in users())
        if (!TesterCatalog.isDisposableEmail(user.email)) user,
    ];
    if (!kept.any(
      (user) => user.email.toLowerCase() == TesterCatalog.member.email,
    )) {
      kept.add(TesterCatalog.member.toUser());
    }
    if (kept.length != users().length) {
      await saveUsers(kept);
    }
    final session = sessionUserId();
    if (session != null && !kept.any((user) => user.id == session)) {
      await setSession(null, remember: false);
    }
    await _prefs.setBool(_testersKey, true);
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list) fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _writeJson(String key, Object value) {
    return _prefs.setString(key, jsonEncode(value));
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase(ref.watch(sharedPreferencesProvider));
});
