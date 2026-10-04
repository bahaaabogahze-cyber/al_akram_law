import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';
import '../../services/case_ai_service.dart';
import '../../services/legal_assistant_service.dart';
import '../documents/documents_screen.dart';
import '../research/legal_research_screen.dart';
import 'add_case_screen.dart';

class CaseDetailsScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailsScreen({super.key, required this.caseId});
  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  Map<String, dynamic>? _case;
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _hearings = [];
  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _analysis;
  bool _analyzing = false;
  final TextEditingController _assistantController = TextEditingController();
  final List<Map<String, dynamic>> _assistantMessages = [];
  bool _askingAssistant = false;

  @override
  void dispose() {
    _assistantController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cases = await LocalStore.getCases();
    final docs = await LocalStore.getDocuments();
    final hearings = await LocalStore.getHearings();
    final tasks = await LocalStore.getTasks();
    Map<String, dynamic>? previousAnalysis;
    try { previousAnalysis = await CaseAiService.latestAnalysis(widget.caseId); } catch (_) {}
    final match = cases.where((c) => c['id'].toString() == widget.caseId).toList();
    if (!mounted) return;
    setState(() {
      _case = match.isEmpty ? null : match.first;
      _documents = docs.where((d) => d['caseId']?.toString() == widget.caseId).toList();
      _hearings = hearings.where((h) => h['caseId']?.toString() == widget.caseId).toList();
      _tasks = tasks.where((t) => t['caseId']?.toString() == widget.caseId).toList();
      _analysis ??= previousAnalysis;
    });
  }


  Future<void> _runAnalysis() async {
    setState(() => _analyzing = true);
    try {
      final result = await CaseAiService.analyzeCase(widget.caseId);
      if (!mounted) return;
      setState(() => _analysis = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتمل تحليل القضية وحُفظ في سجل التحليلات.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _askLegalAssistant([String? suggested]) async {
    final question = (suggested ?? _assistantController.text).trim();
    if (question.isEmpty || _askingAssistant) return;
    _assistantController.clear();
    setState(() {
      _askingAssistant = true;
      _assistantMessages.add({'role': 'user', 'text': question});
    });
    try {
      final result = await LegalAssistantService.ask(caseId: widget.caseId, question: question);
      if (!mounted) return;
      setState(() => _assistantMessages.add({
        'role': 'assistant',
        'text': result['answer']?.toString() ?? 'لم تصل إجابة.',
        'sources': result['sources'] is List ? result['sources'] : [],
        'notFound': result['not_found'] == true,
      }));
    } catch (e) {
      if (!mounted) return;
      setState(() => _assistantMessages.add({'role': 'error', 'text': e.toString().replaceFirst('Exception: ', '')}));
    } finally {
      if (mounted) setState(() => _askingAssistant = false);
    }
  }

  Widget _buildLegalAssistant() {
    final suggestions = [
      'ما المواد القانونية المرتبطة بهذه القضية؟',
      'ما المستندات الموجودة في القضية؟',
      'ما الجلسة القادمة؟',
      'استخرج تواريخ انتهاء العقود والالتزامات من المستندات.',
      'ابحث في مستندات القضية عن مبلغ 50 مليون.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.support_agent, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('مساعد المحامي المتكامل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 6),
          const Text('يسأل عن هذه القضية بالاستناد إلى بياناتها ومستنداتها وجلساتها والمهام والمراجع القانونية المتاحة. كل إجابة تعرض مصادرها.'),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: suggestions.map((q) => ActionChip(
            label: Text(q, style: const TextStyle(fontSize: 11)),
            onPressed: _askingAssistant ? null : () => _askLegalAssistant(q),
          )).toList()),
          if (_assistantMessages.isNotEmpty) ...[
            const Divider(height: 24),
            ..._assistantMessages.map((m) {
              final role = m['role'];
              final isUser = role == 'user';
              final sources = m['sources'] is List ? m['sources'] as List : const [];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary.withValues(alpha: .06) : Colors.grey.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: role == 'error' ? AppColors.error.withValues(alpha: .4) : Colors.black12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isUser ? 'سؤالك' : role == 'error' ? 'تعذر تنفيذ السؤال' : 'إجابة المساعد', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  SelectableText(m['text']?.toString() ?? ''),
                  if (sources.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    const Text('مصادر الإجابة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ...sources.map((source) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• ${(source is Map ? source['title'] : null) ?? 'مصدر'}${source is Map && source['detail'] != null ? ' — ${source['detail']}' : ''}', style: const TextStyle(fontSize: 12)),
                    )),
                  ],
                ]),
              );
            }),
          ],
          if (_askingAssistant) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: _assistantController,
              minLines: 1, maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _askLegalAssistant(),
              decoration: const InputDecoration(hintText: 'اكتب سؤالك عن هذه القضية...', border: OutlineInputBorder(), isDense: true),
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _askingAssistant ? null : () => _askLegalAssistant(),
              icon: const Icon(Icons.send), tooltip: 'إرسال السؤال',
            ),
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('تنبيه: قد تكون النصوص المستخرجة آلياً ناقصة. راجع المستند الأصلي والمصدر القانوني قبل الاعتماد على الإجابة.', style: TextStyle(fontSize: 11, color: Colors.deepOrange)),
          ),
        ]),
      ),
    );
  }

  Widget _smartList(String title, dynamic values, IconData icon) {
    final items = values is List ? values : const [];
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items.isEmpty
            ? [const ListTile(title: Text('لا توجد بيانات مرتبطة حالياً.'))]
            : items.map<Widget>((item) => ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 7),
                title: Text(item is Map ? (item['description'] ?? item['title'] ?? item.toString()).toString() : item.toString()),
                subtitle: item is Map && item['source'] != null ? Text('المصدر: ${item['source']}') : null,
              )).toList(),
      ),
    );
  }

  Widget _buildAnalysis() {
    final a = _analysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Expanded(child: Text('التحليل القانوني الذكي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Icon(Icons.auto_awesome, color: AppColors.primary),
          ]),
          const SizedBox(height: 8),
          const Text('يستخرج الأطراف والوقائع والتواريخ والالتزامات والمسائل القانونية، ويعرض المراجع المتاحة في مكتبتك القانونية.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _analyzing ? null : _runAnalysis,
            icon: _analyzing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.psychology_alt),
            label: Text(_analyzing ? 'جارٍ تحليل ملف القضية...' : a == null ? 'تحليل القضية الآن' : 'إعادة تحليل القضية'),
          ),
          if (a != null) ...[
            const SizedBox(height: 12),
            _smartList('الأطراف', a['parties'], Icons.people_outline),
            _smartList('الوقائع', a['facts'], Icons.subject),
            _smartList('التواريخ', a['dates'], Icons.calendar_month),
            _smartList('الالتزامات', a['obligations'], Icons.assignment_turned_in_outlined),
            _smartList('المستندات', a['documents'], Icons.description_outlined),
            _smartList('المسائل القانونية', a['legal_issues'], Icons.gavel),
            _smartList('المراجع القانونية', a['references'], Icons.menu_book_outlined),
            _smartList('المعلومات الناقصة', a['missing_information'], Icons.help_outline),
            _smartList('الخطوات المقترحة', a['suggested_next_steps'], Icons.checklist),
            _smartList('تنبيهات المراجعة', a['cautions'], Icons.warning_amber_outlined),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('تنبيه: هذا تحليل مساعد وليس رأياً قانونياً نهائياً. يجب مراجعة الوقائع والنصوص ومصادرها الرسمية.', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القضية؟'),
        content: const Text('سيتم حذف القضية وجميع المستندات المرتبطة بها من قاعدة البيانات. لا يمكن التراجع عن هذه العملية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await LocalStore.deleteCase(widget.caseId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_case == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _case!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل القضية'),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AddCaseScreen(existing: c)));
              _load();
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  _line('رقم القضية', c['caseNumber']),
                  _line('النوع', c['type']),
                  _line('الحالة', c['status']),
                  _line('الموكل', c['client']),
                  _line('الخصم', c['opponent']),
                  _line('المحكمة', c['court']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section('ملخص الوقائع', c['summary']),
          _section('ملاحظات المحامي', c['notes']),
          _buildAnalysis(),
          const SizedBox(height: 10),
          _buildLegalAssistant(),
          const SizedBox(height: 8),
          Text('الملف المرتبط بالقضية', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _smartList('الجلسات', _hearings.map((h) => {'description': '${h['title'] ?? 'جلسة'} – ${h['hearingAt'] ?? ''}', 'source': h['court'] ?? ''}).toList(), Icons.event),
          _smartList('المهام', _tasks.map((t) => {'description': '${t['title'] ?? 'مهمة'} – ${t['dueAt'] ?? 'دون موعد'}', 'source': t['completed'] == true ? 'مكتملة' : 'قيد التنفيذ'}).toList(), Icons.task_alt),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _action(Icons.camera_alt, 'مستند جديد', () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentsScreen(caseId: widget.caseId)));
                _load();
              })),
              const SizedBox(width: 10),
              Expanded(child: _action(Icons.search, 'بحث قانوني', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LegalResearchScreen(initialText: '${c['type']} ${c['summary']}')));
              })),
            ],
          ),
          const SizedBox(height: 16),
          Text('مستندات القضية (${_documents.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_documents.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد مستندات مرتبطة بهذه القضية.')))
          else ..._documents.map((d) => ListTile(
            leading: const Icon(Icons.description, color: AppColors.primary),
            title: Text(d['title'] ?? 'مستند'),
            subtitle: Text(d['createdAt'] ?? ''),
          )),
        ],
      ),
    );
  }

  Widget _line(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text('$label: ${value?.toString().isNotEmpty == true ? value : '-'}'),
  );

  Widget _section(String title, dynamic value) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text((value ?? '').toString().isEmpty ? 'لا يوجد' : value.toString()),
      ]),
    ),
  );

  Widget _action(IconData icon, String label, VoidCallback onTap) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
  );
}
