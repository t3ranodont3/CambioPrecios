import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appnew_0/src/providers/auth_provider.dart';
import 'package:appnew_0/src/services/auth_service.dart';
import 'package:appnew_0/src/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  final encryptionKey = List<int>.filled(32, 7);
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('hive-e2e-test-');
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

  test('full auth lifecycle: login → use → logout → cleanup', () async {
    // ── Step 1: Initialize storage ────────────────────────────────────
    await initStorage();

    // ── Step 2: Login via AuthService (same path as AuthProvider) ─────
    final loginSuccess = await AuthService.login('testuser', 'testpass');
    expect(loginSuccess, isTrue);

    // Verify credentials were saved.
    final storedUser = await AuthService.getStoredUsername();
    expect(storedUser, 'testuser');

    // Verify Hive boxes are open for the user.
    expect(Hive.isBoxOpen(configBoxName), isTrue);
    expect(Hive.isBoxOpen(productsBoxName), isTrue);
    expect(Hive.isBoxOpen(reportsBoxName), isTrue);

    // ── Step 3: Write and read data ───────────────────────────────────
    final configBox = Hive.box(configBoxName);
    await configBox.put('establishment_name', 'Farmacia E2E');
    await configBox.put('establishment_ruc', '10123456789');
    await configBox.put('establishment_code', 'E2E01');

    expect(configBox.get('establishment_name'), 'Farmacia E2E');
    expect(configBox.get('establishment_ruc'), '10123456789');
    expect(configBox.get('establishment_code'), 'E2E01');

    // ── Step 4: Verify AuthProvider state after login ─────────────────
    final auth = AuthProvider();
    // Wait for _checkInitialAuth to complete.
    await Future.delayed(const Duration(milliseconds: 100));
    expect(auth.isLoggedIn, isTrue);
    expect(auth.username, 'testuser');

    // ── Step 5: Logout ────────────────────────────────────────────────
    await auth.logout();

    expect(auth.isLoggedIn, isFalse);
    expect(auth.username, '');

    // Verify credentials were cleared.
    final afterLogoutUser = await AuthService.getStoredUsername();
    expect(afterLogoutUser, isNull);

    // ── Step 6: Verify Hive cleanup ───────────────────────────────────
    // logoutCleanup() should have closed all boxes.
    expect(Hive.isBoxOpen(configBoxName), isFalse);
    expect(Hive.isBoxOpen(productsBoxName), isFalse);
    expect(Hive.isBoxOpen(reportsBoxName), isFalse);
  });

  test('re-login after logout opens fresh boxes', () async {
    await initStorage();

    // First login.
    await AuthService.login('user1', 'pass1');
    final config1 = Hive.box(configBoxName);
    await config1.put('establishment_name', 'Farmacia User1');

    // Logout.
    final auth = AuthProvider();
    await Future.delayed(const Duration(milliseconds: 100));
    await auth.logout();

    // Boxes should be closed.
    expect(Hive.isBoxOpen(configBoxName), isFalse);

    // Second login with different user.
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'hive_aes_key': base64UrlEncode(encryptionKey),
    });
    final login2 = await AuthService.login('user2', 'pass2');
    expect(login2, isTrue);

    // Boxes should be open again.
    expect(Hive.isBoxOpen(configBoxName), isTrue);
    expect(Hive.isBoxOpen(productsBoxName), isTrue);
    expect(Hive.isBoxOpen(reportsBoxName), isTrue);
  });
}
