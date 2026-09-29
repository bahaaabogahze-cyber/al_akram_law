import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';

class AddCaseScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AddCaseScreen({super.key, this.existing});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _number;
  late final TextEditingController _court;
  late final TextEditingController _opponent;
  late final TextEditingController _summary;
  late final TextEditingController _notes;

  List<Map<String, dynamic>> _clients = [];
  String? _clientId;
  String _clientName = '';
  bool _loadingClients = true;
  bool _saving = false;
  String _type = 'مدنية';
  String _status = 'جارية';

  @override
  void initState() {
    super.initState();
    final c = widget.existing ?? {};
    _title = TextEditingController(text: c['title']?.toString() ?? '');
    _number = TextEditingController(text: c['caseNumber']?.toString() ?? '');
    _court = TextEditingController(text: c['court']?.toString() ?? '');
    _opponent = TextEditingController(text: c['opponent']?.toString() ?? '');
    _summary = TextEditingController(text: c['summary']?.toString() ?? '');
    _notes = TextEditingController(text: c['notes']?.toString() ?? '');
    _clientId = c['clientId']?.toString();
    _clientName = c['client']?.toString() ?? '';
    _type = c['type']?.toString() ?? 'مدنية';
    _status = c['status']?.toString() ?? 'جارية';
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await LocalStore.getClients();
      if (!mounted) return;
      String? selected = _clientId;
      if (selected == null && _clientName.trim().isNotEmpty) {
        final match = clients.where((c) =>
          (c['full_name'] ?? '').toString().trim() == _clientName.trim()).toList();
        if (match.isNotEmpty) selected = match.first['id']?.toString();
      }
      setState(() {
        _clients = clients;
        _clientId = selected;
        _loadingClients = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingClients = false);
        _showError('تعذر تحميل الموكلين: $e');
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _number, _court, _opponent, _summary, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_clientId == null || _clientId!.isEmpty) {
      _showError('يرجى اختيار الموكل من قائمة الموكلين');
      return;
    }

    Map<String, dynamic>? selectedClient;
    for (final client in _clients) {
      if (client['id']?.toString() == _clientId) {
        selectedClient = client;
        break;
      }
    }
    final clientName = selectedClient?['full_name']?.toString().trim() ?? _clientName.trim();
    if (clientName.isEmpty) {
      _showError('تعذر تحديد اسم الموكل');
      return;
    }

    setState(() => _saving = true);
    try {
      final id = widget.existing?['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
      await LocalStore.saveCase({
        'id': id,
        'title': _title.text.trim(),
        'caseNumber': _number.text.trim(),
        'clientId': _clientId,
        'client': clientName,
        'court': _court.text.trim(),
        'opponent': _opponent.text.trim(),
        'summary': _summary.text.trim(),
        'notes': _notes.text.trim(),
        'type': _type,
        'status': _status,
        'createdAt': widget.existing?['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await LocalStore.addNotification(
        widget.existing == null ? 'تم إنشاء قضية جديدة' : 'تم تحديث القضية',
        '${_title.text.trim()} - ${_number.text.trim()}',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('تعذر حفظ القضية: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'إضافة قضية' : 'تعديل القضية')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_title, 'اسم/عنوان القضية', Icons.folder, required: true),
            _field(_number, 'رقم القضية والسنة', Icons.tag, required: true),
            _clientDropdown(),
            _field(_court, 'المحكمة والمرجع', Icons.account_balance, required: true),
            _field(_opponent, 'الخصم', Icons.people_outline),
            _dropdown('نوع القضية', _type, ['مدنية','جزائية','أحوال شخصية','تجارية','عمالية','عقارية','إدارية','إيجارات'],
                (v) => setState(() => _type = v!)),
            _dropdown('حالة القضية', _status, ['جارية','مؤجلة','منتهية'],
                (v) => setState(() => _status = v!)),
            _field(_summary, 'ملخص الوقائع', Icons.description, maxLines: 5),
            _field(_notes, 'ملاحظات المحامي', Icons.notes, maxLines: 5),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ القضية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _loadingClients
          ? const InputDecorator(
              decoration: InputDecoration(labelText: 'الموكل', border: OutlineInputBorder()),
              child: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('جارٍ تحميل الموكلين...')]),
            )
          : DropdownButtonFormField<String>(
              value: _clients.any((c) => c['id']?.toString() == _clientId) ? _clientId : null,
              decoration: InputDecoration(
                labelText: 'الموكل',
                prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: Text(_clients.isEmpty ? 'لا يوجد موكلون، أضف موكلاً أولاً' : 'اختر الموكل'),
              items: _clients.map((c) => DropdownMenuItem<String>(
                value: c['id']?.toString(),
                child: Text(c['full_name']?.toString() ?? 'بدون اسم'),
              )).toList(),
              onChanged: _clients.isEmpty ? null : (v) {
                final c = _clients.firstWhere((x) => x['id']?.toString() == v);
                setState(() { _clientId = v; _clientName = c['full_name']?.toString() ?? ''; });
              },
              validator: (v) => v == null || v.isEmpty ? 'اختر الموكل' : null,
            ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: values.contains(value) ? value : values.first,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
