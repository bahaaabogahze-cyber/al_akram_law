import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/colors.dart';
import '../../services/legal_pdf_service.dart';
import '../../services/local_store.dart';

class LegalDraftingScreen extends StatefulWidget {
  const LegalDraftingScreen({super.key});
  @override
  State<LegalDraftingScreen> createState() => _LegalDraftingScreenState();
}

class _LegalDraftingScreenState extends State<LegalDraftingScreen> {
  static const Map<String, List<String>> _fields = {
    'عقد إيجار': ['اسم المؤجر','رقم هوية المؤجر','اسم المستأجر','رقم هوية المستأجر','وصف العقار','عنوان العقار','مدة العقد','تاريخ بداية العقد','تاريخ نهاية العقد','بدل الإيجار','طريقة دفع الأجرة','مبلغ التأمين','التزامات المؤجر','التزامات المستأجر','شروط إضافية'],
    'عقد بيع': ['اسم البائع','رقم هوية البائع','اسم المشتري','رقم هوية المشتري','وصف المبيع','الثمن','طريقة الدفع','تاريخ التسليم','شروط إضافية'],
    'وكالة خاصة': ['اسم الموكل','رقم هوية الموكل','اسم الوكيل','رقم هوية الوكيل','موضوع الوكالة وصلاحياتها','مدة الوكالة','شروط وحدود الوكالة'],
    'إنذار عدلي': ['اسم المنذر','اسم المنذر إليه','عنوان التبليغ','موضوع الإنذار','تفاصيل المطالبة','المهلة المطلوبة','الإجراء عند عدم التنفيذ'],
    'لائحة دعوى': ['اسم المدعي','اسم المدعى عليه','المحكمة المختصة','موضوع الدعوى','وقائع الدعوى','الأساس القانوني','الطلبات'],
    'مذكرة دفاع': ['اسم المدعى عليه','المحكمة المختصة','رقم القضية','وقائع الدعوى','الدفوع وأوجه الدفاع','الأساس القانوني','الطلبات'],
  };

  String _template = 'عقد إيجار';
  final Map<String, TextEditingController> _controllers = {};
  final _draftName = TextEditingController();
  String _output = '';
  String? _editingId;
  bool _busy = false;

  @override
  void initState() { super.initState(); _makeControllers(); }

  void _makeControllers() {
    for (final c in _controllers.values) { c.dispose(); }
    _controllers.clear();
    for (final label in _fields[_template]!) { _controllers[label] = TextEditingController(); }
    _output = '';
    _editingId = null;
    _draftName.text = _template;
  }

  @override
  void dispose() { for (final c in _controllers.values) { c.dispose(); } _draftName.dispose(); super.dispose(); }

