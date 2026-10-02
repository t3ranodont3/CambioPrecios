import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../models/report_record.dart';
import '../services/storage_service.dart';
import '../services/hive_helper.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/catalog_search_dialog.dart';
import '../widgets/precios_dialog.dart';
import '../utils/price_utils.dart';
import '../utils/platform_file.dart';
import 'export_csv_screen.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late Box? _reportsBox;
  late Box? _configBox;
  String? _error;
  String? _lastPath;
  bool _isLoading = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<ReportRecord> _cachedRecords = [];
  List<ReportRecord> _filteredRecords = [];
  int _currentPage = 1;
  static const int _itemsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _initData();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    EasyDebounce.cancel('search_debouncer');
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent * 0.9) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_records.length < _filteredRecords.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _initData() {
    try {
      _reportsBox = HiveHelper.box(reportsBoxName);
      _configBox = HiveHelper.box(configBoxName);
      _lastPath = _configBox?.get('last_report_path');
      _loadRecords();
    } catch (e) {
      _error = 'No se pudo acceder al almacenamiento: $e';
      _reportsBox = null;
      _configBox = null;
    }
  }

  void _loadRecords() {
    if (_reportsBox == null) {
      _cachedRecords = [];
      _filteredRecords = [];
      return;
    }
    _cachedRecords = _reportsBox!.values
        .map((e) => ReportRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    _applyFilter(_searchCtrl.text);
  }

  List<ReportRecord> get _allRecords => _cachedRecords;

  List<ReportRecord> get _records {
    final maxItems = _currentPage * _itemsPerPage;
    if (_filteredRecords.length > maxItems) {
      return _filteredRecords.sublist(0, maxItems);
    }
    return _filteredRecords;
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      _filteredRecords = _allRecords;
    } else {
      final q = query.toLowerCase();
      _filteredRecords = _allRecords.where((r) {
        return r.codProd.toLowerCase().contains(q) ||
            r.nombreProducto.toLowerCase().contains(q);
      }).toList();
    }
    _currentPage = 1;
  }

  void _filterRecords(String query) {
    EasyDebounce.debounce(
      'search_debouncer',
      const Duration(milliseconds: 300),
      () {
        setState(() {
          _applyFilter(query);
        });
      },
    );
  }

  Future<void> _reloadFromFile() async {
    if (_lastPath == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar recarga'),
        content: const Text(
          '¿Está seguro que desea volver a cargar el archivo Excel original?\n\n'
          'Se perderán todos los cambios (precios editados, productos nuevos, eliminaciones) '
          'que no haya guardado en una copia de seguridad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cargar datos originales'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);
    try {
      if (!fileExistsSync(_lastPath!)) {
        setState(() {
          _error = 'El archivo previo ya no existe en: $_lastPath';
          _isLoading = false;
        });
        return;
      }

      final bytes = readBytesSync(_lastPath!);
      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (_reportsBox != null) {
        await _reportsBox!.clear();
        bool foundHeader = false;

        final Map<int, Map<String, dynamic>> batchMap = {};
        int currentIndex = 0;
        const int batchSize = 500;

        for (var row in sheet.rows) {
          if (!foundHeader) {
            if (row.isNotEmpty) {
              final firstCell =
                  row[0]?.value?.toString().trim().toLowerCase() ?? '';
              if (firstCell.contains('codprod')) {
                foundHeader = true;
              }
            }
            continue;
          }
          if (row.isEmpty) continue;

          final codProd = row.isNotEmpty
              ? row[0]?.value?.toString().trim() ?? ''
              : '';

          if (codProd.isEmpty) continue;

          final nombreProducto = row.length > 1
              ? row[1]?.value?.toString() ?? ''
              : '';
          final fechaActualizacion = row.length > 2
              ? row[2]?.value?.toString() ?? ''
              : '';
          final laboratorio = row.length > 3
              ? row[3]?.value?.toString() ?? ''
              : '';
          final ifa = row.length > 4 ? row[4]?.value?.toString() ?? '' : '';
          final precioEmpaq = row.length > 5
              ? double.tryParse(row[5]?.value?.toString() ?? '') ?? 0.0
              : 0.0;
          final precioUnit = row.length > 6
              ? double.tryParse(row[6]?.value?.toString() ?? '') ?? 0.0
              : 0.0;

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
            await _reportsBox!.putAll(batchMap);
            batchMap.clear();
          }
        }

        if (batchMap.isNotEmpty) {
          await _reportsBox!.putAll(batchMap);
        }
      }
      setState(() {
        _error = null;
        _isLoading = false;
        _loadRecords();
      });
    } catch (e) {
      setState(() {
        _error = 'Error al recargar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToJson() async {
    if (_reportsBox == null || _reportsBox!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para exportar.')),
      );
      return;
    }
    try {
      final recordsList = _reportsBox!.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Include establishment data in the export.
      final establishment = await getEstablishmentInfo();
      final exportData = {
        'establishment': establishment,
        'records': recordsList,
      };
      final jsonString = jsonEncode(exportData);

      final isMobile = isMobilePlatform;

      final now = DateTime.now();
      final dateStr = DateFormat('yyMMdd HHmm').format(now);
      final fileName = 'ActualizacionPreciosDIGEMID $dateStr';

      if (kIsWeb) {
        final jsonBytes = utf8.encode(jsonString);
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(jsonBytes),
          fileExtension: 'json',
          mimeType: MimeType.json,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión descargada exitosamente')),
        );
      } else if (isMobile) {
        final jsonBytes = utf8.encode(jsonString);
        String? outputFile = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: Uint8List.fromList(jsonBytes),
          fileExtension: 'json',
          mimeType: MimeType.json,
        );

        if (outputFile != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesión guardada exitosamente: $fileName.json'),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copia de seguridad cancelada')),
          );
        }
      } else {
        final outPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar sesión de trabajo',
          fileName: '$fileName.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (outPath != null) {
          await writeFileAsString(outPath, jsonString);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sesión guardada en $outPath')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
    }
  }

  Future<void> _importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() => _isLoading = true);

      String data;
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          data = utf8.decode(result.files.single.bytes!);
        } else {
          throw Exception('No se recibieron datos del archivo web.');
        }
      } else {
        if (result.files.single.path != null) {
          data = await readFileAsString(result.files.single.path!);
        } else if (result.files.single.bytes != null) {
          data = utf8.decode(result.files.single.bytes!);
        } else {
          throw Exception('No se pudo leer el contenido del archivo');
        }
      }

      final dynamic decoded = jsonDecode(data);

      // Support both old format (plain array) and new format (object with
      // 'records' and optional 'establishment').
      List<dynamic> records;
      Map<String, dynamic>? establishmentData;
      if (decoded is List) {
        // Old format: JSON array of records.
        records = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // New format: object with 'records' key.
        records = List<dynamic>.from(decoded['records'] ?? []);
        establishmentData = decoded['establishment'] is Map
            ? Map<String, dynamic>.from(decoded['establishment'])
            : null;
      } else {
        throw Exception('Formato de archivo no reconocido');
      }

      // Restore establishment data if present.
      if (establishmentData != null) {
        final name = establishmentData['name']?.toString() ?? '';
        final ruc = establishmentData['ruc']?.toString() ?? '';
        final code = establishmentData['code']?.toString() ?? '';
        if (name.isNotEmpty || ruc.isNotEmpty || code.isNotEmpty) {
          await setEstablishmentInfo(name: name, ruc: ruc, code: code);
        }
      }

      if (_reportsBox != null) {
        await _reportsBox!.clear();

        final Map<int, Map<String, dynamic>> batchMap = {};
        int currentIndex = 0;
        const int batchSize = 500;

        for (var item in records) {
          if (item is Map) {
            batchMap[currentIndex] = Map<String, dynamic>.from(item);
            currentIndex++;

            if (batchMap.length >= batchSize) {
              await _reportsBox!.putAll(batchMap);
              batchMap.clear();
            }
          }
        }

        if (batchMap.isNotEmpty) {
          await _reportsBox!.putAll(batchMap);
        }
        _loadRecords();
      }
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión restaurada')));
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando json: $e')));
    }
  }

  Future<void> _addRecord() async {
    if (_reportsBox == null) return;

    final selectedProduct = await showDialog<Map<dynamic, dynamic>>(
      context: context,
      builder: (c) => const CatalogSearchDialog(),
    );

    if (selectedProduct != null) {
      final codProd = selectedProduct['Cod_Prod']?.toString() ?? '';

      final existingIndex = _cachedRecords.indexWhere(
        (r) => r.codProd == codProd,
      );

      if (existingIndex != -1) {
        final existingRec = _cachedRecords[existingIndex];
        if (!mounted) return;
        final accion = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Producto ya existente'),
            content: Text(
              'El producto "${existingRec.nombreProducto}" ya está registrado.\n\n'
              'Precio actual: S/ ${existingRec.precioEmpaq.toStringAsFixed(2)} (Empaque) / '
              'S/ ${existingRec.precioUnit.toStringAsFixed(2)} (Unitario)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, 'otro'),
                child: const Text('Añadir otro producto'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, 'cambiar'),
                child: const Text('Cambiar precio'),
              ),
            ],
          ),
        );

        if (accion == 'cambiar') {
          if (!mounted) return;
          final precios = await showDialog<Map<String, double>>(
            context: context,
            builder: (c) => PreciosDialog(
              producto: selectedProduct,
              precioInicial: existingRec.precioEmpaq,
              precioUnitInicial: existingRec.precioUnit,
              validateUnitPrice: validateUnitPrice,
            ),
          );

          if (precios != null) {
            final updated = ReportRecord(
              codProd: existingRec.codProd,
              nombreProducto: existingRec.nombreProducto,
              fechaActualizacion: existingRec.fechaActualizacion,
              laboratorio: existingRec.laboratorio,
              ifa: existingRec.ifa,
              precioEmpaq: precios['precioEmpaq'] ?? 0.0,
              precioUnit: precios['precioUnit'] ?? 0.0,
            );
            _reportsBox!.putAt(existingIndex, updated.toMap());
            _loadRecords();
            setState(() {});
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Precio actualizado')));
          }
        } else if (accion == 'otro') {
          await _addRecord();
          return;
        }
      } else {
        if (!mounted) return;
        final precios = await showDialog<Map<String, double>>(
          context: context,
          builder: (c) => PreciosDialog(
            producto: selectedProduct,
            validateUnitPrice: validateUnitPrice,
          ),
        );

        if (precios != null) {
          setState(() {
            final nombreProd =
                '${selectedProduct['Nom_Prod'] ?? ''} '
                        '${selectedProduct['Concent'] ?? ''} '
                        '${selectedProduct['Nom_Form_Farm'] ?? ''} '
                        '${selectedProduct['Presentac'] ?? ''} '
                        '${selectedProduct['Fraccion'] ?? ''} unid'
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();

            final rec = ReportRecord(
              codProd: selectedProduct['Cod_Prod']?.toString() ?? '',
              nombreProducto: nombreProd,
              fechaActualizacion: '',
              laboratorio:
                  selectedProduct['Nom_Titular']?.toString() ??
                  selectedProduct['Nom_Fabricante']?.toString() ??
                  '',
              ifa: selectedProduct['Nom_IFA']?.toString() ?? '',
              precioEmpaq: precios['precioEmpaq'] ?? 0.0,
              precioUnit: precios['precioUnit'] ?? 0.0,
            );
            _reportsBox!.add(rec.toMap());
            _loadRecords();
          });
        }
      }
    }
  }

  void _saveRecord(int index, ReportRecord rec) {
    if (_reportsBox == null) return;
    _reportsBox!.putAt(index, rec.toMap());
    _loadRecords();
    setState(() {});
  }

  void _deleteRecord(int index) {
    if (_reportsBox == null) return;
    _reportsBox!.deleteAt(index);
    _loadRecords();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar productos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final records = _records;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 40,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Generar reporte CSV final',
                  icon: const Icon(Icons.document_scanner),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportCsvScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Hacer copia de seguridad',
                  icon: const Icon(Icons.save),
                  onPressed: _exportToJson,
                ),
                IconButton(
                  tooltip: 'Restaurar copia de seguridad',
                  icon: const Icon(Icons.file_upload),
                  onPressed: _importFromJson,
                ),
                if (!kIsWeb && _lastPath != null)
                  IconButton(
                    tooltip: 'Volver a cargar archivo Excel original',
                    icon: const Icon(Icons.sync),
                    onPressed: _reloadFromFile,
                  ),
              ],
            ),
            const Text('Editar productos', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_lastPath != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                'Archivo: $_lastPath',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Buscar por Código o Nombre',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _filterRecords('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterRecords,
                  ),
                ),
                Container(
                  color: Colors.blueGrey[100],
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Productos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'Mostrando ${records.length} de ${_filteredRecords.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_searchCtrl.text.isNotEmpty &&
                                  _allRecords.isNotEmpty)
                                const Text('No hay resultados para la búsqueda')
                              else if (_lastPath != null)
                                ElevatedButton.icon(
                                  onPressed: _reloadFromFile,
                                  icon: const Icon(Icons.file_open),
                                  label: const Text(
                                    'Cargar desde último archivo',
                                  ),
                                )
                              else
                                const Text('No hay registros cargados'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          itemCount:
                              records.length +
                              (records.length < _filteredRecords.length
                                  ? 1
                                  : 0),
                          itemBuilder: (context, idx) {
                            if (idx == records.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final rec = records[idx];
                            return InkWell(
                              onTap: () async {
                                final realIndex = _cachedRecords.indexWhere(
                                  (r) => r.codProd == rec.codProd,
                                );
                                final updated = await showDialog<ReportRecord>(
                                  context: context,
                                  builder: (c) => EditDialog(
                                    record: rec,
                                    index: realIndex,
                                    onDelete: _deleteRecord,
                                    validateUnitPrice: validateUnitPrice,
                                    lookupFraccion: lookupFraccion,
                                  ),
                                );
                                if (updated != null) {
                                  _saveRecord(realIndex, updated);
                                }
                              },
                              child: Container(
                                color: idx % 2 == 0
                                    ? Colors.white
                                    : Colors.blueGrey[50],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rec.nombreProducto,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Cód: ${rec.codProd}',
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lab: ${rec.laboratorio} | IFA: ${rec.ifa}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Fecha: ${rec.fechaActualizacion.isEmpty ? "No definida" : rec.fechaActualizacion}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Precio Empaque: S/ ${rec.precioEmpaq.toStringAsFixed(2)} | Precio Unitario: S/ ${rec.precioUnit.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }
}
