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
  static const _testersKey = 'seeded_testers_v2';
  static const _remindersKey = 'reminders_enabled';

  Future<void> seedIfNeeded() async {
    if (!(_prefs.getBool(_seededKey) ?? false)) {
      final world = TesterWorld();
      await _writeJson(
        _usersKey,
        world.users().map((user) => user.toLocalJson()).toList(),
      );
      await _writeJson(
        _priestsKey,
        world.priests().map((priest) => priest.toJson()).toList(),
      );
      await _writeJson(
        _churchesKey,
        seedChurches.map((church) => church.toJson()).toList(),
      );
      await _writeJson(
        _appointmentsKey,
        world.appointments().map((item) => item.toJson()).toList(),
      );
      await saveCares(world.cares());
      await saveCanons(world.canons());
      for (final entry in world.notifications().entries) {
        await _writeJson(
          '${_notificationsKey}_${entry.key}',
          entry.value.map((item) => item.toJson()).toList(),
        );
      }
      await _prefs.setBool(_seededKey, true);
      await _prefs.setBool(_testersKey, true);
    }
    await _ensureTestersCatalog();
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

  Future<void> _ensureTestersCatalog() async {
    if (churches().isEmpty) {
      await saveChurches(seedChurches);
    }
    if (_prefs.getBool(_testersKey) ?? false) return;
    final world = TesterWorld();
    final known = {for (final user in users()) user.email.toLowerCase(): user};
    var usersChanged = false;
    for (final tester in TesterCatalog.logins) {
      final fresh = tester.toUser();
      final existing = known[tester.email.toLowerCase()];
      if (existing == null) {
        known[tester.email.toLowerCase()] = fresh;
        usersChanged = true;
        continue;
      }
      if (existing.fatherId != fresh.fatherId ||
          existing.priestId != fresh.priestId ||
          existing.role != fresh.role) {
        known[tester.email.toLowerCase()] = existing.copyWith(
          role: fresh.role,
          priestId: fresh.priestId,
          fatherId: fresh.fatherId,
        );
        usersChanged = true;
      }
    }
    if (usersChanged) await saveUsers(known.values.toList());
    if (priests().isEmpty) await savePriests(world.priests());
    if (appointments().isEmpty) await saveAppointments(world.appointments());
    if (cares().isEmpty) await saveCares(world.cares());
    if (canons().isEmpty) await saveCanons(world.canons());
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
