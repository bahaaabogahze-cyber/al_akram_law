import 'package:flutter_test/flutter_test.dart';

import 'package:al_akram_law/main.dart';

void main() {
  testWidgets('Login screen renders for a signed-out user', (tester) async {
    await tester.pumpWidget(const AlAkramLawApp(isLoggedIn: false));

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
  });
}
