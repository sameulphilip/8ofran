import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local_database.dart';
import '../domain/church_calendar.dart';

class ConscienceQuestion {
  const ConscienceQuestion({
    required this.id,
    required this.text,
    this.seasonal = false,
  });
  final String id;
  final String text;
  final bool seasonal;
}

class ConscienceSnapshot {
  const ConscienceSnapshot({
    required this.answers,
    this.notes = '',
  });

  final Map<String, bool> answers;
  final String notes;
}

class ConscienceLocalStore {
  ConscienceLocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'conscience_exam_local_only_v2';
  static const _legacyKey = 'conscience_exam_local_only';

  static const baseQuestions = [
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

  static const lentQuestions = [
    ConscienceQuestion(
      id: 'lent_food',
      text: 'هل حفظت الصوم بروح التوبة لا بالمظهر فقط؟',
      seasonal: true,
    ),
    ConscienceQuestion(
      id: 'lent_silence',
      text: 'هل خصصت وقتًا يوميًا للصمت والقراءة الروحية؟',
      seasonal: true,
    ),
    ConscienceQuestion(
      id: 'lent_forgive',
      text: 'هل سعيت للمصالحة مع من بينك وبينه جفاء؟',
      seasonal: true,
    ),
  ];

  static const nativityQuestions = [
    ConscienceQuestion(
      id: 'nativity_hope',
      text: 'هل انتظرت عيد الميلاد برجاء أم بانشغال العالم فقط؟',
      seasonal: true,
    ),
    ConscienceQuestion(
      id: 'nativity_give',
      text: 'هل شاركت بفرح أو عطية بسيطة مع محتاج؟',
      seasonal: true,
    ),
  ];

  static List<ConscienceQuestion> questionsFor([DateTime? now]) {
    final season = ChurchCalendar.seasonFor(now ?? DateTime.now()).season;
    return [
      ...baseQuestions,
      if (season == ChurchSeason.greatLent || season == ChurchSeason.holyWeek)
        ...lentQuestions,
      if (season == ChurchSeason.nativityFast ||
          season == ChurchSeason.nativity)
        ...nativityQuestions,
    ];
  }

  ConscienceSnapshot load() {
    final raw = _prefs.getString(_key) ?? _prefs.getString(_legacyKey);
    if (raw == null) return const ConscienceSnapshot(answers: {});
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map.containsKey('answers')) {
      final answers = map['answers'] as Map<String, dynamic>? ?? {};
      return ConscienceSnapshot(
        answers: {for (final e in answers.entries) e.key: e.value == true},
        notes: map['notes'] as String? ?? '',
      );
    }
    return ConscienceSnapshot(
      answers: {for (final e in map.entries) e.key: e.value == true},
    );
  }

  Future<void> save(ConscienceSnapshot snapshot) {
    return _prefs.setString(
      _key,
      jsonEncode({
        'answers': snapshot.answers,
        'notes': snapshot.notes,
      }),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_legacyKey);
  }

  String exportText({DateTime? now}) {
    final snapshot = load();
    final questions = questionsFor(now);
    final buffer = StringBuffer()
      ..writeln('فحص ذاتي — غفران (محلي فقط)')
      ..writeln('لا يُرفع هذا النص لأي خادم.')
      ..writeln();
    for (final question in questions) {
      final yes = snapshot.answers[question.id] == true;
      buffer.writeln('${yes ? '[x]' : '[ ]'} ${question.text}');
    }
    if (snapshot.notes.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('ملاحظات:')
        ..writeln(snapshot.notes.trim());
    }
    return buffer.toString();
  }
}

final conscienceLocalStoreProvider = Provider<ConscienceLocalStore>((ref) {
  return ConscienceLocalStore(ref.watch(sharedPreferencesProvider));
});
