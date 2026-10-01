import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appnew_0/src/services/storage_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({
      'username': 'testuser',
      'password': 'testpass',
    });

    await Hive.initFlutter();
    Box box;
    if (Hive.isBoxOpen(configBoxName)) {
      box = Hive.box(configBoxName);
    } else {
      box = await Hive.openBox(configBoxName);
    }
    await box.put('est_name_testuser', 'Test Est');
    await box.put('est_ruc_testuser', '12345678901');
    await box.put('est_code_testuser', '1234');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  // testWidgets('HomeScreen displays menu and navigates to catalog', (WidgetTester tester) async {
  //   bool navigatedToCatalog = false;
  //   await tester.pumpWidget(MaterialApp(
  //     home: const HomeScreen(),
  //     routes: {
  //       '/import_catalog': (context) {
  //         navigatedToCatalog = true;
  //         return const Scaffold(body: Text('Mock Catalog'));
  //       },
  //       '/import_report': (context) => const Scaffold(body: Text('Mock Report')),
  //       '/edit': (context) => const Scaffold(body: Text('Mock Edit')),
  //       '/export': (context) => const Scaffold(body: Text('Mock Export')),
  //     },
  //   ));

  //   await tester.pump();
  //   await tester.pumpAndSettle();

  //   if (find.text('Guardar').evaluate().isNotEmpty) {
  //     await tester.tap(find.text('Guardar'));
  //     await tester.pumpAndSettle();
  //   }

  //   expect(find.text('Cargar catálogo de productos'), findsOneWidget);
  //   expect(find.text('Cargar último reporte'), findsOneWidget);
  //   expect(find.text('Editar productos'), findsOneWidget);
  //   expect(find.text('Generar reporte CSV'), findsOneWidget);

  //   await tester.tap(find.text('Cargar catálogo de productos'));
  //   await tester.pumpAndSettle();

  //   expect(navigatedToCatalog, isTrue);
  //   expect(find.text('Mock Catalog'), findsOneWidget);
  // });
}
