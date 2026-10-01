import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appnew_0/src/services/hive_helper.dart';
import 'package:appnew_0/src/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  final encryptionKey = List<int>.filled(32, 7);
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('hive-policy-test-');
    Hive.init(tempDirectory.path);
    FlutterSecureStorage.setMockInitialValues({
      'hive_aes_key': base64UrlEncode(encryptionKey),
    });
    SharedPreferences.setMockInitialValues({});
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

  Future<void> expectHiveError(Future<dynamic> operation) async {
    try {
      await operation;
    } on HiveError {
      return;
    }
    fail('Expected a HiveError.');
  }

  test('HiveHelper encrypts boxes and reuses an already-open box', () async {
    final first = await HiveHelper.openBox('products_test');
    await first.put('item', {'id': '123'});

    final reused = await HiveHelper.openBox('products_test');
    expect(identical(reused, first), isTrue);

    final storedBytes = await File(
      '${tempDirectory.path}${Platform.pathSeparator}products_test.hive',
    ).readAsBytes();
    expect(
      latin1.decode(storedBytes, allowInvalid: true),
      isNot(contains('123')),
    );

    await first.close();
    final reopened = await HiveHelper.openBox('products_test');
    expect(reopened.get('item'), {'id': '123'});
  });

  test('failed encrypted open preserves existing plaintext box data', () async {
    const boxName = 'products_legacy';
    final existing = await Hive.openBox<Map>(boxName);
    await existing.put('keep', {'value': 'preserved'});
    await existing.close();
    final boxFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}$boxName.hive',
    );
    final bytesBefore = await boxFile.readAsBytes();

    await expectHiveError(HiveHelper.openBox(boxName));

    expect(await boxFile.readAsBytes(), bytesBefore);
  });

  test(
    'missing key does not create a replacement for existing box data',
    () async {
      const username = 'existing-user';
      const boxName = 'products_existing-user';
      final existing = await Hive.openBox<Map>(boxName);
      await existing.put('keep', {'value': 'preserved'});
      await existing.close();

      SharedPreferences.setMockInitialValues({'username': username});
      FlutterSecureStorage.setMockInitialValues({});

      await expectHiveError(initStorage());
      expect(
        await const FlutterSecureStorage().read(key: 'hive_aes_key'),
        isNull,
      );

      final reopenedWithoutCipher = await Hive.openBox<Map>(boxName);
      expect(reopenedWithoutCipher.get('keep'), {'value': 'preserved'});
    },
  );
}
