import 'dart:convert';

import 'package:archive/archive.dart';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/report_record.dart';
import '../services/storage_service.dart';

class ExportCsvScreen extends StatefulWidget {
  const ExportCsvScreen({super.key});

  @override
  State<ExportCsvScreen> createState() => _ExportCsvScreenState();
}

class _ExportCsvScreenState extends State<ExportCsvScreen> {
  final TextEditingController _estCodeCtrl = TextEditingController();
  List<ReportRecord> _records = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _estCodeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      Box configBox;
      if (!Hive.isBoxOpen(configBoxName)) {
        configBox = await Hive.openBox(configBoxName);
      } else {
        configBox = Hive.box(configBoxName);
      }

      final savedEst = configBox.get('establishment_code', defaultValue: '');
      _estCodeCtrl.text = savedEst == 'NO ENCONTRADO' ? '' : savedEst;

      Box box;
      if (!Hive.isBoxOpen(reportsBoxName)) {
        box = await Hive.openBox(reportsBoxName);
      } else {
        box = Hive.box(reportsBoxName);
      }

      final recs = <ReportRecord>[];
      for (var item in box.values) {
        if (item is Map) {
          final Map<String, dynamic> stringMap = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          recs.add(ReportRecord.fromMap(stringMap));
        }
      }

      if (mounted) {
        setState(() {
          _records = recs;
        });
      }
    } catch (e) {
      debugPrint('Error loading export data: $e');
    }
  }

  String _generateCsvContent(List<ReportRecord> validRecords) {
    final buffer = StringBuffer();
    final estCodeRaw = _estCodeCtrl.text.trim();
    final paddedEstCode = estCodeRaw.padLeft(7, '0');

    buffer.write('CodEstab,CodProd,Precio 1,Precio 2\r\n');

    for (final r in validRecords) {
      if (r.precioEmpaq <= 0.0 && r.precioUnit <= 0.0) continue;
      final p1 = r.precioEmpaq > 0 ? r.precioEmpaq.toStringAsFixed(2) : '';
      final p2 = r.precioUnit > 0 ? r.precioUnit.toStringAsFixed(2) : '';
      buffer.write('$paddedEstCode,${r.codProd},$p1,$p2\r\n');
    }

    return buffer.toString();
  }

  /// Carga todos los códigos de producto del catálogo actual
  Future<Set<String>> _loadCatalogCodes() async {
    try {
      Box productsBox;
      if (!Hive.isBoxOpen(productsBoxName)) {
        productsBox = await Hive.openBox(productsBoxName);
      } else {
        productsBox = Hive.box(productsBoxName);
      }
      return productsBox.values
          .map((v) => (v is Map ? (v['Cod_Prod'] ?? '').toString().trim() : ''))
          .where((c) => c.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('Error leyendo catálogo: $e');
      return {};
    }
  }

  /// Muestra el diálogo de advertencia y retorna true si el usuario confirma exportar
  Future<bool> _showCatalogWarningDialog({
    required List<ReportRecord> excluded,
    required int validCount,
    required bool catalogEmpty,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(child: Text('Verificación del Catálogo')),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alerta de actualización
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recuerde importar el Catálogo de Productos actualizado al día de la presentación del informe a DIGEMID antes de generar el CSV.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (catalogEmpty)
                  const Text(
                    '⚠️ No se encontró ningún catálogo importado. No se puede verificar la validez de los productos.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  )
                else if (excluded.isEmpty)
                  Text(
                    '✅ Todos los $validCount productos del reporte figuran en el catálogo actual.',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                  )
                else ...[
                  Text(
                    '${excluded.length} producto${excluded.length == 1 ? '' : 's'} NO se incluirá${excluded.length == 1 ? '' : 'n'} en el CSV porque no figuran en el catálogo actual:',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: excluded.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = excluded[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.nombreProducto,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Cód: ${r.codProd}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se exportarán $validCount producto${validCount == 1 ? '' : 's'} válidos.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          if (!catalogEmpty && validCount > 0)
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Generar CSV de todas formas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _exportCsv() async {
    setState(() => _isLoading = true);

    try {
      // 1. Guardar código de establecimiento
      final configBox = Hive.box(configBoxName);
      await configBox.put('establishment_code', _estCodeCtrl.text.trim());

      // 2. Cargar códigos del catálogo actual
      final catalogCodes = await _loadCatalogCodes();
      final catalogEmpty = catalogCodes.isEmpty;

      // 3. Separar válidos e inválidos
      final valid = <ReportRecord>[];
      final excluded = <ReportRecord>[];
      for (final r in _records) {
        if (catalogEmpty || catalogCodes.contains(r.codProd.trim())) {
          valid.add(r);
        } else {
          excluded.add(r);
        }
      }

      setState(() => _isLoading = false);

      // 4. Mostrar diálogo de advertencia si hay excluidos o catálogo vacío
      final shouldExport = (excluded.isEmpty && !catalogEmpty)
          ? await _showCatalogWarningDialog(
              excluded: excluded,
              validCount: valid.length,
              catalogEmpty: catalogEmpty,
            )
          : await _showCatalogWarningDialog(
              excluded: excluded,
              validCount: valid.length,
              catalogEmpty: catalogEmpty,
            );

      if (!shouldExport || !mounted) return;

      setState(() => _isLoading = true);

      // 5. Generar CSV solo con productos válidos
      final csvString = _generateCsvContent(valid);
      final csvBytes = utf8.encode(csvString);
      final rucGuardado = configBox.get('establishment_ruc', defaultValue: '') as String;
      final codeEff = _estCodeCtrl.text.trim();
      final now = DateTime.now();
      final mes = now.month.toString().padLeft(2, '0');
      final year2 = (now.year % 100).toString().padLeft(2, '0');
      String fileName;
      if (rucGuardado.isNotEmpty && codeEff.isNotEmpty) {
        fileName = '${rucGuardado}_${codeEff}_${mes}_${year2}_CARGA ARCHIVO';
      } else if (rucGuardado.isNotEmpty) {
        fileName = '${rucGuardado}_${mes}_${year2}_CARGA ARCHIVO';
      } else if (codeEff.isNotEmpty) {
        fileName = 'RUC_${codeEff}_${mes}_${year2}_CARGA ARCHIVO';
      } else {
        fileName = 'RUC_CODEEFF_${mes}_${year2}_CARGA ARCHIVO';
      }
      if (fileName.length > 70) fileName = fileName.substring(0, 70);

      // 6. Comprimir CSV en ZIP
      final archive = Archive();
      archive.addFile(ArchiveFile(
        '$fileName.csv',
        csvBytes.length,
        csvBytes,
      ));
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

      // 7. Guardar CSV
      final uCsvBytes = Uint8List.fromList(csvBytes);
      String? csvOutput;
      if (kIsWeb) {
        csvOutput = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: uCsvBytes,
          fileExtension: 'csv',
          mimeType: MimeType.csv,
        );
      } else {
        csvOutput = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: uCsvBytes,
          fileExtension: 'csv',
          mimeType: MimeType.csv,
        );
      }

      if (!mounted) return;

      // 8. Guardar ZIP
      String? zipOutput;
      if (kIsWeb) {
        zipOutput = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: zipBytes,
          fileExtension: 'zip',
          mimeType: MimeType.zip,
        );
      } else {
        zipOutput = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: zipBytes,
          fileExtension: 'zip',
          mimeType: MimeType.zip,
        );
      }

      if (!mounted) return;
      final saved = <String>[];
      if (csvOutput != null) saved.add('CSV');
      if (zipOutput != null) saved.add('ZIP');
      if (saved.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivos guardados: ${saved.join(' y ')} ($fileName)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportación cancelada')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisión Final CSV')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.store, color: Colors.deepPurple, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Código de Establecimiento:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _estCodeCtrl,
                          maxLength: 7,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setState(() {});
                            Hive.box(configBoxName).put('establishment_code', val.trim());
                          },
                          decoration: const InputDecoration(
                            hintText: 'Ej. 1234567',
                            border: OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || _records.isEmpty ? null : _exportCsv,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: const Text('Generar CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ${_records.length} producto${_records.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _records.isEmpty
                ? const Center(child: Text('No hay productos para exportar.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith<Color>(
                          (_) {
                            return Colors.grey.shade200;
                          },
                        ),
                        columns: const [
                          DataColumn(label: Text('CodEstab')),
                          DataColumn(label: Text('CodProd')),
                          DataColumn(label: Text('Precio 1')),
                          DataColumn(label: Text('Precio 2')),
                        ],
                        rows: List<DataRow>.generate(_records.length, (index) {
                          final r = _records[index];
                          final isEven = index % 2 == 0;
                          final estCodeRaw = _estCodeCtrl.text.trim();
                          final paddedEstCode = estCodeRaw.padLeft(7, '0');
                          final p1 = r.precioEmpaq > 0
                              ? r.precioEmpaq.toStringAsFixed(2)
                              : '';
                          final p2 = r.precioUnit > 0
                              ? r.precioUnit.toStringAsFixed(2)
                              : '';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color>((_) {
                              return isEven
                                  ? Colors.white
                                  : Colors.grey.shade50;
                            }),
                            cells: [
                              DataCell(Text(paddedEstCode)),
                              DataCell(Text(r.codProd)),
                              DataCell(Text(p1)),
                              DataCell(Text(p2)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
