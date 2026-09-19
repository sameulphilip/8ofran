# غفران

تطبيق Flutter عربي (RTL) لحجز موعد هادئ مع أب روحي. يخزّن بيانات الحجز فقط، من غير محتوى الجلسة.

## التشغيل

```bash
flutter pub get
flutterfire configure --project=ofran-7a7c5
flutter run
```

`lib/firebase_options.dart` و`android/app/google-services.json` محليان ولا يُرفعان إلى Git. انسخ النماذج:

- `lib/firebase_options.example.dart`
- `android/app/google-services.example.json`

## Firebase

المشروع: `ofran-7a7c5`

من Console فعّل:

1. Authentication → Email/Password
2. Authentication → Google
3. Authorized domains: `localhost` للويب
4. أندرويد + Google: أضف SHA-1

انشر القواعد:

```bash
firebase deploy --only firestore:rules --project ofran-7a7c5
```

## حساب الأب

أنشئ حساباً ببريد الأب في الدليل، مثل `youhanna@ghofran.app`. بعد الدخول تظهر خدمة الأب: جدول الاعتراف، المتأخرون، وإعطاء القانون الروحي.

## الخصوصية

القانون الروحي ملاحظة رعوية (صلوات/قراءة)، وليس نص الاعتراف. الفحص الذاتي يبقى على الجهاز.
