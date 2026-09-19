class VerseOfDay {
  const VerseOfDay({required this.text, required this.reference});

  final String text;
  final String reference;

  static const _verses = [
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

  static VerseOfDay today() {
    final index =
        DateTime.now().difference(DateTime(2024)).inDays % _verses.length;
    return _verses[index];
  }
}
