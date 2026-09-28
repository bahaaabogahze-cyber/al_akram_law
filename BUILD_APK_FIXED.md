# بناء APK

هذه النسخة متوافقة مع Flutter 3.47.5 من ناحية Gradle: تم تحديث Gradle Wrapper من 8.9 إلى 8.14، مع إبقاء AGP 8.7.3 لتجنب مشاكل AGP 9/new DSL.

قبل البناء:
1. استخدم Java 21 عبر Flutter: `flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"`
2. افتح PowerShell داخل مجلد المشروع.
3. نفذ:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

الملف الناتج: `build\app\outputs\flutter-apk\app-release.apk`
