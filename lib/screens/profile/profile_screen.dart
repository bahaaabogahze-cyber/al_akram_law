import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/colors.dart';
import '../../core/specialties.dart';
import '../../services/local_store.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'المحامي', email = '', phone = '', specialty = '', bar = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await LocalStore.getProfile();
      if (!mounted) return;
      setState(() {
        name = (row?['full_name'] ?? 'المحامي').toString();
        email = (row?['email'] ?? '').toString();
        phone = (row?['phone'] ?? '').toString();
        specialty = (row?['specialty'] ?? '').toString();
        bar = (row?['bar_number'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('تعذر تحميل بيانات الحساب: $e');
      }
    }
  }

  Future<void> _edit() async {
    final nameC = TextEditingController(text: name);
    final phoneC = TextEditingController(text: phone);
    String? selectedSpecialty = specialty.trim().isEmpty ? null : specialty.trim();
    final barC = TextEditingController(text: bar);
    final form = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('تعديل بيانات المحامي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _field(nameC, 'الاسم الكامل', Icons.person, required: true),
              _field(phoneC, 'الهاتف', Icons.phone),
              StatefulBuilder(
                builder: (context, setLocal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: selectedSpecialty,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'التخصص (اختياري)',
                      prefixIcon: const Icon(Icons.gavel),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      for (final s in [
                        ...kLegalSpecialties,
                        if (selectedSpecialty != null && !kLegalSpecialties.contains(selectedSpecialty)) selectedSpecialty!,
                      ])
                        DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setLocal(() => selectedSpecialty = v),
                  ),
                ),
              ),
              _field(barC, 'رقم النقابة (اختياري)', Icons.badge),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  try {
                    final data = {
                      'full_name': nameC.text.trim(),
                      'phone': phoneC.text.trim(),
                      'specialty': selectedSpecialty ?? '',
                      'bar_number': barC.text.trim(),
                    };
                    if (SupabaseService.isConfigured && SupabaseService.user != null) {
                      await SupabaseService.updateCurrentProfile(data);
                    } else {
                      final p = await SharedPreferences.getInstance();
                      await p.setString('userName', data['full_name']!);
                      await p.setString('userPhone', data['phone']!);
                      await p.setString('userSpecialty', data['specialty']!);
                      await p.setString('barNumber', data['bar_number']!);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load();
                  } catch (e) {
                    if (mounted) _snack('تعذر حفظ البيانات: $e');
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('حفظ'),
              ),
            ]),
          ),
        ),
      ),
    );
    nameC.dispose(); phoneC.dispose(); barC.dispose();
  }

  Future<void> _logout() async {
    try {
      if (SupabaseService.isConfigured && SupabaseService.user != null) {
        await SupabaseService.signOut();
      }
      final p = await SharedPreferences.getInstance();
      await p.setBool('isLoggedIn', false);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) _snack('تعذر تسجيل الخروج: $e');
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: c,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null : null,
        ),
      );

  void _snack(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [IconButton(onPressed: _loading ? null : _edit, icon: const Icon(Icons.edit))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(children: [
                        const CircleAvatar(radius: 42, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 45, color: Colors.white)),
                        const SizedBox(height: 12),
                        Text(name.isEmpty ? 'المحامي' : name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                        if (specialty.isNotEmpty) Text(specialty, style: const TextStyle(color: Colors.black54)),
                        const Divider(height: 28),
                        _row(Icons.email_outlined, 'البريد', email),
                        _row(Icons.phone_outlined, 'الهاتف', phone),
                        _row(Icons.badge_outlined, 'رقم النقابة', bar),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('الخصوصية والأمان'),
                        subtitle: Text(SupabaseService.isConfigured
                            ? 'الحساب والبيانات مرتبطان بقاعدة بيانات Supabase، وكل مستخدم معزول بسياسات RLS.'
                            : 'الوضع المحلي مفعل.'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('حول التطبيق'),
                        subtitle: Text('منصة لإدارة العمل والبحث القانوني والمستندات للمحامين.'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    subtitle: Text(value.isEmpty ? 'غير مضاف' : value),
  );
}
