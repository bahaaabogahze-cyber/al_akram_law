import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final VoidCallback? onActivated;
  const SubscriptionScreen({super.key, this.onActivated});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _code = TextEditingController();
  SubscriptionState? _state;
  bool _loading = true;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await SubscriptionService.getState();
      if (mounted) setState(() => _state = state);
    } catch (e) {
      if (mounted) _show('تعذر التحقق من حالة الاشتراك. تحقق من الاتصال.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contactForSubscription(String plan) async {
    const phone = '963988181075';
    final message = 'مرحباً، أريد تفعيل $plan في تطبيق الأكرم للمحاماة.\n'
        'يرجى تزويدي بتفاصيل الدفع عبر شام كاش. سأرسل إيصال الدفع بعد التحويل.';
    final uri = Uri.https('wa.me', '/$phone', {'text': message});
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _show('تعذر فتح واتساب. يمكنك التواصل على الرقم 00963988181075.');
      }
    } catch (_) {
      if (mounted) {
        _show('تعذر فتح واتساب. يمكنك التواصل على الرقم 00963988181075.');
      }
    }
  }

  Future<void> _redeem() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      _show('أدخل رمز التفعيل.');
      return;
    }
    setState(() => _redeeming = true);
    try {
      await SubscriptionService.redeemActivationCode(code);
      _code.clear();
      await _load();
      if (mounted) {
        _show('تم تفعيل الاشتراك بنجاح.');
        widget.onActivated?.call();
      }
    } on PostgrestException catch (e) {
      _show(e.message);
    } catch (_) {
      _show('تعذر تنفيذ رمز التفعيل.');
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'trial': return 'تجربة مجانية';
      case 'paid': return 'اشتراك مدفوع';
      case 'permanent': return 'اشتراك دائم';
      case 'expired': return 'انتهت الصلاحية';
      case 'suspended': return 'الحساب موقوف';
      default: return 'غير معروف';
    }
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراك والترخيص')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.balance, color: AppColors.secondary, size: 58),
                      const SizedBox(height: 10),
                      const Text('الأكرم للمحاماة', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(_statusLabel(state?.status ?? 'missing'), style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (state?.status == 'trial')
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: AppColors.accent),
                      title: const Text('التجربة المجانية'),
                      subtitle: Text('تنتهي في ${_date(state?.trialEndsAt)}'),
                    ),
                  ),
                if (state?.status == 'expired')
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('انتهت فترة التجربة. يمكنك متابعة تصفح المكتبة القانونية، بينما تحتاج الوظائف الأساسية إلى تفعيل الاشتراك.'),
                    ),
                  ),
                if (state?.status == 'paid')
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.verified, color: AppColors.success),
                      title: const Text('الاشتراك فعال'),
                      subtitle: Text('ينتهي في ${_date(state?.subscriptionEndsAt)}'),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text('الاشتراك المدفوع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'اختر الباقة ثم تواصل معنا عبر واتساب للدفع بواسطة شام كاش. يتم تفعيل الاشتراك بعد التحقق يدويًا من إيصال الدفع.',
                  style: TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('اشتراك شهري', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _contactForSubscription('الاشتراك الشهري'),
                          icon: const Icon(Icons.chat),
                          label: const Text('طلب الاشتراك الشهري عبر واتساب'),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('اشتراك سنوي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _contactForSubscription('الاشتراك السنوي'),
                          icon: const Icon(Icons.chat),
                          label: const Text('طلب الاشتراك السنوي عبر واتساب'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('رقم التواصل: 00963988181075\nوسيلة الدفع: شام كاش\nلن يتم تفعيل الاشتراك إلا بعد التحقق من وصول المبلغ.'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('رمز التفعيل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'أدخل الرمز الذي حصلت عليه',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(onPressed: _redeeming ? null : () => _code.clear(), icon: const Icon(Icons.clear)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _redeeming ? null : _redeem,
                    icon: _redeeming ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.verified),
                    label: const Text('تفعيل الاشتراك'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('يمكنك أيضًا إدخال رمز التفعيل الذي حصلت عليه من الإدارة. يتم التحقق من الرمز عبر خادم Supabase.', style: TextStyle(color: AppColors.grey)),
              ],
            ),
    );
  }
}
