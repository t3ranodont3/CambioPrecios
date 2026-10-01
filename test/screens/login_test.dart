import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appnew_0/src/screens/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen displays form and validates empty fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Try submitting without credentials
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    // Expect validation messages
    expect(find.text('Requerido'), findsNWidgets(2));
  });

  // Note: we can't easily test a successful login and navigation here because it depends on routing
  // and other services initialized in main, so those are covered in integration tests.
}
