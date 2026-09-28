import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

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
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F5F5), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A237E), foregroundColor: Colors.white, centerTitle: true, elevation: 0), inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),),
    home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
  );
}
