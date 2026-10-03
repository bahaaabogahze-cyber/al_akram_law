import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

function createAdminDb(url: string) {
  // Supabase's new secret API keys are exposed as a JSON map in Edge Functions.
  const secretKeysJson = Deno.env.get('SUPABASE_SECRET_KEYS') ?? '';
  if (secretKeysJson) {
    try {
      const secretKeys = JSON.parse(secretKeysJson) as Record<string, string>;
      const secretKey = secretKeys.default;
      if (secretKey) {
        // New sb_secret keys must be sent in the apikey header only, not as a Bearer JWT.
        const fetchWithoutBearer: typeof fetch = (input, init) => {
          const headers = new Headers(init?.headers);
          headers.delete('Authorization');
          return fetch(input, { ...init, headers });
        };
        return createClient(url, secretKey, { global: { fetch: fetchWithoutBearer } });
      }
    } catch (error) {
      console.error('Could not read SUPABASE_SECRET_KEYS:', error instanceof Error ? error.message : 'invalid JSON');
    }
  }

  // Backward compatibility for projects that still expose the legacy service_role key.
  const legacyServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  return legacyServiceRoleKey ? createClient(url, legacyServiceRoleKey) : null;
}

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

async function callGemini(systemInstruction: string, prompt: string) {
  const apiKey = Deno.env.get('GEMINI_API_KEY') ?? '';
  if (!apiKey) throw new Error('مفتاح Gemini غير مضاف. أضف GEMINI_API_KEY إلى Supabase Secrets.');
  const model = Deno.env.get('GEMINI_MODEL') || 'gemini-2.5-flash';
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: systemInstruction }] },
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.1, responseMimeType: 'application/json' },
    }),
  });
  const payload = await response.json();
  if (!response.ok) throw new Error(`Gemini API: ${payload.error?.message || 'تعذر الاتصال بخدمة Gemini.'}`);
  const text = payload.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? '').join('').trim();
  if (!text) throw new Error('لم تصل إجابة نصية من Gemini.');
  return { text, model, usage: payload.usageMetadata ?? {} };
}

