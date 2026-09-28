import 'package:flutter/material.dart';
import 'package:al_akram_law/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      // login logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.balance, color: Color(0xFFD4AF37), size: 90),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: _dec('البريد الإلكتروني', Icons.email_outlined),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'أدخل بريداً إلكترونياً صحيحاً'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: _dec('كلمة المرور', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'كلمة المرور 6 أحرف على الأقل'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
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
