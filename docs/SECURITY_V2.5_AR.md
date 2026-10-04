# تعليمات الأمان – AL AKRAM V2.5

## نتيجة فحص الاعتماد على Supabase Secret API Key

بعد مراجعة ملفات Flutter ووظيفتي Supabase Edge Functions في V2.4، لم يظهر أي استخدام لمفتاح Supabase Secret API Key أو `service_role` في التطبيق أو في وظيفتي الذكاء الاصطناعي.

- `lib/core/supabase_config.dart`: يحتوي عنوان المشروع ومفتاح Publishable العام فقط.
- `lib/services/supabase_service.dart`: يهيئ Supabase باستخدام Publishable Key وجلسة المستخدم.
- `supabase/functions/analyze-case/index.ts`: تستخدم `SUPABASE_URL` و`SUPABASE_ANON_KEY` مع ترويسة Authorization الخاصة بالمستخدم، وتقرأ Gemini من `GEMINI_API_KEY`.
- `supabase/functions/legal-assistant/index.ts`: تتبع الأسلوب نفسه وتقرأ `GEMINI_API_KEY`.
- صلاحيات قراءة بيانات القضية تخضع لجلسة المستخدم وسياسات RLS، ولا تحتاج الوظائف إلى مفتاح إداري عام.

## لماذا كان المفتاح السري موجوداً؟

كان الملف `fix_articles.py` سكربت صيانة اختياريّاً يقرأ `SUPABASE_SECRET_KEY` من متغير بيئة، ثم يستخدمه لتحديث نصوص سجلات `legal_articles`. هذا السكربت ليس جزءاً من تشغيل التطبيق أو مساعد Gemini، وقد أزيل بالكامل من V2.5. بيانات المكتبة القانونية الأساسية تُحمّل عبر ملفات SQL المرفقة بالمشروع، ولا يتطلب تشغيل التطبيق هذا السكربت.

## المفاتيح المطلوبة فعلياً

1. Flutter: مفتاح Supabase Publishable فقط، وهو مصمم للاستخدام في تطبيق العميل عند تفعيل RLS.
2. Supabase Edge Functions: `GEMINI_API_KEY` فقط لمزود الذكاء الاصطناعي.
3. لا يلزم `SUPABASE_SECRET_KEY` أو `service_role` لتشغيل وظائف التحليل والمساعد في هذا الإصدار.

## ما العمل بالمفاتيح التي أنشأتها؟

- المفتاح القديم `default` من نوع Secret API Key الذي ظهر في نسخة V2.3 وعلى GitHub يجب إلغاؤه بعد التأكد من عدم وجود خدمة خارج هذا المستودع تعتمد عليه. لم يظهر استخدامه في ملفات V2.4 التي تمت مراجعتها.
- المفتاح الجديد المسمى `alakram_server_v2` غير مستخدم في V2.5، ولا تضعه في أي ملف. يمكنك حذفه إذا لم تكن قد ربطته بخدمة أخرى.
- لا تحذف مفتاح Publishable.
- أبقِ `GEMINI_API_KEY` في Edge Function Secrets.

## GitHub

حذف `fix_articles.py` من V2.5 لا يمحو نسخته القديمة من تاريخ GitHub. إلغاء المفتاح القديم هو الإجراء الأساسي لإبطال الاعتماد المكشوف. بعد ذلك يمكن تنظيف تاريخ Git للمستودع باستخدام `git filter-repo` ثم دفع التاريخ المنقح بالقوة، مع أخذ نسخة احتياطية أولاً. إذا لم تكن معتاداً على إعادة كتابة سجل Git، لا تنفذ أوامر `push --force` قبل أخذ نسخة احتياطية واتباع خطوات موجهة.

## النشر والاختبار

انشر الوظيفتين بعد فتح مجلد المشروع المرتبط بمشروع Supabase الصحيح:

```bash
supabase functions deploy analyze-case
supabase functions deploy legal-assistant
```

ثم اختبر تسجيل الدخول وفتح قضية وتشغيل التحليل وسؤال المساعد. لم يتم تشغيل Flutter SDK أو Deno/Supabase CLI في بيئة إعداد هذه الحزمة؛ لذلك يجب تنفيذ اختبار البناء والنشر في بيئتك.
