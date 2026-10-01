import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:appnew_0/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    testWidgets('Full flow: Login -> Home -> Edit -> Export', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Login (if we are not already logged in)
      if (find.text('Iniciar sesión').evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextFormField).first, 'testuser');
        await tester.enterText(find.byType(TextFormField).last, 'testpass');
        await tester.tap(find.text('Ingresar'));
        await tester.pumpAndSettle();
        
        // 1.b Check for 2FA PIN dialog
        if (find.text('Configurar PIN (2FA)').evaluate().isNotEmpty) {
          final pinFields = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          );
          await tester.enterText(pinFields.at(0), '1234');
          await tester.enterText(pinFields.at(1), '1234');
          await tester.tap(find.text('Guardar'));
          await tester.pumpAndSettle(const Duration(seconds: 3));
        } else if (find.text('Verificación 2FA').evaluate().isNotEmpty) {
          final pinFields = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          );
          await tester.enterText(pinFields.first, '1234');
          await tester.tap(find.text('Verificar'));
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // 2. Home screen - might show establishment dialog
      // Small delay just to let navigation complete and initial dialogs show up
      await Future.delayed(const Duration(seconds: 4));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (find.text('Datos del Establecimiento').evaluate().isNotEmpty) {
        final textFields = find.byType(TextField);
        if (textFields.evaluate().length >= 3) {
          await tester.enterText(textFields.at(0), 'Farmacia Test'); // Nombre
          await tester.enterText(textFields.at(1), '10123456789'); // RUC
          await tester.enterText(textFields.at(2), '1234'); // Código
          await tester.tap(find.text('Guardar'));
          await tester.pumpAndSettle(const Duration(seconds: 3));
        } else {
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // If reminder dialog is shown instead of automatic popup
      if (find.text('Rellenar ahora').evaluate().isNotEmpty) {
        await tester.tap(find.text('Rellenar ahora'));
        await tester.pumpAndSettle();
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Farmacia Test');
        await tester.enterText(textFields.at(1), '10123456789');
        await tester.enterText(textFields.at(2), '1234');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait until 'Editar productos' is present if not already
      int attempts = 0;
      while (find.text('Editar productos').evaluate().isEmpty && attempts < 5) {
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        attempts++;
      }
      
      expect(find.text('Editar productos'), findsOneWidget);

      // 3. Edit Screen
      await tester.tap(find.text('Editar productos'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Tap the export icon at the top
      final iconExport = find.byIcon(Icons.document_scanner);
      if (iconExport.evaluate().isNotEmpty) {
        await tester.tap(iconExport);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        // Go back to home and tap generate csv
        await tester.pageBack();
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        await tester.tap(find.text('Generar reporte CSV'));
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // 4. Export Screen
      expect(find.text('Revisión Final CSV'), findsWidgets);
      
      // Look for the est code textfield and enter a code
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, '1234567');
        await tester.pumpAndSettle();
      }

      // Verify Generar CSV button exists
      expect(find.text('Generar CSV'), findsOneWidget);
    });
  });
}
