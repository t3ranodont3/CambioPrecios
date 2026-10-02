import 'dart:async';
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

Future<List<int>> _getOrCreateHiveKey(
  Iterable<String> protectedBoxNames,
) async {
  String? encodedKey = await _secureStorage.read(key: 'hive_aes_key');
  if (encodedKey != null) {
    return base64Url.decode(encodedKey);
  }

  for (final boxName in protectedBoxNames) {
    if (await Hive.boxExists(boxName)) {
      throw HiveError(
        'Hive encryption key is missing while box "$boxName" exists. '
        'The box was left untouched.',
      );
    }
  }

  final key = Hive.generateSecureKey();
  await _secureStorage.write(key: 'hive_aes_key', value: base64UrlEncode(key));
  return key;
}

Future<void> initStorage() async {
  await Hive.initFlutter();

  final prefs = await SharedPreferences.getInstance();
  _currentUsername = prefs.getString('username');

  if (_currentUsername == null || _currentUsername!.isEmpty) {
    _currentUsername = 'default';
  }

  _encryptionKey = await _getOrCreateHiveKey([
    productsBoxName,
    reportsBoxName,
    configBoxName,
  ]);

  await openStorageBox(productsBoxName);
  await openStorageBox(reportsBoxName);
  await openStorageBox(configBoxName);
}

Future<Box> openStorageBox(String boxName) async {
  if (Hive.isBoxOpen(boxName)) {
    return Hive.box(boxName);
  }

  final key = _encryptionKey ??= await _getOrCreateHiveKey([boxName]);
  final result = Completer<Box>();
  // Hive 2.2 may emit a second zone error from its in-flight open completer.
  runZonedGuarded(
    () {
      Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(key),
        // A cipher mismatch must fail, not truncate the existing box as
        // crash recovery.
        crashRecovery: false,
      ).then(
        (box) {
          if (!result.isCompleted) result.complete(box);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!result.isCompleted) result.completeError(error, stackTrace);
        },
      );
    },
    (error, stackTrace) {
      if (!result.isCompleted) {
        result.completeError(error, stackTrace);
      } else {
        debugPrint('Additional Hive open error for "$boxName": $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    },
  );
  return result.future;
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
  return openStorageBox(configBoxName);
}

Future<void> switchUser(String username) async {
  try {
    final oldUsername = _currentUsername;
    _currentUsername = username;

    if (oldUsername != null && oldUsername != username) {
      await _closeBoxesForUser(oldUsername);
    }

    _encryptionKey ??= await _getOrCreateHiveKey([
      productsBoxName,
      reportsBoxName,
      configBoxName,
    ]);

    await openStorageBox(productsBoxName);
    await openStorageBox(reportsBoxName);
    await openStorageBox(configBoxName);
  } catch (e) {
    debugPrint('Error switching user: $e');
  }
}

Future<void> logoutCleanup() async {
  try {
    final username = _currentUsername;
    if (username != null && username.isNotEmpty && username != 'default') {
      await _closeBoxesForUser(username);
    }
    _currentUsername = null;
  } catch (e) {
    debugPrint('Error during logout cleanup: $e');
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
