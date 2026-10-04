# AL AKRAM V2.5 – GEMINI & SECRET-KEY CLEANUP

هذا الإصدار مبني على V2.4. أزيل منه سكربت الصيانة `fix_articles.py` بالكامل لأنه كان يحتاج إلى Supabase Secret API Key للكتابة الإدارية في جدول `legal_articles`، بينما لا يحتاج التطبيق إلى هذا السكربت كي يعمل.

## إعداد المفاتيح
1. أبقِ `GEMINI_API_KEY` في Supabase → Edge Functions → Secrets.
2. Flutter يستخدم `sb_publishable_...` فقط.
3. لا تضف `sb_secret_...` أو `service_role` إلى Flutter أو GitHub أو إعدادات التطبيق.
4. لا تحتاج إلى المفتاح المخصص الجديد `alakram_server_v2` لتشغيل هذا الإصدار.

اقرأ `docs/SECURITY_V2.5_AR.md` لمعرفة ما يجب فعله بالمفتاح القديم الذي ظهر في V2.3 وGitHub.
