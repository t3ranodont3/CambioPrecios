import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage_service.dart';

class HiveHelper {
  HiveHelper._();

  static Future<Box<T>> openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Error opening box $name, recreating: $e');
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  static Future<Box<Map>> productsBox() =>
      openBox<Map>(productsBoxName);

  static Future<Box<Map>> reportsBox() =>
      openBox<Map>(reportsBoxName);

  static Future<Box<Map>> configBox() =>
      openBox<Map>(configBoxName);

  static Future<Box<Map>> boxFor(String boxName) =>
      openBox<Map>(boxName);

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
