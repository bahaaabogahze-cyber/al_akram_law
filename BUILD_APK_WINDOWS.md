# إنشاء APK على Windows

هذه النسخة لا تحتوي على `android/local.properties` لأنه ملف خاص بجهازك.

1. ثبّت Flutter وAndroid Studio وتأكد من `flutter doctor`.
2. افتح مجلد المشروع `al_akram_law` في Terminal.
3. نفّذ:

```powershell
flutter clean
flutter pub get
flutter doctor -v
flutter build apk --release
```

4. ستجد APK هنا:

```text
build\app\outputs\flutter-apk\app-release.apk
```

إذا كان Flutter SDK غير موجود في PATH، شغّل `flutter doctor` أولًا أو افتح المشروع من Android Studio بعد تثبيت Flutter plugin.

ملاحظة: نسخة release الحالية تستخدم debug signing لتسهيل الاختبار فقط. قبل النشر على Google Play يجب إعداد مفتاح توقيع release حقيقي.
