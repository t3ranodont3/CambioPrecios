import 'package:flutter/material.dart';
import '../models/report_record.dart';

class EditDialog extends StatefulWidget {
  final ReportRecord record;
  final int index;
  final Function(int) onDelete;
  final Future<double> Function({
    required BuildContext context,
    required double precioEmpaq,
    required double precioUnit,
    required String? fraccionStr,
  }) validateUnitPrice;
  final String? Function(String codProd) lookupFraccion;

  const EditDialog({
    super.key,
    required this.record,
    required this.index,
    required this.onDelete,
    required this.validateUnitPrice,
    required this.lookupFraccion,
  });

  @override
  State<EditDialog> createState() => EditDialogState();
}

class EditDialogState extends State<EditDialog> {
  late TextEditingController _precioEmpaqCtrl;
  late TextEditingController _precioUnitCtrl;

  @override
  void initState() {
    super.initState();
    _precioEmpaqCtrl = TextEditingController(
      text: widget.record.precioEmpaq.toString(),
    );
    _precioUnitCtrl = TextEditingController(
      text: widget.record.precioUnit.toString(),
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
    return AlertDialog(
      title: const Text('Editar precios'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Código: ${widget.record.codProd}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Producto: ${widget.record.nombreProducto}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Laboratorio: ${widget.record.laboratorio}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _precioEmpaqCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              decoration: const InputDecoration(
                labelText: 'Precio Unitario',
                prefixText: 'S/ ',
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () async {
            final confirmar = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: Text(
                  '¿Está seguro de eliminar el registro?\n\n'
                  'Código: ${widget.record.codProd}\n'
                  'Producto: ${widget.record.nombreProducto}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
            if (confirmar == true) {
              widget.onDelete(widget.index);
              if (context.mounted) Navigator.pop(context);
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar Producto'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _save,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final precioEmpaq = double.tryParse(_precioEmpaqCtrl.text) ?? 0.0;
    var precioUnit = double.tryParse(_precioUnitCtrl.text) ?? 0.0;

    final fraccion = widget.lookupFraccion(widget.record.codProd);
    precioUnit = await widget.validateUnitPrice(
      context: context,
      precioEmpaq: precioEmpaq,
      precioUnit: precioUnit,
      fraccionStr: fraccion,
    );

    if (!mounted) return;
    final updated = ReportRecord(
      codProd: widget.record.codProd,
      nombreProducto: widget.record.nombreProducto,
      fechaActualizacion: widget.record.fechaActualizacion,
      laboratorio: widget.record.laboratorio,
      ifa: widget.record.ifa,
      precioEmpaq: precioEmpaq,
      precioUnit: precioUnit,
    );
    Navigator.pop(context, updated);
  }
}
