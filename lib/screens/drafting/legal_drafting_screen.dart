import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/colors.dart';

class LegalDraftingScreen extends StatefulWidget {
  const LegalDraftingScreen({super.key});
  @override
  State<LegalDraftingScreen> createState() => _LegalDraftingScreenState();
}

class _LegalDraftingScreenState extends State<LegalDraftingScreen> {
  String _template = 'مذكرة قانونية';
  final _facts = TextEditingController();
  final _requests = TextEditingController();
  final _notes = TextEditingController();
  String _output = '';

  final _templates = const ['مذكرة قانونية','لائحة دعوى','مذكرة دفاع','إنذار عدلي','طلب عام'];

  @override
  void dispose() {
    _facts.dispose(); _requests.dispose(); _notes.dispose(); super.dispose();
  }

  void _generate() {
    final title = _template;
    final facts = _facts.text.trim().isEmpty ? 'يُرجى إدخال وقائع القضية.' : _facts.text.trim();
    final req = _requests.text.trim().isEmpty ? 'يُرجى إدخال الطلبات القانونية.' : _requests.text.trim();
    final notes = _notes.text.trim();
    setState(() {
      _output = "$title\n\nأولاً: الوقائع\n$facts\n\nثانياً: الطلبات\n$req\n\nثالثاً: الملاحظات والأساس القانوني\n${notes.isEmpty ? 'يُضاف الأساس القانوني والنصوص والاجتهادات بعد مراجعتها من المحامي.' : notes}\n\nالخاتمة\nمع الاحتفاظ بكافة الحقوق والدفوع القانونية.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصياغة القانونية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _template,
            decoration: const InputDecoration(labelText: 'نوع المستند', border: OutlineInputBorder()),
            items: _templates.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _template = v!),
          ),
          const SizedBox(height: 14),
          _field(_facts, 'وقائع القضية', Icons.description, 6),
          _field(_requests, 'الطلبات', Icons.gavel, 4),
          _field(_notes, 'النصوص أو الملاحظات التي تريد إدراجها', Icons.menu_book, 5),
          FilledButton.icon(
            onPressed: _generate,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('إنشاء مسودة أولية'),
          ),
          const SizedBox(height: 16),
          if (_output.isNotEmpty) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('المسودة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                const SizedBox(height: 10),
                SelectableText(_output),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _output));
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ المسودة')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('نسخ النص'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('هذه صياغة أولية للمساعدة في العمل وليست بديلاً عن مراجعة المحامي للنصوص النافذة والوقائع والاختصاص والمواعيد.'))),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, int lines) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c, minLines: lines, maxLines: lines, textDirection: TextDirection.rtl,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.primary), border: const OutlineInputBorder()),
    ),
  );
}
