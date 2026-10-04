import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CaseAiService {
  static Future<Map<String, dynamic>?> latestAnalysis(String caseId) async {
    if (!SupabaseService.isConfigured || SupabaseService.user == null) return null;
    final row = await SupabaseService.client
        .from('case_analyses')
        .select('analysis')
        .eq('case_id', caseId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final value = row?['analysis'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<Map<String, dynamic>> analyzeCase(String caseId) async {
    if (!SupabaseService.isConfigured || SupabaseService.user == null) {
      throw Exception('يجب تسجيل الدخول والاتصال بمشروع Supabase لاستخدام تحليل القضية.');
    }
    final response = await SupabaseService.client.functions.invoke(
      'analyze-case',
      body: {'caseId': caseId},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'تعذر تحليل القضية (HTTP ${response.status}).');
    }
    if (data is! Map || data['analysis'] is! Map) {
      throw Exception('استجابة التحليل غير مكتملة.');
    }
    return Map<String, dynamic>.from(data['analysis'] as Map);
  }
}
