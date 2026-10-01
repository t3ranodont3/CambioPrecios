import 'csv_export_io.dart' if (dart.library.js_interop) 'csv_export_web.dart' as pl;
import '../models/report_record.dart';

Future<String?> exportCsv({
  required List<ReportRecord> records,
  required String ruc,
  required String code,
  required String estName,
}) => pl.exportCsvAsCsv(
  records: records,
  ruc: ruc,
  code: code,
  estName: estName,
);
