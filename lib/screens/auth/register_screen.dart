import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/specialties.dart';
import '../../services/supabase_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _specialty; // optional

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    if (!SupabaseService.isConfigured) {
      _show('الاتصال بقاعدة البيانات غير مُعد. لا يمكن إنشاء الحساب حاليًا.');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      final response = await SupabaseService.signUp(
        email: email,
        password: _password.text,
        profile: {
          'full_name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'specialty': _specialty ?? '',
        },
      );

      if (response.user == null) {
        throw Exception('تعذر إنشاء الحساب. حاول مرة أخرى.');
      }

      // Store display information only. Never store the password locally.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _name.text.trim());
      await prefs.setString('userEmail', email);

      if (!mounted) return;

      if (response.session == null) {
        _show('تم إنشاء الحساب. تحقق من بريدك الإلكتروني ثم سجّل الدخول.');
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context);
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (mounted) _show(_friendlyAuthError(e));
    } catch (e) {
      if (mounted) _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('user already registered')) {
      return 'هذا البريد الإلكتروني مسجل مسبقًا. جرّب تسجيل الدخول.';
    }
    if (message.contains('password')) {
      return 'كلمة المرور غير صالحة. استخدم كلمة مرور أقوى.';
    }
    if (message.contains('email')) {
      return 'عنوان البريد الإلكتروني غير صالح أو غير مقبول.';
    }
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('socket') ||
        message.contains('failed host lookup') ||
        message.contains('host lookup')) {
      return 'تعذر الوصول إلى خادم Supabase. تحقق من الإنترنت أو أوقف VPN مؤقتًا ثم حاول مرة أخرى.';
    }
    return e.message;
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: !_loading,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                    ? 'هذا الحقل مطلوب'
                    : null
                : null),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'هذا الحقل مطلوب';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'أدخل بريدًا إلكترونيًا صحيحًا';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'هذا الحقل مطلوب';
    if (password.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'أعد إدخال كلمة المرور';
    if (value != _password.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب محامٍ')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _field(_name, 'اسم المحامي', Icons.person, required: true),
            _field(
              _email,
              'البريد الإلكتروني',
              Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            _field(
              _phone,
              'رقم الهاتف',
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _specialty,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'التخصص (اختياري)',
                  prefixIcon: const Icon(Icons.gavel),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  for (final s in kLegalSpecialties)
                    DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: _loading ? null : (v) => setState(() => _specialty = v),
              ),
            ),
            _field(
              _password,
              'كلمة المرور',
              Icons.lock,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
            _field(
              _confirmPassword,
              'تأكيد كلمة المرور',
              Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إنشاء الحساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
