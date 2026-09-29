# إعداد Supabase — تطبيق منصة الأكرم للمحامين السوريين

تم ربط المشروع ببيانات مشروع Supabase الحالي:

- Project URL: `https://ilwbrqtgwtzcjlgzfycn.supabase.co`
- يستخدم التطبيق **Publishable Key** فقط.
- لا يوجد أي `service_role` أو Secret Key داخل التطبيق.

## تشغيل التطبيق

بعد تثبيت Flutter وتشغيل `flutter pub get`:

```bash
flutter run
```

يمكن أيضاً تجاوز الإعدادات المضمنة وقت البناء:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

ولنسخة Android: 

```bash
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## قاعدة البيانات

نفّذ ملف:

`supabase/migrations/0001_al_akram_law.sql`

من **SQL Editor** في مشروع Supabase.

هذا ينشئ الجداول الأساسية للمحامين والموكلين والقضايا والجلسات والمستندات والإشعارات والمهام، بالإضافة إلى بنية اللمحامين السوريينة القانونية السورية وRLS وStorage الخاص بالمستندات.

## مهم

المفتاح الموجود في تطبيق Flutter هو Publishable Key وليس مفتاحاً سرياً. لا تضع أبداً `service_role` أو Secret Key في التطبيق.

## بيانات المكتبة القانونية

تمت إضافة ملف البيانات:

`data/all_legal_articles_with_penalties.csv`

وتمت إضافة سكربت الاستخراج:

`scripts/extract_to_csv.py`

كما تمت إضافة migration:

`supabase/migrations/0004_legal_articles_data.sql`

وهذه الـ migration تضيف حقول العقوبات وتدخل البيانات المستخرجة إلى `legal_sources` و`legal_articles`. ثم تقوم `0005_legal_library_rpc.sql` بتحديث دوال البحث والتصفح التي يستخدمها التطبيق.

**ترتيب التنفيذ في Supabase SQL Editor:**

1. `0001_al_akram_law.sql`
2. `0002_production_hardening.sql`
3. `0003_legal_search_metadata.sql`
4. `0004_legal_articles_data.sql`
5. `0005_legal_library_rpc.sql`

بعد تنفيذها وتشغيل التطبيق، ستقرأ شاشة المكتبة والبحث القانوني البيانات من Supabase بدل القائمة الثابتة الموجودة سابقًا داخل التطبيق.

> ملاحظة: ملف `0004_legal_articles_data.sql` كبير لأنه يحتوي على البيانات نفسها حتى يمكن تجهيز قاعدة البيانات دون الحاجة إلى مفتاح `service_role` داخل تطبيق Flutter.

## المرحلة الأولى — التجربة والاشتراكات والهوية البصرية

تمت إضافة migration جديدة مستقلة:

`supabase/migrations/0010_subscription_trial_activation.sql`

**نفّذها بعد جميع migrations الحالية (0001 → 0009) دون حذف أو إعادة تنفيذ الملفات القديمة.**

تضيف هذه المرحلة:

- تجربة مجانية مدتها 3 أشهر تُحسب بواسطة `now()` على PostgreSQL عند إنشاء الحساب.
- حقول حالة الاشتراك وتواريخ التجربة والاشتراك داخل `profiles`.
- جدول `activation_codes` مع حد الاستخدام وتاريخ الانتهاء ونوع الرمز.
- دالة خادمية ذرّية `redeem_activation_code()` لا تكشف جدول الرموز للتطبيق.
- دوال `get_subscription_state()` و`refresh_subscription_status()` للتحقق من الصلاحية من الخادم.
- تشديد RLS على القضايا والموكلين والجلسات والمستندات والمهام بعد انتهاء الصلاحية.
- إبقاء المكتبة القانونية قابلة للتصفح للمستخدم المنتهي اشتراكه.
- واجهة اشتراك ورمز تفعيل داخل التطبيق، مع إغلاق الوظائف الأساسية عند انتهاء الصلاحية.
- هوية بصرية جديدة: Dark Navy + Cyan مع إبقاء الذهبي للهوية القانونية.
- أيقونة Android جديدة بميزان عدالة ذهبي على خلفية كحلية.

### إنشاء رمز تفعيل من لوحة Supabase

يمكن للمشرف في المرحلة الحالية إنشاء الرمز مباشرة من SQL Editor، مثال:

```sql
insert into public.activation_codes
  (code, type, expires_at, max_uses, duration_months, created_by)
values
  ('AKRAM-YEAR-001', 'yearly', now() + interval '30 days', 1, null, auth.uid());
```

لا يتم وضع هذا الرمز داخل Flutter أو داخل APK. مثال الرمز أعلاه للاختبار فقط، ويجب تغييره عند الاستخدام الفعلي.

**ملاحظة أمنية:** لا تمنح تطبيق Flutter صلاحية `select` على `activation_codes`. التطبيق يستدعي دالة الخادم فقط، أما إدارة وإنشاء الرموز ولوحة المشرف فستُستكمل في المرحلة التالية.
