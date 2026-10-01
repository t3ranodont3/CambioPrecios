import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/precio_ws.dart';
import '../models/report_record.dart';
import '../services/digemid_service.dart';
import '../services/storage_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  // Controllers
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // State
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isError = false;
  List<PrecioWS> _wsProducts = [];
  String _idSucursal = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final wsConfig = await getWsConfig();
    final estInfo = await getEstablishmentInfo();

    setState(() {
      _urlCtrl.text = wsConfig['url'] ?? '';
      _userCtrl.text = wsConfig['username'] ?? '10405093699';
      _passCtrl.text = wsConfig['password'] ?? 'JA10405093699';
      _idSucursal = estInfo['code'] ?? '';
    });
  }

  Future<void> _saveConfig() async {
    await setWsConfig(
      url: _urlCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
  }

  DigemidService _buildService() {
    return DigemidService(
      baseUrl: _urlCtrl.text.trim(),
      wsUsername: _userCtrl.text.trim(),
      wsPassword: _passCtrl.text.trim(),
    );
  }

  void _setStatus(String msg, {bool error = false}) {
    if (mounted) {
      setState(() {
        _statusMessage = msg;
        _isError = error;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 1. ObtenerListaProductos
  // ---------------------------------------------------------------------------
  Future<void> _obtenerListaProductos() async {
    if (_idSucursal.isEmpty) {
      _setStatus('⚠️ Configure el código de establecimiento primero.', error: true);
      return;
    }

    setState(() => _isLoading = true);
    _setStatus('Consultando productos...');
    await _saveConfig();

    try {
      final service = _buildService();
      final precios = await service.obtenerListaProductos(_idSucursal);
      setState(() {
        _wsProducts = precios;
      });
      _setStatus('✅ Se obtuvieron ${precios.length} productos del servidor.');
    } on DigemidServiceException catch (e) {
      _setStatus('❌ Error: ${e.message}', error: true);
    } catch (e) {
      _setStatus('❌ Error inesperado: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. ActualizarProducto (envía todos los productos locales)
  // ---------------------------------------------------------------------------
  Future<void> _actualizarProductos() async {
    if (_idSucursal.isEmpty) {
      _setStatus('⚠️ Configure el código de establecimiento primero.', error: true);
      return;
    }

    setState(() => _isLoading = true);
    _setStatus('Enviando precios al servidor...');
    await _saveConfig();

    try {
      // Obtener registros locales
      final records = await _loadLocalRecords();
      if (records.isEmpty) {
        _setStatus('⚠️ No hay registros de precios para enviar.', error: true);
        return;
      }

      final service = _buildService();
      int ok = 0;
      int fail = 0;
      final errors = <String>[];

      for (final r in records) {
        try {
          final precio = PrecioWS(
            idProducto: int.tryParse(r.codProd) ?? 0,
            precioMinUnit: r.precioUnit,
            precioMaxEmpaq: r.precioEmpaq,
            precioPromedio: 0.0, // No se utiliza
            fecha: DateTime.tryParse(r.fechaActualizacion) ?? DateTime.now(),
          );

          final result = await service.actualizarProducto(
            idSucursal: _idSucursal,
            precio: precio,
          );

          if (result.toLowerCase().contains('error')) {
            fail++;
            errors.add('Prod ${r.codProd}: $result');
          } else {
            ok++;
          }
        } catch (e) {
          fail++;
          errors.add('Prod ${r.codProd}: $e');
        }

        // Actualizar progreso
        _setStatus('Enviando ${ok + fail}/${records.length}...');
      }

      final errSummary = errors.isNotEmpty
          ? '\nErrores:\n${errors.take(5).join('\n')}${errors.length > 5 ? '\n...y ${errors.length - 5} más' : ''}'
          : '';
      _setStatus('✅ Enviados: $ok | Fallidos: $fail$errSummary',
          error: fail > 0);
    } on DigemidServiceException catch (e) {
      _setStatus('❌ Error: ${e.message}', error: true);
    } catch (e) {
      _setStatus('❌ Error inesperado: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. DeshabilitarProducto
  // ---------------------------------------------------------------------------
  Future<void> _deshabilitarProducto(String idProducto) async {
    if (_idSucursal.isEmpty) {
      _setStatus('⚠️ Configure el código de establecimiento primero.', error: true);
      return;
    }

    setState(() => _isLoading = true);
    _setStatus('Deshabilitando producto $idProducto...');
    await _saveConfig();

    try {
      final service = _buildService();
      final result = await service.deshabilitarProducto(
        idSucursal: _idSucursal,
        idProducto: idProducto,
      );
      _setStatus('✅ Resultado: $result');
    } on DigemidServiceException catch (e) {
      _setStatus('❌ Error: ${e.message}', error: true);
    } catch (e) {
      _setStatus('❌ Error inesperado: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. ReplicarPrecios
  // ---------------------------------------------------------------------------
  Future<void> _replicarPrecios() async {
    if (_idSucursal.isEmpty) {
      _setStatus('⚠️ Configure el código de establecimiento primero.', error: true);
      return;
    }

    setState(() => _isLoading = true);
    _setStatus('Replicando precios...');
    await _saveConfig();

    try {
      final service = _buildService();
      final result = await service.replicarPrecios(_idSucursal);
      _setStatus('✅ Resultado: $result');
    } on DigemidServiceException catch (e) {
      _setStatus('❌ Error: ${e.message}', error: true);
    } catch (e) {
      _setStatus('❌ Error inesperado: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<List<ReportRecord>> _loadLocalRecords() async {
    Box box;
    if (!Hive.isBoxOpen(reportsBoxName)) {
      box = await Hive.openBox(reportsBoxName);
    } else {
      box = Hive.box(reportsBoxName);
    }

    final recs = <ReportRecord>[];
    for (var item in box.values) {
      if (item is Map) {
        final stringMap = item.map((k, v) => MapEntry(k.toString(), v));
        recs.add(ReportRecord.fromMap(stringMap));
      }
    }
    return recs;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar con DIGEMID'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Configuración del WS ----
            _buildConfigSection(),
            const SizedBox(height: 16),

            // ---- Estado ----
            if (_statusMessage.isNotEmpty) _buildStatusCard(),
            const SizedBox(height: 16),

            // ---- Operaciones ----
            _buildOperationsSection(),

            // ---- Resultados ObtenerListaProductos ----
            if (_wsProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildProductsTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.deepPurple.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Configuración del Web Service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL del Web Service',
                hintText: 'https://opm-digemid.minsa.gob.pe/ServicePrecios.asmx',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Usuario WS',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña WS',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.store, color: Colors.blue.shade400, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Código de Sucursal (establecimiento): $_idSucursal',
                  style: TextStyle(
                    fontSize: 13,
                    color: _idSucursal.isEmpty ? Colors.red : Colors.grey.shade700,
                    fontWeight: _idSucursal.isEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _isError ? Colors.red.shade50 : Colors.green.shade50,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _isError ? Icons.error_outline : Icons.check_circle_outline,
              color: _isError ? Colors.red.shade700 : Colors.green.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: _isError ? Colors.red.shade800 : Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: Colors.deepPurple.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Operaciones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Obtener Lista
            _OperationTile(
              icon: Icons.download,
              color: Colors.blue,
              title: 'Obtener Lista de Productos',
              subtitle: 'Consultar los precios actuales de la sucursal en DIGEMID',
              onTap: _isLoading ? null : _obtenerListaProductos,
            ),
            const Divider(),

            // Actualizar Productos  
            _OperationTile(
              icon: Icons.upload,
              color: Colors.green,
              title: 'Actualizar Productos',
              subtitle: 'Enviar todos los precios locales editados al servidor',
              onTap: _isLoading ? null : _actualizarProductos,
            ),
            const Divider(),

            // Replicar Precios
            _OperationTile(
              icon: Icons.copy_all,
              color: Colors.orange,
              title: 'Replicar Precios',
              subtitle: 'Realizar una réplica de precios de la sucursal',
              onTap: _isLoading ? null : _replicarPrecios,
            ),
            const Divider(),

            // Deshabilitar Producto
            _DeshabilitarTile(
              enabled: !_isLoading,
              onDeshabilitar: _deshabilitarProducto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Text(
                  'Productos del Servidor (${_wsProducts.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                columns: const [
                  DataColumn(label: Text('IdProducto')),
                  DataColumn(label: Text('PrecioMinUnit')),
                  DataColumn(label: Text('PrecioMaxEmpaq')),
                  DataColumn(label: Text('PrecioPromedio')),
                  DataColumn(label: Text('Fecha')),
                ],
                rows: _wsProducts.map((p) {
                  return DataRow(cells: [
                    DataCell(Text('${p.idProducto}')),
                    DataCell(Text(p.precioMinUnit.toStringAsFixed(2))),
                    DataCell(Text(p.precioMaxEmpaq.toStringAsFixed(2))),
                    DataCell(Text(p.precioPromedio.toStringAsFixed(2))),
                    DataCell(Text(p.fecha.toLocal().toString().split('.').first)),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _OperationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OperationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: const Text('Ejecutar'),
      ),
    );
  }
}

class _DeshabilitarTile extends StatefulWidget {
  final bool enabled;
  final Future<void> Function(String idProducto) onDeshabilitar;

  const _DeshabilitarTile({
    required this.enabled,
    required this.onDeshabilitar,
  });

  @override
  State<_DeshabilitarTile> createState() => _DeshabilitarTileState();
}

class _DeshabilitarTileState extends State<_DeshabilitarTile> {
  final _prodIdCtrl = TextEditingController();

  @override
  void dispose() {
    _prodIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.withValues(alpha: 0.15),
            child: const Icon(Icons.block, color: Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deshabilitar Producto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ingrese el código del producto a deshabilitar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _prodIdCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Código prod.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: widget.enabled && _prodIdCtrl.text.trim().isNotEmpty
                          ? () => widget.onDeshabilitar(_prodIdCtrl.text.trim())
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Deshabilitar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
