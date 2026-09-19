import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/appointments/domain/appointment.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/priests/domain/priest.dart';
import '../constants/app_constants.dart';
import '../utils/slot_id.dart';

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

  Future<void> seedIfNeeded() async {
    if (_prefs.getBool(_seededKey) ?? false) return;

    final priests = [
      const Priest(id: 'p_youhanna', name: 'أبونا يوحنا', churchName: 'القاهرة'),
      const Priest(id: 'p_mina', name: 'أبونا مينا', churchName: 'الإسكندرية'),
      const Priest(id: 'p_dawoud', name: 'أبونا داود', churchName: 'المنيا'),
      const Priest(id: 'p_kirollos', name: 'أبونا كيرلس', churchName: 'أسيوط'),
      const Priest(id: 'p_bishoy', name: 'أبونا بيشوي', churchName: 'طنطا'),
    ];

    final demoUser = AppUser(
      id: 'u_ramzi',
      fullName: 'رمزى مكرم',
      username: AppConstants.demoUsername,
      email: 'ramzi@ghofran.app',
      password: AppConstants.demoPassword,
    );

    final upcoming = _nextSaturdayAt(17, 0);
    final appointment = Appointment(
      id: SlotId.build(
        priestId: 'p_youhanna',
        date: upcoming,
        time: TimeOfDayLike.fromDateTime(upcoming),
      ),
      userId: demoUser.id,
      priestId: 'p_youhanna',
      startsAt: upcoming,
      status: AppointmentStatus.confirmed,
    );

    final notifications = [
      AppNotification(
        id: 'n1',
        title: 'تأكيد الموعد',
        body: 'تم تأكيد موعدك مع أبونا يوحنا.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n2',
        title: 'تذكير',
        body: 'موعدك بعد 24 ساعة. خذ وقتك.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        read: true,
      ),
    ];

    await _writeJson(_usersKey, [demoUser.toLocalJson()]);
    await _writeJson(_priestsKey, priests.map((p) => p.toJson()).toList());
    await _writeJson(_appointmentsKey, [appointment.toJson()]);
    await _writeJson(
      '${_notificationsKey}_${demoUser.id}',
      notifications.map((n) => n.toJson()).toList(),
    );
    await _prefs.setBool(_seededKey, true);
  }

  List<AppUser> users() => _readList(_usersKey, AppUser.fromJson);

  Future<void> saveUsers(List<AppUser> value) {
    return _writeJson(_usersKey, value.map((e) => e.toLocalJson()).toList());
  }

  List<Priest> priests() => _readList(_priestsKey, Priest.fromJson);

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

  static DateTime _nextSaturdayAt(int hour, int minute) {
    var date = DateTime.now().add(const Duration(days: 1));
    while (date.weekday != DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase(ref.watch(sharedPreferencesProvider));
});
