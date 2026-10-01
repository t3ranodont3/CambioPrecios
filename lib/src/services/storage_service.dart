import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String? _currentUsername;
List<int>? _encryptionKey;
const _secureStorage = FlutterSecureStorage();

String get currentUsername {
  if (_currentUsername == null || _currentUsername!.isEmpty) {
    return 'default';
  }
  return _currentUsername!;
}

Future<List<int>> _getOrCreateHiveKey() async {
  String? encodedKey = await _secureStorage.read(key: 'hive_aes_key');
  if (encodedKey == null) {
    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: 'hive_aes_key',
      value: base64UrlEncode(key),
    );
    return key;
  }
  return base64Url.decode(encodedKey);
}

Future<void> initStorage() async {
  await Hive.initFlutter();

  final prefs = await SharedPreferences.getInstance();
  _currentUsername = prefs.getString('username');

  if (_currentUsername == null || _currentUsername!.isEmpty) {
    _currentUsername = 'default';
  }

  _encryptionKey = await _getOrCreateHiveKey();

  await _openOrCreateBox(productsBoxName);
  await _openOrCreateBox(reportsBoxName);
  await _openOrCreateBox(configBoxName);
}

Future<Box> _openOrCreateBox(String boxName) async {
  return Hive.openBox(
    boxName,
    encryptionCipher: HiveAesCipher(_encryptionKey!),
  );
}

String get productsBoxName => 'products_$currentUsername';
String get reportsBoxName => 'reports_$currentUsername';
String get configBoxName => 'config_$currentUsername';

Future<void> setCsvExportDirectory(String path) async {
  try {
    final box = await _openConfigBox();
    await box.put('csv_export_dir', path);
  } catch (e) {
    debugPrint('Error setting CSV export directory: $e');
  }
}

Future<String?> getCsvExportDirectory() async {
  try {
    final box = await _openConfigBox();
    return box.get('csv_export_dir')?.toString();
  } catch (e) {
    debugPrint('Error getting CSV export directory: $e');
    return null;
  }
}

Future<void> setEstablishmentInfo({
  required String name,
  required String ruc,
  required String code,
}) async {
  try {
    final box = await _openConfigBox();
    await box.put('establishment_name', name);
    await box.put('establishment_ruc', ruc);
    await box.put('establishment_code', code);
  } catch (e) {
    debugPrint('Error saving establishment info: $e');
  }
}

Future<Map<String, String>> getEstablishmentInfo() async {
  final box = await _openConfigBox();
  final name = box.get('establishment_name')?.toString() ?? '';
  final ruc = box.get('establishment_ruc')?.toString() ?? '';
  final code = box.get('establishment_code')?.toString() ?? '';
  return {'name': name, 'ruc': ruc, 'code': code};
}

const _defaultWsUrl =
    'https://ms-opm.minsa.gob.pe/msopmcovid/ServicePrecios.asmx';

Future<void> setWsConfig({
  required String url,
  required String username,
  required String password,
}) async {
  final box = await _openConfigBox();
  await box.put('ws_url', url);
  await box.put('ws_username', username);
  await box.put('ws_password', password);
}

Future<Map<String, String>> getWsConfig() async {
  final box = await _openConfigBox();
  return {
    'url': box.get('ws_url')?.toString() ?? _defaultWsUrl,
    'username': box.get('ws_username')?.toString() ?? '',
    'password': box.get('ws_password')?.toString() ?? '',
  };
}

Future<Box> _openConfigBox() async {
  return _openOrCreateBox(configBoxName);
}

Future<void> switchUser(String username) async {
  try {
    final oldUsername = _currentUsername;
    _currentUsername = username;

    if (oldUsername != null && oldUsername != username) {
      await _closeBoxesForUser(oldUsername);
    }

    _encryptionKey ??= await _getOrCreateHiveKey();

    await _openOrCreateBox(productsBoxName);
    await _openOrCreateBox(reportsBoxName);
    await _openOrCreateBox(configBoxName);
  } catch (e) {
    debugPrint('Error switching user: $e');
  }
}

Future<void> _closeBoxesForUser(String username) async {
  try {
    final names = [
      'products_$username',
      'reports_$username',
      'config_$username',
    ];
    for (final name in names) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
    }
  } catch (e) {
    debugPrint('Error closing old boxes: $e');
  }
}
