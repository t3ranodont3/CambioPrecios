import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../services/hive_helper.dart';
import '../utils/platform_file.dart';

class ImportCatalogScreen extends StatefulWidget {
  const ImportCatalogScreen({super.key});

  @override
  State<ImportCatalogScreen> createState() => _ImportCatalogScreenState();
}

class _ImportCatalogScreenState extends State<ImportCatalogScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadLastFile();
  }

  void _loadLastFile() {
    final box = HiveHelper.box(configBoxName);
    final path = box.get('last_catalog_path');
    final name = box.get('last_catalog_name');

    if (kIsWeb) {
      if (name != null) {
        setState(() {
          _status = 'Último archivo web: $name';
        });
      }
    } else {
      if (path != null) {
        if (fileExistsSync(path)) {
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
    String? filePath;
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
      if (result.files.single.bytes != null) {
        bytes = result.files.single.bytes!;
      } else if (result.files.single.path != null) {
        filePath = result.files.single.path!;
        bytes = readBytesSync(filePath);
      } else {
        setState(() => _status = 'Error: No se pudo leer el archivo');
        return;
      }

      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      final box = await HiveHelper.productsBox();
      await box.clear();
      bool foundHeader = false;

      final Map<int, Map<String, dynamic>> batchMap = {};
      int currentIndex = 0;
      const int batchSize = 500;

      for (var row in sheet.rows) {
        if (!foundHeader) {
          if (row.isNotEmpty) {
            final firstCell =
                row[0]?.value?.toString().trim().toLowerCase() ?? '';
            if (firstCell.replaceAll('_', '').contains('codprod')) {
              foundHeader = true;
              debugPrint('Encontrada cabecera de Catalogo en fila');
            }
          }
          continue;
        }
        if (row.isEmpty) continue;

        final codProd = row.isNotEmpty
            ? row[0]?.value?.toString().trim() ?? ''
            : '';
        if (codProd.isEmpty) continue;

        final nomProd = 1 < row.length ? row[1]?.value?.toString() ?? '' : '';
        final concent = 2 < row.length ? row[2]?.value?.toString() ?? '' : '';
        final nomFormFarm = 3 < row.length
            ? row[3]?.value?.toString() ?? ''
            : '';
        final presentac = 4 < row.length ? row[4]?.value?.toString() ?? '' : '';
        final fraccion = 5 < row.length ? row[5]?.value?.toString() ?? '' : '';
        final numRegSan = 6 < row.length ? row[6]?.value?.toString() ?? '' : '';
        final nomTitular = 7 < row.length
            ? row[7]?.value?.toString() ?? ''
            : '';
        final nomFabricante = 8 < row.length
            ? row[8]?.value?.toString() ?? ''
            : '';
        final nomIfa = 9 < row.length ? row[9]?.value?.toString() ?? '' : '';
        final nomRubro = 10 < row.length
            ? row[10]?.value?.toString() ?? ''
            : '';
        final situacion = 11 < row.length
            ? row[11]?.value?.toString() ?? ''
            : '';

        batchMap[currentIndex] = {
          'Cod_Prod': codProd,
          'Nom_Prod': nomProd,
          'Concent': concent,
          'Nom_Form_Farm': nomFormFarm,
          'Presentac': presentac,
          'Fraccion': fraccion,
          'Num_RegSan': numRegSan,
          'Nom_Titular': nomTitular,
          'Nom_Fabricante': nomFabricante,
          'Nom_IFA': nomIfa,
          'Nom_Rubro': nomRubro,
          'Situacion': situacion,
        };

        currentIndex++;

        if (batchMap.length >= batchSize) {
          await box.putAll(batchMap);
          batchMap.clear();
        }
      }

      // Insert any remaining items
      if (batchMap.isNotEmpty) {
        await box.putAll(batchMap);
      }

      // Guardar ruta del archivo
      final configBox = HiveHelper.box(configBoxName);
      if (filePath != null) {
        await configBox.put('last_catalog_path', filePath);
      }
      await configBox.put('last_catalog_name', result.files.single.name);

      debugPrint(
        'Header encontrado: $foundHeader, Items guardados: ${box.length}',
      );

      setState(() {
        final displayName = kIsWeb ? result.files.single.name : filePath;
        _status =
            'Catálogo almacenado (${box.length} items)${displayName != null ? '\nArchivo: $displayName' : ''}';
      });
    } catch (e) {
      setState(() => _status = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar catálogo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.library_books,
                size: 64,
                color: Colors.deepPurple,
              ),
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
                  label: const Text('Seleccionar catálogo (Excel)'),
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
