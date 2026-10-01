// ignore_for_file: avoid_print
import 'dart:io';
import 'package:excel/excel.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run bin/inspect_excel.dart <path_to_excel_file>');
    return;
  }

  final path = args[0];
  final file = File(path);
  if (!file.existsSync()) {
    print('File does not exist: $path');
    return;
  }

  print('Reading: $path');
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheetName = excel.tables.keys.first;
  final sheet = excel.tables[sheetName]!;

  print('--- FIRST 20 ROWS ---');
  int count = 0;
  for (var row in sheet.rows) {
    if (count > 20) break;
    print('Row $count length: ${row.length}');
    for (int i = 0; i < row.length; i++) {
      final val = row[i]?.value;
      if (val != null && val.toString().trim().isNotEmpty) {
        print('  Col $i: "$val"');
      }
    }
    count++;
  }
}

