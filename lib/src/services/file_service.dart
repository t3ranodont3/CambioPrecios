import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

/// Helper that picks an Excel file and returns the loaded workbook.
Future<Excel?> pickAndLoadExcel() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls'],
  );
  if (result == null || result.files.isEmpty) return null;
  final path = result.files.single.path;
  if (path == null) return null;
  final bytes = File(path).readAsBytesSync();
  return Excel.decodeBytes(bytes);
}

/// Converts a list of maps to a CSV string.
String generateCsv(List<Map<String, dynamic>> rows,
    {List<String>? headerOverride}) {
  final buffer = StringBuffer();
  final headers = headerOverride ??
      (rows.isNotEmpty ? rows.first.keys.toList() : <String>[]);
  buffer.writeln(headers.join(','));
  for (final row in rows) {
    final values = headers.map((h) => row[h]?.toString() ?? '').toList();
    buffer.writeln(values.map((v) => '"${v.replaceAll('"', '""')}"').join(','));
  }
  return buffer.toString();
}

/// Saves [csv] into a file chosen by the user.
Future<String?> saveCsv(String csv, {String defaultName = 'report.csv'}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Guardar reporte como',
    fileName: defaultName,
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (path == null) return null;
  final file = File(path);
  await file.writeAsString(csv);
  return path;
}
