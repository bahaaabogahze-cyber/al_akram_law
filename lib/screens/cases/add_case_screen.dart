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
  late final TextEditingController _client;
  late final TextEditingController _court;
  late final TextEditingController _opponent;
  late final TextEditingController _summary;
  late final TextEditingController _notes;
  String _type = 'مدنية';
  String _status = 'جارية';

  @override
  void initState() {
    super.initState();
    final c = widget.existing ?? {};
    _title = TextEditingController(text: c['title'] ?? '');
    _number = TextEditingController(text: c['caseNumber'] ?? '');
    _client = TextEditingController(text: c['client'] ?? '');
    _court = TextEditingController(text: c['court'] ?? '');
    _opponent = TextEditingController(text: c['opponent'] ?? '');
    _summary = TextEditingController(text: c['summary'] ?? '');
    _notes = TextEditingController(text: c['notes'] ?? '');
    _type = c['type'] ?? 'مدنية';
    _status = c['status'] ?? 'جارية';
  }

  @override
  void dispose() {
    for (final c in [_title, _number, _client, _court, _opponent, _summary, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final id = widget.existing?['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
    await LocalStore.saveCase({
      'id': id,
      'title': _title.text.trim(),
      'caseNumber': _number.text.trim(),
      'client': _client.text.trim(),
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
    if (mounted) Navigator.pop(context);
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
            _field(_client, 'اسم الموكل', Icons.person, required: true),
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
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('حفظ القضية'),
            ),
          ],
        ),
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
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
