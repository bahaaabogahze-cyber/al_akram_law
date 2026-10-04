# AL AKRAM V2.5 – Gemini & Secret-Key Cleanup

هذا المشروع يستخدم Google Gemini من خلال Supabase Edge Functions.

## مفاتيح الوصول المستخدمة
- Flutter يستخدم Supabase Publishable Key فقط، مع جلسة المستخدم وسياسات RLS.
- وظيفتا `analyze-case` و`legal-assistant` تقرآن `GEMINI_API_KEY` من Supabase Edge Function Secrets.
- لا يستخدم تطبيق Flutter أو وظائفه مفتاح Supabase Secret API Key / service_role.
- أزيل سكربت الصيانة `fix_articles.py` لأنه كان يحتاج مفتاح Supabase ذي صلاحيات مرتفعة، وهو غير مطلوب لتشغيل التطبيق.

راجع `docs/SECURITY_V2.5_AR.md` و`docs/GEMINI_V2.4_SETUP_AR.md` قبل النشر.

**مهم:** حذف الملف من هذه النسخة لا يمحو ظهوره من سجل GitHub السابق. يجب إلغاء المفتاح الذي سبق نشره، ثم تنظيف سجل Git إذا أردت إزالة الملف من تاريخ المستودع.
