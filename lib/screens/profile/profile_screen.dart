import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'المحامي';
  String email = '';
  String phone = '';
  String specialty = '';
  String bar = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = SupabaseService.isConfigured ? await SupabaseService.getProfile() : null;
      if (!mounted) return;
      if (row != null) {
        setState(() {
          name = row['full_name'] ?? 'المحامي'; email = row['email'] ?? ''; phone = row['phone'] ?? '';
          specialty = row['specialty'] ?? ''; bar = row['bar_number'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    if (SupabaseService.isConfigured) { await SupabaseService.signOut(); }

    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const CircleAvatar(radius: 42, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 45, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  if (specialty.isNotEmpty) Text(specialty, style: const TextStyle(color: Colors.black54)),
                  const Divider(height: 28),
                  _row(Icons.email_outlined, 'البريد', email),
                  _row(Icons.phone_outlined, 'الهاتف', phone),
                  _row(Icons.badge_outlined, 'رقم النقابة', bar),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.security), title: const Text('الخصوصية والأمان'), subtitle: Text(SupabaseService.isConfigured ? 'الحساب والبيانات مرتبطان بقاعدة بيانات Supabase الآمنة.' : 'الوضع المحلي مفعل. أضف إعدادات Supabase للربط السحابي.')),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.info_outline), title: const Text('حول التطبيق'), subtitle: const Text('منصة لإدارة العمل والبحث القانوني للمحامين السوريين، مع عزل بيانات كل حساب عن الآخرين.')),
              ],
            ),
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
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    subtitle: Text(value.isEmpty ? 'غير مضاف' : value),
  );
}