Deno.serve(async (req) => {
  const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
    status, headers: { ...cors, 'Content-Type': 'application/json; charset=utf-8' },
  });
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
    const authorization = req.headers.get('Authorization');
    if (!authorization) return json({ error: 'يلزم تسجيل الدخول.' }, 401);
    const url = Deno.env.get('SUPABASE_URL') ?? '';
    const anon = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    if (!url || !anon) return json({ error: 'إعدادات Supabase غير مكتملة.' }, 500);
    if (!Deno.env.get('GEMINI_API_KEY')) return json({ error: 'مفتاح Gemini غير مضاف. أضف GEMINI_API_KEY إلى Supabase Secrets.' }, 503);

    const db = createClient(url, anon, { global: { headers: { Authorization: authorization } } });
    const adminDb = createAdminDb(url);
    const { data: auth, error: authError } = await db.auth.getUser();
    if (authError || !auth.user) return json({ error: 'جلسة الدخول غير صالحة.' }, 401);
    const body = await req.json();
    const question = String(body.question ?? '').trim();
    const caseId = String(body.caseId ?? '').trim();
    if (!question || question.length > 3000) return json({ error: 'اكتب سؤالاً لا يتجاوز 3000 حرف.' }, 400);
    if (!caseId) return json({ error: 'رقم القضية مطلوب.' }, 400);

    const { data: c, error: ce } = await db.from('cases').select('*').eq('id', caseId).single();
    if (ce || !c) return json({ error: 'القضية غير موجودة أو لا تملك صلاحية الوصول إليها.' }, 404);
    const [docRes, hearingRes, taskRes] = await Promise.all([
      db.from('documents').select('id,title,notes,ocr_text,created_at').eq('case_id', caseId).order('created_at', { ascending: false }).limit(40),
      db.from('hearings').select('id,title,court,hearing_at,notes,status').eq('case_id', caseId).order('hearing_at', { ascending: true }).limit(30),
      db.from('tasks').select('id,title,description,due_at,priority,completed').eq('case_id', caseId).order('due_at', { ascending: true }).limit(40),
    ]);
    if (docRes.error || hearingRes.error || taskRes.error) return json({ error: 'تعذر جلب بعض بيانات القضية. تحقق من صلاحيات الجداول والترحيلات.' }, 500);

    const docs = docRes.data ?? [];
    const hearings = hearingRes.data ?? [];
    const tasks = taskRes.data ?? [];
    const legalQuery = [question, c.title, c.case_type, c.summary].filter(Boolean).join(' ').slice(0, 700);
    const { data: refs } = await db.rpc('search_legal_articles', { q: legalQuery, category: null, max_results: 12 });
    const legalRefs = refs ?? [];
    const sourceCatalog = [
      { sourceId: `case:${caseId}`, type: 'case', title: c.title ?? 'ملف القضية', detail: `رقم القضية: ${c.case_number ?? 'غير محدد'}` },
      ...docs.map((d) => ({ sourceId: `document:${d.id}`, type: 'document', title: d.title ?? 'مستند', detail: `تاريخ الإضافة: ${d.created_at ?? 'غير محدد'}` })),
      ...hearings.map((h) => ({ sourceId: `hearing:${h.id}`, type: 'hearing', title: h.title ?? 'جلسة', detail: `موعد الجلسة: ${h.hearing_at ?? 'غير محدد'}` })),
      ...tasks.map((t) => ({ sourceId: `task:${t.id}`, type: 'task', title: t.title ?? 'مهمة', detail: `موعد الاستحقاق: ${t.due_at ?? 'غير محدد'}` })),
      ...legalRefs.map((r: Record<string, unknown>) => ({ sourceId: `legal:${r.id}`, type: 'legal_reference', title: `${r.source_title ?? 'مرجع قانوني'} – المادة ${r.article_number ?? ''}`, detail: String(r.title ?? r.article_number ?? '') })),
    ];
    const context = {
      sourceCatalog,
      case: { title: c.title, caseNumber: c.case_number, type: c.case_type, client: c.client_name, opponent: c.opponent, court: c.court, summary: c.summary, notes: c.notes },
      documents: docs.map((d) => ({ id: d.id, title: d.title, notes: d.notes, createdAt: d.created_at, extractedText: (d.ocr_text ?? '').toString().slice(0, 7000) })),
      hearings, tasks,
      legalReferences: legalRefs.map((r: Record<string, unknown>) => ({ id: r.id, sourceId: `legal:${r.id}`, sourceTitle: r.source_title, articleNumber: r.article_number, title: r.title, content: r.content })),
    };
    const system = `أنت مساعد محامٍ يعمل حصراً على بيانات القضية المقدمة. أجب بالعربية. لا تخترع أي معلومة أو مستند أو موعد أو مادة. إذا لم توجد معلومة قل إنها غير موجودة في البيانات المتاحة. أعد JSON صالحاً فقط بالشكل {"answer":"...","sources":[{"sourceId":"المعرف الحرفي من sourceCatalog"}],"not_found":false}. لا تنشئ sourceId ولا تخترع مصدراً. كل حقيقة محددة يجب أن تربط بمعرف موجود حرفياً في sourceCatalog. لا تنسب مادة قانونية إلا إلى legalReferences المقدمة، واذكر اسم المصدر ورقم المادة. لا تعتبر النتائج رأياً قانونياً نهائياً.`;
    const prompt = `سؤال المحامي: ${question}\n\nبيانات القضية ومصادرها:\n${JSON.stringify(context).slice(0, 65000)}\n\nأجب اعتماداً على هذه البيانات فقط. عند ذكر مستند أو جلسة أو مهمة أو مادة قانونية أرفق sourceId الصحيح من sourceCatalog. لا تكتب أي معرف آخر.`;
    const ai = await callGemini(system, prompt);
    const usage = ai.usage as Record<string, number>;
    if (adminDb) {
      const { error: logError } = await adminDb.from('ai_usage_logs').insert({ user_id: auth.user.id, function_name: 'legal-assistant', model: ai.model, input_tokens: Number(usage.promptTokenCount ?? 0), output_tokens: Number(usage.candidatesTokenCount ?? 0) });
      if (logError) console.error('AI usage log insert failed:', logError.message);
    } else {
      console.error('No Supabase secret/service-role key is available; AI usage was not logged.');
    }
    let result: Record<string, unknown>;
    try { result = JSON.parse(ai.text); } catch { return json({ error: 'أعاد Gemini نتيجة ليست JSON صالحاً. أعد المحاولة.' }, 502); }
    const allowedSources = new Map(sourceCatalog.map((source) => [source.sourceId, source]));
    const validatedSources = Array.isArray(result.sources)
      ? result.sources.map((source: Record<string, unknown>) => allowedSources.get(String(source.sourceId ?? ''))).filter(Boolean)
      : [];
    return json({ ...result, sources: validatedSources, provider: 'gemini', model: ai.model, contextCounts: { documents: docs.length, hearings: hearings.length, tasks: tasks.length, legalReferences: legalRefs.length } });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'حدث خطأ غير متوقع.' }, 500);
  }
});
