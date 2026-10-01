import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../utils/report_column_mapper.dart';

class ImportReportScreen extends StatefulWidget {
  const ImportReportScreen({super.key});

  @override
  State<ImportReportScreen> createState() => _ImportReportScreenState();
}

class _ImportReportScreenState extends State<ImportReportScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadLastFile();
  }

  void _loadLastFile() {
    final box = Hive.box(configBoxName);
    final path = box.get('last_report_path');
    final name = box.get('last_report_name');

    if (kIsWeb) {
      if (name != null) {
        setState(() {
          _status = 'Último archivo web: $name';
        });
      }
    } else {
      if (path != null) {
        if (File(path).existsSync()) {
          setState(() {
            _status = 'Último archivo: $path';
          });
        } else {
          setState(() {
            _status = 'Error: El archivo previo ya no existe en $path';
          });
        }
      }
    }
  }

  Future<void> _doImport() async {
    setState(() {
      _status = 'Seleccionando archivo...';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _status = 'Importación cancelada');
        return;
      }

      List<int> bytes;
      String? filePath;
      if (result.files.single.bytes != null) {
        bytes = result.files.single.bytes!;
      } else if (result.files.single.path != null) {
        filePath = result.files.single.path!;
        bytes = File(filePath).readAsBytesSync();
      } else {
        setState(() => _status = 'Error: No se pudo leer el archivo');
        return;
      }

      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      late Box box;
      try {
        final boxName = reportsBoxName;
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
        box = Hive.box(boxName);
      } catch (e) {
        debugPrint('Error opening reports box: $e');
        try {
          box = Hive.box('reports');
        } catch (e2) {
          setState(
            () => _status = 'Error: No se pudo acceder al almacenamiento',
          );
          return;
        }
      }
      await box.clear();
      bool foundHeader = false;
      late ReportColumnMapper columnMapper;

      final Map<int, Map<String, dynamic>> batchMap = {};
      int currentIndex = 0;
      const int batchSize = 500;

      for (var row in sheet.rows) {
        if (!foundHeader) {
          if (row.isNotEmpty) {
            // Extract establishment code searching across all cells in the row
            for (int i = 0; i < row.length; i++) {
              final cellStr =
                  row[i]?.value?.toString().trim().toLowerCase() ?? '';
              if (cellStr.contains('establecimiento')) {
                // Look for the next non-empty cell to the right
                for (int j = i + 1; j < row.length; j++) {
                  final nextCellStr = row[j]?.value?.toString().trim() ?? '';
                  if (nextCellStr.isNotEmpty) {
                    final configBox = Hive.box(configBoxName);
                    await configBox.put('establishment_code', nextCellStr);
                    break;
                  }
                }
                break;
              }
            }

            final possibleHeader = ReportColumnMapper.fromHeaders(
              row.map((cell) => cell?.value?.toString()).toList(),
            );
            if (possibleHeader.codProdIndex != null) {
              columnMapper = possibleHeader;
              foundHeader = true;
            }
          }
          continue;
        }
        if (row.isEmpty) continue;

        String valueAt(int? index) {
          if (index == null || index < 0 || index >= row.length) return '';
          return row[index]?.value?.toString() ?? '';
        }

        final codProd = valueAt(columnMapper.codProdIndex).trim();

        // Filter if CodProd is empty
        if (codProd.isEmpty) continue;

        final nombreProducto = valueAt(columnMapper.nombreProductoIndex);
        final fechaActualizacion = valueAt(
          columnMapper.fechaActualizacionIndex,
        );
        final laboratorio = valueAt(columnMapper.laboratorioIndex);
        final ifa = valueAt(columnMapper.ifaIndex);
        final precioEmpaq =
            double.tryParse(valueAt(columnMapper.precioEmpaqIndex)) ?? 0.0;
        final precioUnit =
            double.tryParse(valueAt(columnMapper.precioUnitIndex)) ?? 0.0;

        // Avoid adding completely empty trailing rows
        if (codProd.isEmpty && nombreProducto.isEmpty) continue;

        batchMap[currentIndex] = {
          'codProd': codProd,
          'nombreProducto': nombreProducto,
          'fechaActualizacion': fechaActualizacion,
          'laboratorio': laboratorio,
          'ifa': ifa,
          'precioEmpaq': precioEmpaq,
          'precioUnit': precioUnit,
        };

        currentIndex++;

        if (batchMap.length >= batchSize) {
          await box.putAll(batchMap);
          batchMap.clear();
        }
      }

      if (batchMap.isNotEmpty) {
        await box.putAll(batchMap);
      }

      // Guardar ruta del archivo
      final configBox = Hive.box(configBoxName);
      if (filePath != null) {
        await configBox.put('last_report_path', filePath);
      }
      await configBox.put('last_report_name', result.files.single.name);

      setState(() {
        final displayName = kIsWeb ? result.files.single.name : filePath;
        _status =
            'Reporte almacenado (${box.length} elementos)${displayName != null ? '\nArchivo: $displayName' : ''}';
      });
    } catch (e) {
      setState(() => _status = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar último reporte')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.file_upload, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 24),
              if (_status != null)
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: _doImport,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Seleccionar reporte (Excel)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
