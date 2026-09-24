enum ChurchSeason {
  ordinary,
  nativityFast,
  nativity,
  greatLent,
  holyWeek,
  pascha,
  apostlesFast,
  virginFast,
}

class ChurchCalendarItem {
  const ChurchCalendarItem({
    required this.title,
    required this.body,
    required this.start,
    required this.end,
  });

  final String title;
  final String body;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

class ChurchSeasonInfo {
  const ChurchSeasonInfo({
    required this.season,
    required this.title,
    required this.body,
  });

  final ChurchSeason season;
  final String title;
  final String body;
}

class ChurchCalendar {
  ChurchCalendar._();

  static ChurchSeasonInfo seasonFor(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    if (_between(date, month: 11, day: 25, endMonth: 12, endDay: 31) ||
        _between(date, month: 1, day: 1, endMonth: 1, endDay: 6)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.nativityFast,
        title: 'صوم الميلاد',
        body: 'زمن انتظار ورجاء. صلِّ بهدوء واستعد لعيد التجسد.',
      );
    }
    if (_between(date, month: 1, day: 7, endMonth: 1, endDay: 8)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.nativity,
        title: 'عيد الميلاد',
        body: 'المسيح وُلد. افرح بهدوء، واشكر على نعمة التجسد.',
      );
    }
    if (_inGreatLent(date)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.greatLent,
        title: 'الصوم الكبير',
        body: 'زمن توبة وصلاة. خفّف الضجيج، وراجع قلبك بصدق.',
      );
    }
    if (_inHolyWeek(date)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.holyWeek,
        title: 'أسبوع الآلام',
        body: 'سرّ الصليب قريب. امكث في الصلاة والقراءة الهادئة.',
      );
    }
    if (_inPascha(date)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.pascha,
        title: 'الخمسين المقدسة',
        body: 'المسيح قام. عِش فرح القيامة في علاقاتك اليومية.',
      );
    }
    if (_between(date, month: 6, day: 12, endMonth: 7, endDay: 11)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.apostlesFast,
        title: 'صوم الرسل',
        body: 'زمن شهادة وخدمة. اطلب أن يكون كلامك هادئًا ومفيدًا.',
      );
    }
    if (_between(date, month: 8, day: 7, endMonth: 8, endDay: 21)) {
      return const ChurchSeasonInfo(
        season: ChurchSeason.virginFast,
        title: 'صوم العذراء',
        body: 'زمن تواضع وطلب شفاعة. صلِّ من أجل بيتك وكنيستك.',
      );
    }
    return const ChurchSeasonInfo(
      season: ChurchSeason.ordinary,
      title: 'زمن عادي',
      body: 'احفظ صلواتك اليومية، وابقَ قريبًا من الأب الروحي.',
    );
  }

  static List<ChurchCalendarItem> itemsAround(DateTime day) {
    final year = day.year;
    final lentStart = _greatLentStart(year);
    final pascha = lentStart.add(const Duration(days: 48));
    return [
      ChurchCalendarItem(
        title: 'صوم الميلاد',
        body: 'من 25 هاتور تقريبًا حتى عيد الميلاد.',
        start: DateTime(year, 11, 25),
        end: DateTime(year + 1, 1, 6),
      ),
      ChurchCalendarItem(
        title: 'عيد الميلاد',
        body: '7 و8 يناير — فرح التجسد.',
        start: DateTime(year, 1, 7),
        end: DateTime(year, 1, 8),
      ),
      ChurchCalendarItem(
        title: 'الصوم الكبير',
        body: 'زمن توبة. التواريخ تقريبية حسب السنة.',
        start: lentStart,
        end: lentStart.add(const Duration(days: 39)),
      ),
      ChurchCalendarItem(
        title: 'أسبوع الآلام',
        body: 'الاستعداد للصليب والقيامة.',
        start: lentStart.add(const Duration(days: 40)),
        end: pascha.subtract(const Duration(days: 1)),
      ),
      ChurchCalendarItem(
        title: 'عيد القيامة',
        body: 'بدء الخمسين المقدسة.',
        start: pascha,
        end: pascha.add(const Duration(days: 49)),
      ),
      ChurchCalendarItem(
        title: 'صوم الرسل',
        body: 'بعد الخمسين — زمن شهادة وخدمة.',
        start: DateTime(year, 6, 12),
        end: DateTime(year, 7, 11),
      ),
      ChurchCalendarItem(
        title: 'صوم العذراء',
        body: 'من 1 إلى 15 مسرى تقريبًا.',
        start: DateTime(year, 8, 7),
        end: DateTime(year, 8, 21),
      ),
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  static bool _between(
    DateTime date, {
    required int month,
    required int day,
    required int endMonth,
    required int endDay,
  }) {
    final start = DateTime(date.year, month, day);
    final end = DateTime(date.year, endMonth, endDay);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// Approximate Coptic Great Lent start for nearby years.
  static DateTime _greatLentStart(int year) {
    return switch (year) {
      2025 => DateTime(2025, 3, 3),
      2026 => DateTime(2026, 2, 23),
      2027 => DateTime(2027, 3, 15),
      2028 => DateTime(2028, 3, 6),
      _ => DateTime(year, 3, 1),
    };
  }

  static bool _inGreatLent(DateTime date) {
    final start = _greatLentStart(date.year);
    final end = start.add(const Duration(days: 39));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static bool _inHolyWeek(DateTime date) {
    final start = _greatLentStart(date.year).add(const Duration(days: 40));
    final end = start.add(const Duration(days: 7));
    return !date.isBefore(start) && date.isBefore(end);
  }

  static bool _inPascha(DateTime date) {
    final start = _greatLentStart(date.year).add(const Duration(days: 48));
    final end = start.add(const Duration(days: 49));
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
