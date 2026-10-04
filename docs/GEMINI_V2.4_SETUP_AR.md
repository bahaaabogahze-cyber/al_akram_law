# AL AKRAM V2.4 – Gemini Integration

## ما تغير
- تحويل وظيفتي `analyze-case` و`legal-assistant` من OpenAI إلى Google Gemini.
- قراءة المفتاح حصراً من `GEMINI_API_KEY` في Supabase Edge Function Secrets.
- النموذج الافتراضي `gemini-2.5-flash` ويمكن تغييره عبر `GEMINI_MODEL`.
- لا يوجد مفتاح Gemini أو OpenAI أو Supabase مضمّن في ملفات هذا الإصدار.
- في الإصدار V2.5 أزيل ملف `fix_articles.py` بالكامل لأنه سكربت صيانة اختياري كان يحتاج مفتاح Supabase Secret API Key، ولا تحتاجه وظائف التطبيق.

## مهم جداً: تدوير الأسرار التي سبق نشرها
عُثر في نسخة V2.3 على بيانات اعتماد مكتوبة داخل `fix_articles.py` (مفتاح Gemini ومفتاح Supabase سري). يجب إلغاء المفتاحين المكشوفين. إزالة الملف في V2.5 لا تمحو النسخة القديمة من سجل GitHub؛ راجع `docs/SECURITY_V2.5_AR.md`.

## إعداد Supabase
من Supabase Dashboard ثم Edge Functions ثم Secrets، أضف أو حدّث:
- الاسم: `GEMINI_API_KEY`
- القيمة: مفتاح Gemini الجديد
- (اختياري) الاسم: `GEMINI_MODEL`، القيمة: `gemini-2.5-flash`

لا تضع المفتاح في Flutter أو ملفات المشروع أو GitHub. لا حاجة إلى أي إعداد لمزود OpenAI في هذا الإصدار. بعد التأكد من نجاح Gemini، احذف Secret القديم الخاص بـ OpenAI إن وجد.

## نشر وظائف الخادم
من مجلد المشروع المرتبط بمشروع Supabase الصحيح:

```bash
supabase functions deploy analyze-case
supabase functions deploy legal-assistant
```

يجب أن يكون المستخدم مسجلاً للدخول عند استدعاء الوظيفتين. تستخدمان جلسة المستخدم وصلاحيات RLS عند قراءة بيانات القضية.

## اختبار
1. افتح التطبيق وسجل الدخول.
2. افتح قضية لديها مستندات أو جلسات.
3. نفّذ تحليل القضية من شاشة التحليل.
4. افتح مساعد المحامي واسأله عن مستند أو موعد جلسة.
5. تحقق من أن كل مصدر معروض يعود إلى سجل موجود في القضية.

## ملاحظات
- البحث في المستندات يعتمد على النص الموجود في `documents.ocr_text`؛ الصور أو ملفات PDF التي لم يُستخرج نصها لن تكون قابلة للبحث النصي.
- لم يتم تشغيل Flutter SDK أو Deno/Supabase CLI في بيئة إعداد هذه الحزمة؛ يلزم نشر الوظيفتين واختبارهما في مشروعك قبل اعتبار التكامل عاملاً.
- أزيل `fix_articles.py` في V2.5 لأنه ليس مطلوباً لتشغيل التطبيق أو مساعد Gemini.
