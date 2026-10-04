# الأكرم للمحاماة — النسخة المدمجة V2.7

## محتويات الدمج
- المشروع الأصلي كاملاً دون حذف ملفات التطبيق أو قواعد البيانات المحلية.
- لوحة الإدارة المستقلة داخل `admin_dashboard/index.html`.
- نسختا Edge Functions المحدثتان: `legal-assistant` و`analyze-case`.
- ملف ترحيل إضافي `supabase/migrations/0014_admin_dashboard_compatibility.sql` لمعالجة صلاحيات عرض المستخدمين وإجراءات الاشتراك ولوحة الإدارة.
- رفع رقم إصدار Flutter إلى `2.7.0+10` دون تغيير الاعتماديات.

## مهم قبل الاستخدام
1. احتفظ بنسخة احتياطية من مشروعك الحالي.
2. لا تشغّل `supabase/reference/0013_ALAKRAM_ADMIN_COMPLETE_ALREADY_APPLIED_REFERENCE.sql`؛ هذا مرجع فقط لملف سبق تنفيذه.
3. راجع ثم نفّذ مرة واحدة ملف `supabase/migrations/0014_admin_dashboard_compatibility.sql` من Supabase SQL Editor. هذا الملف إضافي، ولا يحذف المستخدمين أو القضايا أو المستندات.
4. في Supabase Edge Function Secrets تأكد من وجود `GEMINI_API_KEY` و`SUPABASE_SERVICE_ROLE_KEY`. أضف/تحقق من المفتاح على الخادم فقط؛ لا تضعه في Flutter أو لوحة HTML أو GitHub. لا تشارك المفتاح مع أحد.
5. انشر الوظيفتين:
   - `supabase functions deploy legal-assistant`
   - `supabase functions deploy analyze-case`
6. افتح `admin_dashboard/index.html` عبر استضافة HTTPS، وأدخل Supabase Project URL وPublishable/anon key فقط، ثم سجّل الدخول بحساب المدير.

## التوافق الذي عولج
- قاعدة البيانات الحالية تعتمد `admin` و`user`؛ لوحة الإدارة الآن تستخدم `user` بدلاً من `lawyer` عند استدعاء RPC تغيير الدور.
- تسجيل `ai_usage_logs` يتم من Edge Functions باستخدام `SUPABASE_SERVICE_ROLE_KEY` على الخادم، وليس من جلسة المستخدم؛ وهذا يطابق صلاحيات جدول السجل في SQL السابق.
- صلاحيات لوحة الإدارة وإجراءات الاشتراك أضيفت في ترحيل 0014 منفصل، دون إعادة تشغيل 0013.

## ما لم يتم تغييره / ما يحتاج خطوة لاحقة
- شاشة صياغة العقود في Flutter ما زالت تستخدم النماذج المحلية الحالية وتحفظ المسودات محلياً؛ لم يتم ربطها بعد بجدول `contract_templates`، لذلك إضافة نموذج من لوحة الإدارة لن تجعله يظهر تلقائياً في شاشة الصياغة قبل تطوير هذا الربط.
- لا يوجد احتساب فعلي لتكلفة Gemini بالدولار أو فرض حصص شهرية تلقائية؛ السجل يحفظ أعداد الرموز فقط.
- الاشتراكات يدوية عبر لوحة الإدارة، وليست بوابة دفع إلكتروني.

## الفحوصات
- تم فحص سلامة أرشيفي المصدر وقراءة ملفات الدمج قبل إنشاء هذه النسخة.
- تم الحفاظ على ملفات migrations القانونية والبيانات الأصلية كما هي.
- لم يتم تشغيل Flutter build أو `flutter analyze` أو نشر Edge Functions أو تنفيذ SQL على مشروع Supabase الفعلي في هذه البيئة. نفّذ الاختبارات محلياً قبل توزيع APK.
