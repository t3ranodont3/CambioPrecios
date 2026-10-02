import 'package:appnew_0/src/services/storage_service.dart';
import 'package:appnew_0/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  test(
    'initStorage propagates required storage initialization failures',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async {
            throw PlatformException(code: 'storage_unavailable');
          });

      await expectLater(initStorage(), throwsA(isA<PlatformException>()));
    },
  );

  testWidgets('startup displays a safe failure screen when storage fails', (
    tester,
  ) async {
    final startupApp = await createStartupApp(
      initializeStorage: () async => throw StateError('storage unavailable'),
    );

    await tester.pumpWidget(startupApp);

    expect(find.text('No se pudo iniciar la aplicación'), findsOneWidget);
    expect(
      find.textContaining('No se pudo inicializar el almacenamiento local.'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión'), findsNothing);
  });
}
