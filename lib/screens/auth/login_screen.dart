import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/supabase_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }

    setState(() => _loading = true);

    try {
      // Supabase Auth is the only authentication method.
      // The password is never stored in SharedPreferences.
      if (!SupabaseService.isConfigured) {
        throw Exception(
          'خدمة تسجيل الدخول غير مهيأة. تحقق من إعدادات Supabase.',
        );
      }

      final email = _email.text.trim();

      await SupabaseService.signIn(
        email,
        _password.text,
      );

      final profile = await SupabaseService.getProfile();

      // Store only non-sensitive display information locally.
      // Never store the password or an authentication credential here.
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'userName',
        (profile?['full_name'] ?? 'المحامي').toString(),
      );
      await prefs.setString('userEmail', email);

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        _show(_friendly(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _friendly(Object error) {
    final message = error.toString();

    if (message.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }

    if (message.contains('Email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول.';
    }

    if (message.contains('Network') ||
        message.contains('Socket') ||
        message.contains('Failed host lookup')) {
      return 'تعذر الاتصال بالخادم. تحقق من الإنترنت ثم حاول مرة أخرى.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A33),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.balance,
                color: Color(0xFFD4AF37),
                size: 90,
              ),
              const SizedBox(height: 15),
              const Text(
                'الأكرم للمحاماة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'نظام إدارة المحاماة السورية',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 45),
              Container(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF071A33),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: _dec(
                          'البريد الإلكتروني',
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'أدخل بريداً إلكترونياً صحيحاً';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: _dec(
                          'كلمة المرور',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscure = !_obscure);
                            },
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'كلمة المرور 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF071A33),
                            foregroundColor: Colors.white,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text('إنشاء حساب جديد'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
