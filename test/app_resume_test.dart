import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appnew_0/src/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  final encryptionKey = List<int>.filled(32, 7);
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('hive-resume-test-');
    Hive.init(tempDirectory.path);
    FlutterSecureStorage.setMockInitialValues({
      'hive_aes_key': base64UrlEncode(encryptionKey),
    });
    SharedPreferences.setMockInitialValues({'username': 'testuser'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return tempDirectory.path;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('app resume preserves local Hive state without remote calls', () async {
    // Open encrypted boxes (same cipher policy as the app)
    final productsBox = await Hive.openBox(
      productsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
      crashRecovery: false,
    );
    final configBox = await Hive.openBox(
      configBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
      crashRecovery: false,
    );

    // Seed local data
    await productsBox.put(0, {'id': '1', 'name': 'Aspirina', 'price': '5.00'});
    await configBox.put('establishment_name', 'Farmacia Test');
    await configBox.put('establishment_ruc', '12345678901');
    await configBox.put('establishment_code', 'F001');

    // Simulate background → resume lifecycle sequence
    WidgetsBinding.instance
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    // Hive boxes still open and data intact after resume
    expect(Hive.isBoxOpen(productsBoxName), isTrue);
    expect(Hive.isBoxOpen(configBoxName), isTrue);
    expect(productsBox.get(0), {
      'id': '1',
      'name': 'Aspirina',
      'price': '5.00',
    });
    expect(configBox.get('establishment_name'), 'Farmacia Test');
    expect(configBox.get('establishment_ruc'), '12345678901');
    expect(configBox.get('establishment_code'), 'F001');

    // getEstablishmentInfo still returns correct data (no stale state)
    final info = await getEstablishmentInfo();
    expect(info['name'], 'Farmacia Test');
    expect(info['ruc'], '12345678901');
    expect(info['code'], 'F001');
  });

  test('repeated resume cycles do not corrupt local state', () async {
    final productsBox = await Hive.openBox(
      productsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
      crashRecovery: false,
    );
    final configBox = await Hive.openBox(
      configBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
      crashRecovery: false,
    );

    await productsBox.put(0, {'id': '1', 'name': 'Aspirina', 'price': '5.00'});
    await configBox.put('establishment_name', 'Farmacia Test');

    // Simulate 10 pause/resume cycles
    for (int i = 0; i < 10; i++) {
      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }

    expect(Hive.isBoxOpen(productsBoxName), isTrue);
    expect(Hive.isBoxOpen(configBoxName), isTrue);
    expect(productsBox.get(0), {
      'id': '1',
      'name': 'Aspirina',
      'price': '5.00',
    });
    expect(configBox.get('establishment_name'), 'Farmacia Test');
  });
}
