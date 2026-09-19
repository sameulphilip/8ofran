class GuideSection {
  const GuideSection({required this.title, required this.body});
  final String title;
  final String body;
}

class GuideContent {
  GuideContent._();

  static const confessionSteps = [
    GuideSection(
      title: 'قبل الموعد',
      body:
          'اختار وقتاً لا تُستعجل فيه. التطبيق للحجز فقط، فجهّز قلبك بعيداً عن الشاشة.',
    ),
    GuideSection(
      title: 'فحص هادئ',
      body:
          'راجع يومك وعلاقاتك بصدق. استخدم الفحص الذاتي المحفوظ على جهازك إن احتجت.',
    ),
    GuideSection(
      title: 'أثناء اللقاء',
      body:
          'كن واضحاً ومختصراً. لا حاجة لتبرير كل شيء. الخصوصية مسؤوليتك ومسؤوليتنا.',
    ),
    GuideSection(
      title: 'بعدها',
      body: 'خذ خطوة واحدة عملية. الموعد بداية، مش نهاية.',
    ),
  ];

  static const psalm50 =
      'اهدأ قليلاً. اسأل نفسك: ماذا أثقلني هذا الأسبوع؟ من أسأت إليه؟ وما الذي أحتاج أن أتركه؟ '
      'لا تكتب الإجابة هنا إن كانت خاصة. اكتبها في دفترك، أو احفظها في الفحص الذاتي على جهازك فقط.';

  static const fasts = [
    GuideSection(
      title: 'صمت قصير',
      body: 'خمس دقائق من غير هاتف قبل النوم تكفي لتعود لنفسك.',
    ),
    GuideSection(
      title: 'جملة صادقة',
      body: 'إن كنت ستقابل أحداً غداً، جهّز جملة واحدة واضحة، لا خطاباً.',
    ),
    GuideSection(
      title: 'حدود لطيفة',
      body: 'لا تحجز موعدين في نفس الأسبوع إن كنت مرهقاً. الهدوء أهم من العدد.',
    ),
    GuideSection(
      title: 'بعد الموعد',
      body: 'امشِ قليلاً قبل أن تفتح التطبيقات. خلّ اللقاء يرسو.',
    ),
  ];
}
