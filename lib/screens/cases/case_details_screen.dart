import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cases = await LocalStore.getCases();
    final docs = await LocalStore.getDocuments();
    final match = cases.where((c) => c['id'].toString() == widget.caseId).toList();
    if (!mounted) return;
    setState(() {
      _case = match.isEmpty ? null : match.first;
      _documents = docs.where((d) => d['caseId']?.toString() == widget.caseId).toList();
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القضية؟'),
        content: const Text('سيتم حذف بيانات القضية من هذا الجهاز.'),
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
