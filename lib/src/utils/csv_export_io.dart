import 'dart:io' as io;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/report_record.dart';

import '../services/storage_service.dart';

Future<String?> exportCsvAsCsv({
  required List<ReportRecord> records,
  required String ruc,
  required String code,
  required String estName,
}) async {
  final now = DateTime.now();
  final mes = now.month.toString().padLeft(2, '0');
  final year2 = (now.year % 100).toString().padLeft(2, '0');
  String filename;
  if (code.isNotEmpty) {
    filename = '${ruc}_${code}_${mes}_${year2}_CARGA ARCHIVO.csv';
  } else {
    filename = '${ruc}_${mes}_${year2}_CARGA ARCHIVO.csv';
  }
  if (filename.length > 70) filename = filename.substring(0, 70);

  String toField(String s) {
    final s2 = s.replaceAll('"', '""');
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"$s2"';
    }
    return s2;
  }

  final header = [
    'CodProd',
    'Nombre Producto',
    'Fecha Act.',
    'Laboratorio',
    'IFA',
    'Precio Empaque',
    'Precio Unit.',
  ];
  final List<String> lines = [];
  lines.add(header.map((h) => toField(h)).join(','));
  for (final rec in records) {
    lines.add(
      [
        rec.codProd,
        rec.nombreProducto,
        rec.fechaActualizacion,
        rec.laboratorio,
        rec.ifa,
        rec.precioEmpaq.toStringAsFixed(2),
        rec.precioUnit.toStringAsFixed(2),
      ].map((e) => toField(e)).join(','),
    );
  }
  final csv = lines.join('\n');

  String? dirPath = await getCsvExportDirectory();
  if (dirPath == null) {
    final dir = await getApplicationDocumentsDirectory();
    dirPath = dir.path;
    await setCsvExportDirectory(dirPath);
  }
  final path = io.Directory(dirPath).path;
  final filePath = '$path/$filename';
  final file = io.File(filePath);
  await file.writeAsString(csv, encoding: utf8);
  return filePath;
}
