import 'dart:convert';
import 'dart:io';

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
    tempDirectory = await Directory.systemTemp.createTemp('json-export-test-');
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

  test('JSON export includes establishment data', () async {
    await initStorage();

    // Set establishment data.
    await setEstablishmentInfo(
      name: 'Farmacia Test',
      ruc: '10123456789',
      code: 'TST01',
    );

    // Add some report records.
    final reportsBox = await openStorageBox(reportsBoxName);
    await reportsBox.put(0, {
      'producto': 'Paracetamol',
      'precio': 5.50,
      'estado': 'Activo',
    });
    await reportsBox.put(1, {
      'producto': 'Ibuprofeno',
      'precio': 8.75,
      'estado': 'Activo',
    });

    // Simulate the export logic from edit_screen.dart.
    final recordsList = reportsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final establishment = await getEstablishmentInfo();
    final exportData = {'establishment': establishment, 'records': recordsList};
    final jsonString = jsonEncode(exportData);

    // Verify the JSON structure.
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    expect(decoded.containsKey('establishment'), isTrue);
    expect(decoded.containsKey('records'), isTrue);

    // Verify establishment data.
    final est = decoded['establishment'] as Map<String, dynamic>;
    expect(est['name'], 'Farmacia Test');
    expect(est['ruc'], '10123456789');
    expect(est['code'], 'TST01');

    // Verify records.
    final records = decoded['records'] as List<dynamic>;
    expect(records.length, 2);
    expect(records[0]['producto'], 'Paracetamol');
    expect(records[1]['producto'], 'Ibuprofeno');
  });

  test('JSON import restores establishment data from new format', () async {
    await initStorage();

    // Simulate a new-format JSON file.
    final importData = {
      'establishment': {
        'name': 'Farmacia Importada',
        'ruc': '98765432101',
        'code': 'IMP01',
      },
      'records': [
        {'producto': 'Aspirina', 'precio': 3.25, 'estado': 'Activo'},
      ],
    };
    final jsonString = jsonEncode(importData);

    // Simulate the import logic from edit_screen.dart.
    final decoded = jsonDecode(jsonString);
    List<dynamic> records;
    Map<String, dynamic>? establishmentData;
    if (decoded is List) {
      records = decoded;
    } else if (decoded is Map<String, dynamic>) {
      records = List<dynamic>.from(decoded['records'] ?? []);
      establishmentData = decoded['establishment'] is Map
          ? Map<String, dynamic>.from(decoded['establishment'])
          : null;
    } else {
      throw Exception('Formato de archivo no reconocido');
    }

    // Restore establishment data.
    if (establishmentData != null) {
      final name = establishmentData['name']?.toString() ?? '';
      final ruc = establishmentData['ruc']?.toString() ?? '';
      final code = establishmentData['code']?.toString() ?? '';
      if (name.isNotEmpty || ruc.isNotEmpty || code.isNotEmpty) {
        await setEstablishmentInfo(name: name, ruc: ruc, code: code);
      }
    }

    // Restore records.
    final reportsBox = await openStorageBox(reportsBoxName);
    await reportsBox.clear();
    int idx = 0;
    for (var item in records) {
      if (item is Map) {
        await reportsBox.put(idx, Map<String, dynamic>.from(item));
        idx++;
      }
    }

    // Verify establishment was restored.
    final info = await getEstablishmentInfo();
    expect(info['name'], 'Farmacia Importada');
    expect(info['ruc'], '98765432101');
    expect(info['code'], 'IMP01');

    // Verify records were restored.
    expect(reportsBox.length, 1);
    expect(reportsBox.get(0)['producto'], 'Aspirina');
  });

  test('JSON import handles old format (plain array) gracefully', () async {
    await initStorage();

    // Set some initial establishment data.
    await setEstablishmentInfo(
      name: 'Original',
      ruc: '11111111111',
      code: 'ORIG',
    );

    // Open the reports box with encryption (same as initStorage does).
    final reportsBox = await openStorageBox(reportsBoxName);

    // Simulate an old-format JSON file (plain array, no establishment).
    final oldFormat = [
      {'producto': 'Vitamina C', 'precio': 4.00, 'estado': 'Activo'},
    ];
    final jsonString = jsonEncode(oldFormat);

    // Simulate the import logic.
    final decoded = jsonDecode(jsonString);
    List<dynamic> records;
    Map<String, dynamic>? establishmentData;
    if (decoded is List) {
      records = decoded;
    } else if (decoded is Map<String, dynamic>) {
      records = List<dynamic>.from(decoded['records'] ?? []);
      establishmentData = decoded['establishment'] is Map
          ? Map<String, dynamic>.from(decoded['establishment'])
          : null;
    } else {
      throw Exception('Formato de archivo no reconocido');
    }

    // No establishment data in old format — should not overwrite.
    if (establishmentData != null) {
      final name = establishmentData['name']?.toString() ?? '';
      final ruc = establishmentData['ruc']?.toString() ?? '';
      final code = establishmentData['code']?.toString() ?? '';
      if (name.isNotEmpty || ruc.isNotEmpty || code.isNotEmpty) {
        await setEstablishmentInfo(name: name, ruc: ruc, code: code);
      }
    }

    // Restore records to the box.
    await reportsBox.clear();
    int idx = 0;
    for (var item in records) {
      if (item is Map) {
        await reportsBox.put(idx, Map<String, dynamic>.from(item));
        idx++;
      }
    }

    // Verify establishment data is preserved (not overwritten).
    final info = await getEstablishmentInfo();
    expect(info['name'], 'Original');
    expect(info['ruc'], '11111111111');
    expect(info['code'], 'ORIG');

    // Verify records were restored.
    expect(reportsBox.length, 1);
    expect(reportsBox.get(0)['producto'], 'Vitamina C');
  });
}
