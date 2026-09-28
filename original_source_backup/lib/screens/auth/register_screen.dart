import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _barNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedSpecialty = 'القانون المدني';

  final List<String> _specialties = [
    'القانون المدني',
    'القانون الجزائي',
    'قانون الأحوال الشخصية',
    'القانون التجاري',
    'القانون العمالي',
    'القانون العقاري',
    'القانون الإداري',
    'قانون الإيجارات',
  ];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _nameController.text);
      await prefs.setString('userEmail', _emailController.text);
      await prefs.setString('userSpecialty', _selectedSpecialty);
      await prefs.setString('barNumber', _barNumberController.text);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 24),
              _buildField(_nameController, 'الاسم الكامل', Icons.person,
                  (v) => v!.isEmpty ? 'أدخل الاسم' : null),
              const SizedBox(height: 16),
              _buildField(_emailController, 'البريد الإلكتروني', Icons.email,
                  (v) => !v!.contains('@') ? 'بريد غير صحيح' : null,
                  isLTR: true),
              const SizedBox(height: 16),
              _buildField(_phoneController, 'رقم الهاتف', Icons.phone,
                  (v) => v!.isEmpty ? 'أدخل رقم الهاتف' : null,
                  isLTR: true,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(_barNumberController, 'رقم النقابة', Icons.badge,
                  (v) => v!.isEmpty ? 'أدخل رقم النقابة' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                decoration: InputDecoration(
                  labelText: 'التخصص القانوني',
                  prefixIcon: const Icon(Icons.gavel,
                      color: Color(0xFF1A237E)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _specialties
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSpecialty = v!),
              ),
              const SizedBox(height: 16),
              _buildField(
                _passwordController,
                'كلمة المرور',
                Icons.lock,
                (v) => v!.length < 6 ? 'كلمة المرور قصيرة' : null,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                _confirmPasswordController,
                'تأكيد كلمة المرور',
                Icons.lock_outline,
                (v) => v != _passwordController.text
                    ? 'كلمة المرور غير متطابقة'
                    : null,
                obscure: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إنشاء الحساب',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    bool isLTR = false,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        suffixIcon: suffix,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
      ),
      validator: validator,
    );
  }
}