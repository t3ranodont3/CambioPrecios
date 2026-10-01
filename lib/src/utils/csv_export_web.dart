import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../models/report_record.dart';

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
  final lines = <String>[];
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

  final blob = web.Blob([csv.toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return 'WEB';
}
