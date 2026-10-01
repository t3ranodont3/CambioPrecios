import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _estName = '';
  String _estRuc = '';
  String _estCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadEstablishmentInfo(),
    );
  }

  Widget _establishmentReminder() {
    if (_estName.isNotEmpty && _estRuc.isNotEmpty && _estCode.isNotEmpty) {
      return SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: 280,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade300, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Datos del establecimiento incompletos',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor complete los datos de su establecimiento antes de generar reportes.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Rellenar ahora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _promptEstablishmentInfo(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadEstablishmentInfo() async {
    final info = await getEstablishmentInfo();
    setState(() {
      _estName = info['name'] ?? '';
      _estRuc = info['ruc'] ?? '';
      _estCode = info['code'] ?? '';
    });
    if (_estName.isEmpty || _estRuc.isEmpty || _estCode.isEmpty) {
      // Prompt user to fill establishment data
      await _promptEstablishmentInfo();
    }
  }

  Future<void> _promptEstablishmentInfo() async {
    final nameCtrl = TextEditingController(text: _estName);
    final rucCtrl = TextEditingController(text: _estRuc);
    final codeCtrl = TextEditingController(text: _estCode);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Datos del Establecimiento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: rucCtrl,
                decoration: const InputDecoration(
                  labelText: 'RUC',
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Código'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final ruc = rucCtrl.text.trim();
                final code = codeCtrl.text.trim();

                if (ruc.length != 11) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El RUC debe tener exactamente 11 dígitos numéricos.',
                      ),
                    ),
                  );
                  return;
                }

                final navigator = Navigator.of(ctx);
                if (name.isNotEmpty && code.isNotEmpty) {
                  await setEstablishmentInfo(name: name, ruc: ruc, code: code);
                  setState(() {
                    _estName = name;
                    _estRuc = ruc;
                    _estCode = code;
                  });
                }
                navigator.pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _establishmentCard() {
    if (_estName.isEmpty && _estRuc.isEmpty && _estCode.isEmpty) {
      return SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: 280,
        child: Card(
          margin: const EdgeInsets.only(top: 6.0, bottom: 18.0),
          child: ListTile(
            leading: const Icon(Icons.store, color: Colors.blue),
            title: const Text('Establecimiento:'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _estName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text('RUC: $_estRuc'),
                const SizedBox(height: 4),
                Text('Código: $_estCode'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              tooltip: 'Editar datos del establecimiento',
              onPressed: () => _promptEstablishmentInfo(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Se mantiene el AppBar existente
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('OPM - Observatorio Perú'),
            Text(
              (_estName.isNotEmpty && _estRuc.isNotEmpty && _estCode.isNotEmpty)
                  ? 'Establecimiento: $_estName | RUC: $_estRuc | Código: $_estCode'
                  : 'Establecimiento: -',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              nav.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _establishmentReminder(),
              _establishmentCard(),
              _MenuButton(
                icon: Icons.upload_file,
                label: 'Cargar catálogo de productos',
                onTap: () => Navigator.of(context).pushNamed('/import_catalog'),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.upload,
                label: 'Cargar último reporte',
                onTap: () => Navigator.of(context).pushNamed('/import_report'),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.edit,
                label: 'Editar productos',
                onTap: () async {
                  await Navigator.of(context).pushNamed('/edit');
                  if (mounted) _loadEstablishmentInfo();
                },
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.save_alt,
                label: 'Generar reporte CSV',
                onTap: () async {
                  await Navigator.of(context).pushNamed('/export');
                  if (mounted) _loadEstablishmentInfo();
                },
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.cloud_sync,
                label: 'Sincronizar con DIGEMID',
                onTap: () => Navigator.of(context).pushNamed('/sync'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}
