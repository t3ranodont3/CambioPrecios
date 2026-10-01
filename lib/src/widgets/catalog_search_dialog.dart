import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/storage_service.dart';

class CatalogSearchDialog extends StatefulWidget {
  const CatalogSearchDialog({super.key});

  @override
  State<CatalogSearchDialog> createState() => CatalogSearchDialogState();
}

class CatalogSearchDialogState extends State<CatalogSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<dynamic, dynamic>> _allProducts = [];
  List<Map<dynamic, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadCatalog() {
    try {
      Box box;
      try {
        box = Hive.box(productsBoxName);
      } catch (e) {
        box = Hive.box('products');
      }
      final products = box.values.map((e) {
        if (e is Map) return Map<dynamic, dynamic>.from(e);
        return <dynamic, dynamic>{};
      }).toList();
      setState(() {
        _allProducts = products;
        _filtered = List.from(_allProducts);
      });
    } catch (e) {
      debugPrint('Error listando catalogo: $e');
      setState(() {
        _allProducts = [];
        _filtered = [];
      });
    }
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = List.from(_allProducts));
      return;
    }
    final q = query.toLowerCase().trim();
    final words = q.split(RegExp(r'\s+'));
    setState(() {
      _filtered = _allProducts.where((p) {
        final searchText = [
          p['Cod_Prod'],
          p['Nom_Prod'],
          p['Nom_Titular'],
        ].map((v) => (v ?? '').toString()).join(' ').toLowerCase();
        final partialMatch = words.every((w) => searchText.contains(w));

        final ifa = (p['Nom_IFA'] ?? '').toString().toLowerCase().trim();
        final ifaExactMatch = ifa.isNotEmpty && ifa == q;

        return partialMatch || ifaExactMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalInset = (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
        ? width * 0.025
        : 40.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: 24.0,
      ),
      title: const Text('Buscar en Catálogo'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            TextField(
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
                          _filter('');
                        },
                      )
                    : null,
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _allProducts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No hay productos en el catálogo.\nImporte primero el catálogo.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text('No hay resultados para la búsqueda'),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, idx) {
                            final p = _filtered[idx];
                            return InkWell(
                              onTap: () => Navigator.pop(context, p),
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
                                            p['Nom_Prod']?.toString() ??
                                                'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Cód: ${p['Cod_Prod'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lab: ${p['Nom_Titular'] ?? p['Nom_Fabricante'] ?? ''} | IFA: ${p['Nom_IFA'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Forma: ${p['Nom_Form_Farm'] ?? ''} | Concent: ${p['Concent'] ?? ''} | Pres: ${p['Presentac'] ?? ''} | Fracc: ${p['Fraccion'] ?? ''}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Rubro: ${p['Nom_Rubro'] ?? ''} | Situación: ${p['Situacion'] ?? ''} | RegSan: ${p['Num_RegSan'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
