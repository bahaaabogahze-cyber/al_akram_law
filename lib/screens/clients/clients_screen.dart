import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;
  String _query = '';

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final data = await LocalStore.getClients();
      if (mounted) setState(() { _clients = data; _loading = false; });
    } catch (e) { if (mounted) { setState(() => _loading = false); _snack('تعذر تحميل الموكلين: $e'); } }
  }

  List<Map<String, dynamic>> get _filtered => _clients.where((c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return ['full_name','phone','email','national_id','address'].any((k) => (c[k] ?? '').toString().toLowerCase().contains(q));
  }).toList();

  Future<void> _showEditor([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(text: existing?['full_name'] ?? '');
    final national = TextEditingController(text: existing?['national_id'] ?? '');
    final phone = TextEditingController(text: existing?['phone'] ?? '');
    final email = TextEditingController(text: existing?['email'] ?? '');
    final address = TextEditingController(text: existing?['address'] ?? '');
    final notes = TextEditingController(text: existing?['notes'] ?? '');
    final form = GlobalKey<FormState>();
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
      child: Form(key: form, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(existing == null ? 'إضافة موكل' : 'تعديل بيانات الموكل', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _field(name, 'الاسم الكامل', Icons.person, required: true),
        _field(national, 'الرقم الوطني', Icons.badge),
        _field(phone, 'الهاتف', Icons.phone, type: TextInputType.phone),
        _field(email, 'البريد الإلكتروني', Icons.email, type: TextInputType.emailAddress),
        _field(address, 'العنوان', Icons.location_on),
        _field(notes, 'ملاحظات', Icons.notes, maxLines: 3),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () async {
          if (!form.currentState!.validate()) return;
          final item = {
            'id': existing?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
            'full_name': name.text.trim(), 'national_id': national.text.trim(), 'phone': phone.text.trim(),
            'email': email.text.trim(), 'address': address.text.trim(), 'notes': notes.text.trim(),
          };
          try { await LocalStore.saveClient(item); if (ctx.mounted) Navigator.pop(ctx); await _load(); }
          catch (e) { if (mounted) _snack('تعذر حفظ الموكل: $e'); }
        }, icon: const Icon(Icons.save), label: const Text('حفظ البيانات')),
      ]))),
    ));
    for (final c in [name,national,phone,email,address,notes]) c.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder());
  Widget _field(TextEditingController c, String label, IconData icon, {bool required = false, TextInputType? type, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: c, keyboardType: type, maxLines: maxLines, textDirection: TextDirection.rtl, decoration: _dec(label, icon), validator: required ? (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null : null));
  void _snack(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: AppBar(title: const Text('الموكلون')), body: Column(children: [
      Container(color: AppColors.primary, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: TextField(controller: _search, onChanged: (v) => setState(() => _query = v), textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.black), decoration: InputDecoration(hintText: 'ابحث باسم الموكل أو الهاتف أو الرقم الوطني', filled: true, fillColor: Colors.white, prefixIcon: const Icon(Icons.search), suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.clear)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: _stat('${_clients.length}', 'إجمالي الموكلين', Icons.people)), const SizedBox(width: 10), Expanded(child: _stat('${_clients.where((c) => (c['notes'] ?? '').toString().isNotEmpty).length}', 'لديهم ملاحظات', Icons.notes))])),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _filtered.isEmpty ? const Center(child: Text('لا توجد بيانات موكلين بعد.')) : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filtered.length, itemBuilder: (_, i) => _card(_filtered[i])))),
    ]), floatingActionButton: FloatingActionButton.extended(onPressed: () => _showEditor(), backgroundColor: AppColors.primary, icon: const Icon(Icons.person_add, color: Colors.white), label: const Text('إضافة موكل', style: TextStyle(color: Colors.white))));
  }
  Widget _stat(String n, String l, IconData i) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Icon(i, color: AppColors.primary), const SizedBox(height: 4), Text(n, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)), Text(l, style: const TextStyle(fontSize: 11))])));
  Widget _card(Map<String, dynamic> c) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: () => _showEditor(c), leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(.1), child: Text((c['full_name'] ?? 'م').toString().characters.first, style: const TextStyle(color: AppColors.primary))), title: Text(c['full_name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text([if ((c['phone'] ?? '').toString().isNotEmpty) '📞 ${c['phone']}', if ((c['national_id'] ?? '').toString().isNotEmpty) '🪪 ${c['national_id']}'].join('\n')), trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'delete') { await LocalStore.deleteClient(c['id'].toString()); await _load(); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('حذف'))])));
}
