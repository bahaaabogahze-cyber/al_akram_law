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

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

async function callGemini(prompt: string, systemInstruction: string) {
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
      generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
    }),
  });
  const payload = await response.json();
  if (!response.ok) {
    const message = payload.error?.message || 'تعذر الاتصال بخدمة Gemini.';
    throw new Error(`Gemini API: ${message}`);
  }
  const text = payload.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? '').join('').trim();
  if (!text) throw new Error('لم يرجع Gemini نتيجة نصية. تحقق من إعداد النموذج أو من محتوى الطلب.');
  return { text, model, usage: payload.usageMetadata ?? {} };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const json = (data: unknown, status = 200) => new Response(JSON.stringify(data), {
    status, headers: { ...corsHeaders, 'Content-Type': 'application/json; charset=utf-8' },
  });
  try {
    if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
    const authorization = req.headers.get('Authorization');
    if (!authorization) return json({ error: 'يلزم تسجيل الدخول.' }, 401);
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    if (!supabaseUrl || !anonKey) return json({ error: 'إعدادات Supabase غير مكتملة.' }, 500);
    if (!Deno.env.get('GEMINI_API_KEY')) return json({ error: 'مفتاح Gemini غير مضاف. أضف GEMINI_API_KEY إلى Supabase Secrets.' }, 503);

    const db = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authorization } } });
    const adminDb = createAdminDb(supabaseUrl);
    const { data: authData, error: authError } = await db.auth.getUser();
    if (authError || !authData.user) return json({ error: 'جلسة الدخول غير صالحة.' }, 401);
    const body = await req.json();
    const caseId = String(body.caseId ?? '').trim();
    if (!caseId) return json({ error: 'رقم القضية مطلوب.' }, 400);

    const { data: caseRow, error: caseError } = await db.from('cases').select('*').eq('id', caseId).single();
    if (caseError || !caseRow) return json({ error: 'القضية غير موجودة أو لا تملك صلاحية الوصول إليها.' }, 404);
    const { data: docs, error: docsError } = await db.from('documents').select('title,notes,ocr_text,created_at').eq('case_id', caseId).order('created_at', { ascending: false }).limit(30);
    const { data: hearings, error: hearingsError } = await db.from('hearings').select('title,court,hearing_at,notes,status').eq('case_id', caseId).order('hearing_at', { ascending: true }).limit(20);
    const { data: tasks, error: tasksError } = await db.from('tasks').select('title,description,due_at,priority,completed').eq('case_id', caseId).order('due_at', { ascending: true }).limit(30);
    if (docsError || hearingsError || tasksError) return json({ error: 'تعذر جلب بعض بيانات القضية. تحقق من صلاحيات الجداول.' }, 500);

    const queryText = [caseRow.title, caseRow.case_type, caseRow.summary, caseRow.opponent].filter(Boolean).join(' ');
    let legalRefs: unknown[] = [];
    if (queryText) {
      const { data, error } = await db.rpc('search_legal_articles', { q: queryText.slice(0, 700), category: null, max_results: 8 });
      if (!error) legalRefs = data ?? [];
    }
    const source = {
      case: caseRow,
      documents: (docs ?? []).map((d) => ({ title: d.title, notes: d.notes, extractedText: (d.ocr_text ?? '').toString().slice(0, 5000) })),
      hearings: hearings ?? [], tasks: tasks ?? [], legalReferences: legalRefs,
    };
    const prompt = `أنت مساعد بحث قانوني للمحامي. حلل البيانات التالية باللغة العربية الفصحى وبشكل منظم. لا تخترع وقائع أو مواد قانونية. ميّز بوضوح بين المعلومات الواردة والافتراضات والنواقص. لا تعتبر التحليل رأياً قانونياً نهائياً، واذكر ضرورة مراجعة النصوص النافذة ومصادرها. أعد JSON صالحاً فقط بالمفاتيح: parties (array), facts (array), dates (array), obligations (array), documents (array), legal_issues (array), references (array), missing_information (array), suggested_next_steps (array), cautions (array). كل عنصر يمكن أن يكون نصاً أو كائناً صغيراً يتضمن description وsource. المراجع يجب أن تأتي حصراً من legalReferences المرفقة ولا تنسب إليها حكماً غير موجود.\n\nالبيانات:\n${JSON.stringify(source).slice(0, 24000)}`;
    const ai = await callGemini(prompt, 'أخرج JSON صالحاً فقط. لا تختلق مراجع أو وقائع.');
    const usage = ai.usage as Record<string, number>;
    if (adminDb) {
      const { error: logError } = await adminDb.from('ai_usage_logs').insert({ user_id: authData.user.id, function_name: 'analyze-case', model: ai.model, input_tokens: Number(usage.promptTokenCount ?? 0), output_tokens: Number(usage.candidatesTokenCount ?? 0) });
      if (logError) console.error('AI usage log insert failed:', logError.message);
    } else {
      console.error('No Supabase secret/service-role key is available; AI usage was not logged.');
    }
    let analysis: unknown;
    try { analysis = JSON.parse(ai.text); } catch { return json({ error: 'أعاد Gemini نتيجة ليست JSON صالحاً. أعد المحاولة.' }, 502); }
    const { error: saveError } = await db.from('case_analyses').insert({ user_id: authData.user.id, case_id: caseId, analysis, model: ai.model });
    if (saveError) return json({ error: `اكتمل التحليل لكن تعذر حفظه: ${saveError.message}`, analysis }, 500);
    return json({ analysis, model: ai.model, provider: 'gemini' });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : 'حدث خطأ غير متوقع.' }, 500);
  }
});
