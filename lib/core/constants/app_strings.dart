class AppStrings {
  AppStrings._();

  static const appName = 'غفران';
  static const appNameEn = 'GHOFRAN';
  static const tagline = 'معاً في طريق المحبة والخدمة';
  static const brandLine =
      'منصة لحجز موعد هادئ مع أب روحي. تفاصيل الجلسة لا تُحفظ.';
  static const privacyBody =
      'غفران يخزن بيانات الحجز فقط: من، مع من، ومتى. '
      'لا يُحفظ محتوى الجلسة. الفحص الذاتي يبقى على الجهاز.';

  static const username = 'اسم المستخدم';
  static const emailOrUsername = 'البريد الإلكتروني أو اسم المستخدم';
  static const password = 'كلمة المرور';
  static const rememberMe = 'تذكرني';
  static const forgotPassword = 'نسيت كلمة المرور؟';
  static const login = 'تسجيل الدخول';
  static const or = 'أو';
  static const loginWithGoogle = 'الدخول باستخدام Google';
  static const noAccount = 'ليس لديك حساب؟';
  static const createNewAccount = 'إنشاء حساب جديد';

  static const signupTitle = 'إنشاء حساب جديد';
  static const signupSubtitle = 'انضم إلينا وكن جزءاً من عائلتنا';
  static const fullName = 'الاسم الكامل';
  static const email = 'البريد الإلكتروني';
  static const confirmPassword = 'تأكيد كلمة المرور';
  static const acceptTerms = 'أوافق على الشروط وسياسة الخصوصية';
  static const signup = 'إنشاء حساب';
  static const signupWithGoogle = 'التسجيل باستخدام Google';
  static const haveAccount = 'لديك حساب بالفعل؟';
  static const goToLogin = 'تسجيل الدخول';

  static const requiredField = 'هذا الحقل مطلوب';
  static const invalidEmail = 'أدخل بريداً إلكترونياً صحيحاً';
  static const shortPassword = 'كلمة المرور يجب ألا تقل عن 8 أحرف';
  static const passwordMismatch = 'كلمتا المرور غير متطابقتين';
  static const acceptTermsError = 'يجب الموافقة على الشروط أولاً';
  static const loginFailed = 'اسم المستخدم أو كلمة المرور غير صحيحة';
  static const usernameTaken = 'اسم المستخدم مستخدم من قبل';
  static const emailTaken = 'هذا البريد مسجّل من قبل';
  static const googleMockNotice = 'تعذّر الدخول بجوجل. جرّب البريد أو أنشئ حساباً.';
  static const noConnection = 'لا يوجد اتصال بالإنترنت';
  static const firebaseNotReady =
      'خدمة الحسابات غير مفعّلة بعد. فعّل Email/Password وGoogle في Firebase Authentication.';
  static const resetSent = 'إن وُجد حساب بهذا البريد سنرسل رابط إعادة التعيين.';
  static const sendReset = 'إرسال رابط الاستعادة';
  static const resetTitle = 'استعادة كلمة المرور';
  static const resetHint = 'أدخل بريدك وسنرسل رابط إعادة التعيين.';
  static const bookingConfirmedTitle = 'تم تأكيد الحجز';
  static const bookingConfirmedBody = 'تم تأكيد موعدك على غفران.';
  static const bookingCancelledTitle = 'تم إلغاء الموعد';
  static const bookingCancelledBody = 'تم إلغاء الموعد.';

  static const welcome = 'مرحباً';
  static const peaceGreeting = 'سلام الرب معك دائماً';
  static const lastAppointment = 'موعدك القادم';
  static const viewAll = 'عرض الكل';
  static const bookNew = 'حجز موعد جديد';
  static const upcomingShort = 'المواعيد';
  static const aboutShort = 'عن غفران';
  static const infoGuides = 'استعداد';
  static const verseOfDay = 'سطر لليوم';
  static const tileBook = 'حجز موعد جديد';
  static const tileAppointments = 'مواعيدي القادمة';
  static const tilePriests = 'الآباء';
  static const tileInfo = 'معلومات وإرشادات';
  static const todayBadge = 'اليوم';
  static const emptyNextInvite = 'لا يوجد موعد قادم — احجز موعدك الآن';

  static const home = 'الرئيسية';
  static const bookTab = 'حجز';
  static const moreTab = 'المزيد';
  static const bookConfession = 'حجز موعد';
  static const myAppointments = 'مواعيدي القادمة';
  static const aboutPage = 'عن غفران';
  static const infoAndGuides = 'معلومات وإرشادات';
  static const upcomingAppointments = 'مواعيدي القادمة';
  static const notifications = 'الإشعارات';
  static const contactUs = 'تواصل';
  static const settings = 'الإعدادات';
  static const logout = 'خروج';

  static const choosePriest = 'اختر الأب';
  static const priestRole = 'أب روحي';
  static const selectSlot = 'اختيار الموعد';
  static const availableSlots = 'المواعيد المتاحة';
  static const next = 'التالي';
  static const noSlots = 'لا توجد مواعيد في هذا اليوم';
  static const nearestAvailable = 'أقرب يوم متاح';
  static const noPriests = 'لا يوجد آباء متاحون حالياً. تواصل معنا إن احتجت.';
  static const retry = 'إعادة المحاولة';
  static const menuLabel = 'القائمة';
  static const backLabel = 'رجوع';

  static const confirmBooking = 'تأكيد الحجز';
  static const reviewDetails = 'مراجعة تفاصيل الموعد';
  static const confirm = 'تأكيد الحجز';
  static String withPriest(String name) => 'مع $name';
  static const dateLabel = 'التاريخ';
  static const timeLabel = 'الوقت';
  static const placeLabel = 'المكان';

  static const bookingSuccessTitle = 'تم حجز موعدك بنجاح';
  static const bookingSuccessBody =
      'شكراً لك، تم حجز موعدك، ونتطلع لرؤيتك.';
  static const backHome = 'العودة للرئيسية';
  static const showAppointments = 'عرض مواعيدي';
  static const slotTaken = 'هذا الموعد لم يعد متاحاً، اختر وقتاً آخر';
  static const privacyNote =
      'تفاصيل الجلسة سرّ بينك وبين الأب، ولا تُخزَّن في التطبيق.';
  static const optionalNote = 'ملاحظة للتنظيم (اختياري)';
  static const remindMe = 'هل تحب أن نذكّرك قبل موعدك؟';

  static const upcoming = 'القادمة';
  static const past = 'السابقة';
  static const confirmed = 'مؤكد';
  static const pending = 'قيد التأكيد';
  static const cancelled = 'ملغي';
  static const completed = 'مكتمل';
  static const reschedule = 'تغيير الموعد';
  static const cancelAppointment = 'إلغاء الموعد';
  static const noOtherAppointments = 'لا توجد مواعيد أخرى حالياً';
  static const bookFromHomeHint = 'يمكنك حجز موعد جديد من الصفحة الرئيسية';
  static const bookNewAppointment = 'حجز موعد جديد';
  static const appointmentNote =
      'من فضلك احضر في الموعد المحدد مع الالتزام بالهدوء.';
  static const appointmentDetails = 'تفاصيل الموعد';
  static const notes = 'ملاحظة للتنظيم';
  static const notesHint =
      'الملاحظة للتنظيم فقط: وقت أطول مثلاً. لا تكتب محتوى الجلسة.';
  static const rescheduleAppointment = 'تغيير الموعد';
  static const cancelConfirmTitle = 'هل تريد إلغاء الموعد؟';
  static const cancelConfirmBody =
      'الإلغاء متاح قبل الموعد بـ 12 ساعة على الأقل. يمكنك حجز موعد جديد في أي وقت.';
  static const keepAppointment = 'تراجع';
  static const yesCancel = 'نعم، ألغِ الموعد';

  static String cancelBodyFor(String name, String date) =>
      'سيتم إلغاء موعدك مع $name يوم $date. يمكنك حجز موعد جديد في أي وقت.';

  static String inHours(int hours) => hours <= 1 ? 'بعد أقل من ساعة' : 'بعد $hours ساعات';
  static const cancelTooLate =
      'لا يمكن إلغاء أو تغيير الموعد قبل أقل من 12 ساعة.';
  static const emptyUpcoming = 'لا يوجد موعد قادم';
  static const emptyPast = 'لا توجد مواعيد سابقة';
  static const emptyUpcomingAction = 'احجز أول موعد';
  static const formErrorTitle = 'راجع البيانات دي';
  static const choosePriestHint = 'آباء من مدن مختلفة. اختار الأنسب ليك.';
  static const prepareVisit = 'جهّز نفسك للموعد';
  static const viewDetails = 'التفاصيل';
  static const emptyNotificationsHint = 'لما يتأكد موعد أو يتغيّر، هيبان هنا.';

  static const addToCalendar = 'إضافة للتقويم';
  static const openMaps = 'فتح الموقع على الخريطة';
  static const supportAddress = 'خدمة عامة — مصر';
  static const supportPhone = '01000000000';
  static const supportEmail = 'hello@bonowa.app';
  static const serviceHours = 'الحجز متاح معظم الأيام من 3:00 م إلى 7:00 م';

  static const infoTitle = 'استعداد للموعد';
  static const confessionGuide = 'دليل الاستعداد';
  static const conscienceExam = 'فحص ذاتي';
  static const reflectionText = 'نص للتأمل';
  static const quietPrompts = 'أسئلة للهدوء';
  static const privacyLocalOnly =
      'هذه الإجابات تُحفظ على جهازك فقط، ولا تُرفع لأي خادم.';
  static const saveLocally = 'حفظ على الجهاز';
  static const savedLocally = 'تم الحفظ على جهازك فقط';
  static const clearLocal = 'مسح الإجابات المحلية';
  static const clearedLocal = 'تم مسح الإجابات من الجهاز';

  static const noNotifications = 'صندوق الإشعارات فاضي';
  static const markAllRead = 'تعيين الكل كمقروء';

  static const settingsTitle = 'الإعدادات';
  static const notifyReminders = 'تذكير بالمواعيد';
  static const biometricSoon = 'قفل التطبيق بالبصمة أو الوجه';
  static const biometricHint = 'قريباً. لن يُخزَّن أي محتوى خاص بالجلسة.';
  static const privacyPolicy = 'سياسة الخصوصية';
  static const aboutApp = 'عن غفران';
  static const demoHint = 'أنشئ حساباً جديداً أو ادخل ببريدك.';
  static const comingSoon = 'قريباً';

  static const contactPhone = 'اتصال';
  static const contactWhatsApp = 'واتساب';
  static const contactEmail = 'بريد';

  static const logoutConfirm = 'خروج من الحساب؟';
  static const logoutBody = 'تقدر ترجع في أي وقت.';
  static const cancel = 'إلغاء';
  static const ok = 'حسناً';

  static const aboutBody =
      'غفران منصة لحجز موعد هادئ مع أب روحي. الفكرة بسيطة: تختار أباً، تختار وقتاً، وتحتفظ بخصوصيتك. '
      'التطبيق يسجّل مين ومع مين وإمتى. لا يسجّل محتوى الجلسة.';

  static const weekdays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
}
