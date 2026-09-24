import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local_database.dart';

class PrepareStep {
  const PrepareStep({required this.id, required this.text});
  final String id;
  final String text;
}

class PrepareLocalStore {
  PrepareLocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'prepare_visit_local_only';

  static const steps = [
    PrepareStep(id: 'silence', text: 'صمت قصير بعيدًا عن الهاتف'),
    PrepareStep(id: 'psalm', text: 'قراءة مزمور أو نص تأملي بهدوء'),
    PrepareStep(id: 'exam', text: 'فحص ذاتي على الجهاز فقط'),
    PrepareStep(id: 'forgive', text: 'نية مصالحة إن كان هناك جفاء'),
    PrepareStep(id: 'arrive', text: 'الوصول مبكرًا بهدوء دون استعجال'),
  ];

  Map<String, bool> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in map.entries) e.key: e.value == true};
  }

  Future<void> save(Map<String, bool> checks) {
    return _prefs.setString(_key, jsonEncode(checks));
  }

  Future<void> clear() => _prefs.remove(_key);
}

final prepareLocalStoreProvider = Provider<PrepareLocalStore>((ref) {
  return PrepareLocalStore(ref.watch(sharedPreferencesProvider));
});
