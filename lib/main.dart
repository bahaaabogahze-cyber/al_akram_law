import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/subscription/subscription_gate.dart';
import 'core/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = SupabaseService.isConfigured
      ? SupabaseService.user != null
      : (prefs.getBool('isLoggedIn') ?? false);
  runApp(AlAkramLawApp(isLoggedIn: isLoggedIn));
}

class AlAkramLawApp extends StatelessWidget {
  final bool isLoggedIn;
  const AlAkramLawApp({super.key, required this.isLoggedIn});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'منصة الأكرم للمحامين السوريين', debugShowCheckedModeBanner: false,
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    home: isLoggedIn
        ? const SubscriptionGate(child: HomeScreen())
        : const LoginScreen(),
  );
}
