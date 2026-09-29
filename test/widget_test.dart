import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:al_akram_law/main.dart';

void main() {
  testWidgets('Login screen renders for a signed-out user', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AlAkramLawApp(isLoggedIn: false));
    await tester.pump();

    // "تسجيل الدخول" appears twice: the heading and the submit button.
    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('البريد الإلكتروني'), findsWidgets);
    expect(find.text('إنشاء حساب جديد'), findsWidgets);
  });
}
