import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreciosDialog extends StatefulWidget {
  final Map<dynamic, dynamic> producto;
  final double? precioInicial;
  final double? precioUnitInicial;
  final Future<double> Function({
    required BuildContext context,
    required double precioEmpaq,
    required double precioUnit,
    required String? fraccionStr,
  }) validateUnitPrice;

  const PreciosDialog({
    super.key,
    required this.producto,
    this.precioInicial,
    this.precioUnitInicial,
    required this.validateUnitPrice,
  });

  @override
  State<PreciosDialog> createState() => PreciosDialogState();
}

class PreciosDialogState extends State<PreciosDialog> {
  late TextEditingController _precioEmpaqCtrl;
  late TextEditingController _precioUnitCtrl;

  @override
  void initState() {
    super.initState();
    _precioEmpaqCtrl = TextEditingController(
      text: widget.precioInicial?.toString() ?? '',
    );
    _precioUnitCtrl = TextEditingController(
      text: widget.precioUnitInicial?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _precioEmpaqCtrl.dispose();
    _precioUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final isEdicion = widget.precioInicial != null;
    return AlertDialog(
      title: Text(isEdicion ? 'Actualizar precio' : 'Agregar producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Código', p['Cod_Prod']?.toString() ?? ''),
            _infoRow('Producto', p['Nom_Prod']?.toString() ?? ''),
            _infoRow(
              'Laboratorio',
              p['Nom_Titular']?.toString() ??
                  p['Nom_Fabricante']?.toString() ??
                  '',
            ),
            _infoRow('IFA', p['Nom_IFA']?.toString() ?? ''),
            _infoRow(
              'Forma Farmacéutica',
              p['Nom_Form_Farm']?.toString() ?? '',
            ),
            _infoRow('Concentración', p['Concent']?.toString() ?? ''),
            _infoRow('Fracción', p['Fraccion']?.toString() ?? ''),
            _infoRow('Presentación', p['Presentac']?.toString() ?? ''),
            _infoRow('Rubro', p['Nom_Rubro']?.toString() ?? ''),
            _infoRow('Situación', p['Situacion']?.toString() ?? ''),
            _infoRow('Reg. Sanitario', p['Num_RegSan']?.toString() ?? ''),
            const Divider(height: 24),
            Text(
              isEdicion ? 'Nuevos Precios' : 'Precios',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioEmpaqCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio Empaque',
                prefixText: 'S/ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioUnitCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio Unitario',
                prefixText: 'S/ ',
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
        TextButton(
          onPressed: _submit,
          child: Text(isEdicion ? 'Actualizar' : 'Agregar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final precioEmpaq = double.tryParse(_precioEmpaqCtrl.text) ?? 0.0;
    var precioUnit = double.tryParse(_precioUnitCtrl.text) ?? 0.0;

    final fraccionStr = widget.producto['Fraccion']?.toString();
    precioUnit = await widget.validateUnitPrice(
      context: context,
      precioEmpaq: precioEmpaq,
      precioUnit: precioUnit,
      fraccionStr: fraccionStr,
    );

    if (!mounted) return;
    final precios = {
      'precioEmpaq': precioEmpaq,
      'precioUnit': precioUnit,
    };
    Navigator.pop(context, precios);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