  String _compose() {
    final b = StringBuffer('$_template\n\n');
    b.writeln('تم إعداد هذه المسودة بتاريخ ${DateTime.now().toLocal().toString().split('.').first}.');
    b.writeln('');
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      b.writeln('${entry.key}: ${value.isEmpty ? '........................' : value}');
      b.writeln('');
    }
    b.writeln('');
    b.writeln('التوقيعات:');
    b.writeln('الطرف الأول: ........................    الطرف الثاني: ........................');
    b.writeln('');
    b.writeln('تنبيه للمراجعة: هذه مسودة قابلة للتعديل، ويجب على المحامي مراجعة الوقائع والاختصاص والقانون الواجب التطبيق والشروط قبل اعتمادها أو توقيعها.');
    return b.toString();
  }

  void _generate() => setState(() => _output = _compose());

  Future<void> _save() async {
    if (_output.isEmpty) _generate();
    final id = _editingId ?? DateTime.now().microsecondsSinceEpoch.toString();
    await LocalStore.saveLegalDraft({
      'id': id, 'name': _draftName.text.trim().isEmpty ? _template : _draftName.text.trim(),
      'template': _template, 'content': _output,
      'values': _controllers.map((k, v) => MapEntry(k, v.text)),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (!mounted) return;
    setState(() => _editingId = id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المسودة على الجهاز.')));
  }

  Future<void> _openDrafts() async {
    final drafts = await LocalStore.getLegalDrafts();
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(
      child: SizedBox(height: MediaQuery.of(ctx).size.height * .65,
        child: drafts.isEmpty
          ? const Center(child: Text('لا توجد مسودات محفوظة بعد.'))
          : ListView.builder(itemCount: drafts.length, itemBuilder: (_, i) {
              final d = drafts[i];
              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(d['name']?.toString() ?? d['template']?.toString() ?? 'مسودة'),
                subtitle: Text(d['updatedAt']?.toString() ?? ''),
                onTap: () { Navigator.pop(ctx); _loadDraft(d); },
              );
            }),
      ),
    ));
  }

  void _loadDraft(Map<String, dynamic> draft) {
    final template = draft['template']?.toString();
    if (template == null || !_fields.containsKey(template)) return;
    setState(() {
      _template = template;
      _makeControllers();
      final values = draft['values'];
      if (values is Map) {
        for (final entry in values.entries) {
          if (_controllers.containsKey(entry.key.toString())) _controllers[entry.key.toString()]!.text = entry.value?.toString() ?? '';
        }
      }
      _draftName.text = draft['name']?.toString() ?? template;
      _output = draft['content']?.toString() ?? '';
      _editingId = draft['id']?.toString();
    });
  }

  Future<void> _exportPdf() async {
    if (_output.isEmpty) _generate();
    setState(() => _busy = true);
    try {
      final bytes = await LegalPdfService.textToPdf(_template, _output);
      await LegalPdfService.printOrShare(bytes, name: '${_draftName.text.trim().isEmpty ? _template : _draftName.text.trim()}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء PDF: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مكتبة العقود والنماذج'),
      actions: [IconButton(onPressed: _openDrafts, icon: const Icon(Icons.folder_open), tooltip: 'المسودات المحفوظة')],
    ),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(
        value: _template,
        decoration: const InputDecoration(labelText: 'اختر النموذج القانوني', border: OutlineInputBorder()),
        items: _fields.keys.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v == null) return; setState(() { _template = v; _makeControllers(); }); },
      ),
      const SizedBox(height: 14),
      TextField(controller: _draftName, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'اسم المسودة', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      ..._controllers.entries.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: entry.value,
          minLines: ['وقائع الدعوى','الأساس القانوني','الدفوع وأوجه الدفاع','التزامات المؤجر','التزامات المستأجر','شروط إضافية','موضوع الوكالة وصلاحياتها'].contains(entry.key) ? 3 : 1,
          maxLines: ['وقائع الدعوى','الأساس القانوني','الدفوع وأوجه الدفاع','التزامات المؤجر','التزامات المستأجر','شروط إضافية','موضوع الوكالة وصلاحياتها'].contains(entry.key) ? 4 : 2,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(labelText: entry.key, border: const OutlineInputBorder()),
        ),
      )),
      FilledButton.icon(onPressed: _generate, style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(50)), icon: const Icon(Icons.article), label: const Text('إنشاء العقد / المسودة')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ المسودة')),
      if (_output.isNotEmpty) ...[
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('معاينة المستند', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 17)),
          const SizedBox(height: 10),
          SelectableText(_output, textDirection: TextDirection.rtl),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: _output)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص'))); }, icon: const Icon(Icons.copy), label: const Text('نسخ')),
            FilledButton.icon(onPressed: _busy ? null : _exportPdf, icon: const Icon(Icons.picture_as_pdf), label: Text(_busy ? 'جارٍ التجهيز...' : 'PDF / طباعة / مشاركة')),
          ]),
        ]))),
      ],
      const SizedBox(height: 12),
      const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('النماذج قوالب أولية قابلة للتخصيص وليست استشارة أو صيغة معتمدة لكل دولة. يجب مراجعة القانون المحلي والبيانات والشروط قبل التوقيع.'))),
    ]),
  );
}
