import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local_database.dart';

class ConscienceQuestion {
  const ConscienceQuestion({required this.id, required this.text});
  final String id;
  final String text;
}

class ConscienceLocalStore {
  ConscienceLocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'conscience_exam_local_only';

  static const questions = [
    ConscienceQuestion(
      id: 'prayer',
      text: 'هل أهملت الصلاة اليومية أو صلوات الأجبية بغير عذر؟',
    ),
    ConscienceQuestion(
      id: 'liturgy',
      text: 'هل تهاونت في حضور القداس بغير سبب ضروري؟',
    ),
    ConscienceQuestion(
      id: 'fasting',
      text: 'هل كسرت الأصوام الكنسية باستخفاف؟',
    ),
    ConscienceQuestion(id: 'anger', text: 'هل أسأت إلى أحد بغضب أو كلام جارح؟'),
    ConscienceQuestion(
      id: 'tongue',
      text: 'هل وقعت في نميمة أو دينونة أو كذب؟',
    ),
    ConscienceQuestion(id: 'envy', text: 'هل حسدت أحداً أو اشتهيت ما ليس لك؟'),
    ConscienceQuestion(
      id: 'family',
      text: 'هل قصّرت في محبة أهلك أو طاعة من يجب توقيرهم؟',
    ),
    ConscienceQuestion(
      id: 'mercy',
      text: 'هل تهاونت في أعمال الرحمة نحو المحتاج؟',
    ),
    ConscienceQuestion(
      id: 'thoughts',
      text: 'هل استسلمت لأفكار نجسة أو كرهت أحداً في قلبك؟',
    ),
    ConscienceQuestion(id: 'gratitude', text: 'هل نسيت الشكر لله على نعمه؟'),
  ];

  Map<String, bool> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in map.entries) e.key: e.value == true};
  }

  Future<void> save(Map<String, bool> answers) {
    return _prefs.setString(_key, jsonEncode(answers));
  }

  Future<void> clear() => _prefs.remove(_key);
}

final conscienceLocalStoreProvider = Provider<ConscienceLocalStore>((ref) {
  return ConscienceLocalStore(ref.watch(sharedPreferencesProvider));
});
