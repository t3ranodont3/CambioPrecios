import 'package:hive_flutter/hive_flutter.dart';
import 'storage_service.dart';

class HiveHelper {
  HiveHelper._();

  static Future<Box> openBox(String name) => openStorageBox(name);

  static Box box(String name) => Hive.box(name);

  static Future<Box> productsBox() => openBox(productsBoxName);

  static Future<Box> reportsBox() => openBox(reportsBoxName);

  static Future<Box> configBox() => openBox(configBoxName);

  static Future<Box> boxFor(String boxName) => openBox(boxName);

  static Future<void> putAll(
    Box box,
    Map<int, Map<String, dynamic>> batch, {
    int batchSize = 500,
  }) async {
    final entries = batch.entries.toList();
    for (var i = 0; i < entries.length; i += batchSize) {
      final chunk = <int, Map<String, dynamic>>{};
      for (var j = i; j < i + batchSize && j < entries.length; j++) {
        chunk[entries[j].key] = entries[j].value;
      }
      await box.putAll(chunk);
    }
  }
}
