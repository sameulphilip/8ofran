import 'package:a3traf/features/info/domain/church_calendar.dart';
import 'package:a3traf/features/home/presentation/verse_of_day.dart';
import 'package:a3traf/features/info/data/conscience_local_store.dart';
import 'package:a3traf/features/settings/data/app_lock_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ChurchCalendar', () {
    test('detects nativity fast in December', () {
      final season = ChurchCalendar.seasonFor(DateTime(2026, 12, 10));
      expect(season.season, ChurchSeason.nativityFast);
    });

    test('detects approximate great lent in 2026', () {
      final season = ChurchCalendar.seasonFor(DateTime(2026, 3, 1));
      expect(season.season, ChurchSeason.greatLent);
    });

    test('lists calendar items around a day', () {
      final items = ChurchCalendar.itemsAround(DateTime(2026, 4, 1));
      expect(items, isNotEmpty);
      expect(items.any((e) => e.title.contains('الميلاد')), isTrue);
    });
  });

  group('VerseOfDay', () {
    test('picks lent verse during great lent', () {
      final verse = VerseOfDay.today(DateTime(2026, 3, 1));
      expect(
        verse.reference,
        anyOf('مزمور 50: 12', 'متى 3: 2', '1 يوحنا 1: 9'),
      );
    });
  });

  group('ConscienceLocalStore', () {
    test('adds seasonal questions in lent', () {
      final questions = ConscienceLocalStore.questionsFor(DateTime(2026, 3, 1));
      expect(questions.any((q) => q.id == 'lent_food'), isTrue);
    });

    test('saves notes only locally', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ConscienceLocalStore(prefs);
      await store.save(
        const ConscienceSnapshot(
          answers: {'prayer': true},
          notes: 'مذكرة خاصة',
        ),
      );
      final loaded = store.load();
      expect(loaded.answers['prayer'], isTrue);
      expect(loaded.notes, 'مذكرة خاصة');
      expect(store.exportText(), contains('مذكرة خاصة'));
      await store.clear();
      expect(store.load().answers, isEmpty);
    });
  });

  group('AppLockStore', () {
    test('hashes and verifies pin without storing plaintext', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AppLockStore(prefs);
      await store.enableWithPin('1234');
      expect(store.isEnabled, isTrue);
      expect(store.pinHash, isNot('1234'));
      expect(store.verifyPin('1234'), isTrue);
      expect(store.verifyPin('0000'), isFalse);
      await store.disable();
      expect(store.isEnabled, isFalse);
    });
  });
}
