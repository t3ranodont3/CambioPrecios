import 'package:flutter/material.dart';
import '../services/hive_helper.dart';
import '../services/storage_service.dart';

Future<double> validateUnitPrice({
  required BuildContext context,
  required double precioEmpaq,
  required double precioUnit,
  required String? fraccionStr,
}) async {
  if (fraccionStr == null || fraccionStr.trim().isEmpty) return precioUnit;

  final fraccion = double.tryParse(fraccionStr.trim());
  if (fraccion == null || fraccion <= 0) return precioUnit;

  final calculado = precioEmpaq / fraccion;
  final calculadoRound = double.parse(calculado.toStringAsFixed(2));
  final unitRound = double.parse(precioUnit.toStringAsFixed(2));

  if (calculadoRound == unitRound) return precioUnit;

  final usar = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Verificación de Precio Unitario'),
      content: Text(
        'El precio unitario calculado es:\n\n'
        'S/ ${precioEmpaq.toStringAsFixed(2)} ÷ $fraccion = '
        'S/ ${calculadoRound.toStringAsFixed(2)}\n\n'
        'Usted digitó: S/ ${unitRound.toStringAsFixed(2)}\n\n'
        '¿Desea usar el precio calculado?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text('Mantener S/ ${unitRound.toStringAsFixed(2)}'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text('Usar S/ ${calculadoRound.toStringAsFixed(2)}'),
        ),
      ],
    ),
  );

  return (usar == true) ? calculadoRound : precioUnit;
}

String? lookupFraccion(String codProd) {
  try {
    final box = HiveHelper.box(productsBoxName);
    for (final item in box.values) {
      if (item is Map) {
        final code = item['Cod_Prod']?.toString() ?? '';
        if (code == codProd) {
          return item['Fraccion']?.toString();
        }
      }
    }
  } catch (_) {}
  return null;
}
