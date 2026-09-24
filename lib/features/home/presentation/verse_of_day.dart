import '../../info/domain/church_calendar.dart';

class VerseOfDay {
  const VerseOfDay({required this.text, required this.reference});

  final String text;
  final String reference;

  static const _ordinary = [
    VerseOfDay(
      text: 'تعالوا إليّ يا جميع المتعبين والثقيلي الأحمال، وأنا أريحكم.',
      reference: 'متى 11: 28',
    ),
    VerseOfDay(
      text: 'الرب راعيّ فلا يعوزني شيء. في مراعٍ خضر يربضني.',
      reference: 'مزمور 23: 1-2',
    ),
    VerseOfDay(
      text: 'قريب هو الرب من المنكسري القلوب، ويخلّص المنسحقي الروح.',
      reference: 'مزمور 34: 18',
    ),
    VerseOfDay(
      text: 'سلاماً أترك لكم. سلامي أعطيكم. لا كما يعطي العالم أعطيكم أنا.',
      reference: 'يوحنا 14: 27',
    ),
    VerseOfDay(
      text: 'اطرح على الرب همّك فهو يعولك. لا يدع الصدّيق يتزعزع.',
      reference: 'مزمور 55: 22',
    ),
    VerseOfDay(
      text: 'توكّل على الرب بكل قلبك، وعلى فهمك لا تعتمد.',
      reference: 'أمثال 3: 5',
    ),
    VerseOfDay(
      text: 'ارفعوا إليّ عيونكم وانظروا. الحقول قد ابيضّت للحصاد.',
      reference: 'يوحنا 4: 35',
    ),
  ];

  static const _nativityFast = [
    VerseOfDay(
      text: 'ها العذراء تحبل وتلد ابنًا وتدعو اسمه عمانوئيل.',
      reference: 'إشعياء 7: 14',
    ),
    VerseOfDay(
      text: 'الشعب السالك في الظلمة أبصر نورًا عظيمًا.',
      reference: 'إشعياء 9: 2',
    ),
  ];

  static const _greatLent = [
    VerseOfDay(
      text: 'اخلق فيّ يا الله قلبًا نقيًا، وروحًا مستقيمًا جدّد في داخلي.',
      reference: 'مزمور 50: 12',
    ),
    VerseOfDay(
      text: 'توبوا لأنه قد اقترب ملكوت السموات.',
      reference: 'متى 3: 2',
    ),
    VerseOfDay(
      text: 'إن اعترفنا بخطايانا فهو أمين وعادل حتى يغفر لنا خطايانا.',
      reference: '1 يوحنا 1: 9',
    ),
  ];

  static const _pascha = [
    VerseOfDay(
      text: 'المسيح قام من الأموات، وصار باكورة الراقدين.',
      reference: '1 كورنثوس 15: 20',
    ),
    VerseOfDay(
      text: 'هذا هو اليوم الذي صنعه الرب، نبتهج ونفرح فيه.',
      reference: 'مزمور 117: 24',
    ),
  ];

  static const _holyWeek = [
    VerseOfDay(
      text: 'هوذا حمل الله الذي يرفع خطية العالم.',
      reference: 'يوحنا 1: 29',
    ),
    VerseOfDay(
      text: 'أبي، إن أمكن فلتعبر عني هذه الكأس، ولكن ليس كما أريد أنا بل كما تريد أنت.',
      reference: 'متى 26: 39',
    ),
  ];

  static VerseOfDay today([DateTime? now]) {
    final day = now ?? DateTime.now();
    final season = ChurchCalendar.seasonFor(day).season;
    final pool = switch (season) {
      ChurchSeason.nativityFast || ChurchSeason.nativity => _nativityFast,
      ChurchSeason.greatLent => _greatLent,
      ChurchSeason.holyWeek => _holyWeek,
      ChurchSeason.pascha => _pascha,
      _ => _ordinary,
    };
    final index = day.difference(DateTime(2024)).inDays.abs() % pool.length;
    return pool[index];
  }
}
