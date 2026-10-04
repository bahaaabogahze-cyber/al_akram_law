import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class LegalAssistantService {
  static Future<Map<String, dynamic>> ask({required String caseId, required String question}) async {
    if (!SupabaseService.isConfigured || SupabaseService.user == null) {
      throw Exception('يجب تسجيل الدخول والاتصال بـ Supabase لاستخدام المساعد القانوني.');
    }
    final response = await SupabaseService.client.functions.invoke(
      'legal-assistant', body: {'caseId': caseId, 'question': question},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'تعذر الحصول على إجابة المساعد (HTTP ${response.status}).');
    }
    if (data is! Map || data['answer'] == null) throw Exception('استجابة المساعد غير مكتملة.');
    return Map<String, dynamic>.from(data);
  }
}
