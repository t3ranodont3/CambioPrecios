import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:appnew_0/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Performance test: Scrolling Edit Screen', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    if (find.text('Iniciar sesión').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).last, 'testpass');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    if (find.text('Cancelar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Cancelar').first);
      await tester.pumpAndSettle();
    }

    await binding.traceAction(() async {
      await tester.tap(find.text('Editar productos'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }, reportKey: 'edit_screen_transition_summary');
  });
}
