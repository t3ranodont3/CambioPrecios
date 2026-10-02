import 'package:flutter_test/flutter_test.dart';
import 'package:appnew_0/src/utils/report_column_mapper.dart';

void main() {
  test('maps the latest report columns by header rather than position', () {
    final columns = ReportColumnMapper.fromHeaders([
      'CodProd',
      'Nombre Producto',
      'Fecha Actualización',
      'Laboratorio',
      'IFA',
      'Num_RegSan',
      'Precio Empaq.',
      'Precio Unit.',
    ]);

    expect(columns.codProdIndex, 0);
    expect(columns.nombreProductoIndex, 1);
    expect(columns.fechaActualizacionIndex, 2);
    expect(columns.laboratorioIndex, 3);
    expect(columns.ifaIndex, 4);
    expect(columns.precioEmpaqIndex, 6);
    expect(columns.precioUnitIndex, 7);
  });

  test('supports the app-export price header and independent column order', () {
    final columns = ReportColumnMapper.fromHeaders([
      'Precio Unit.',
      'Precio Empaque',
      'IFA',
      'CodProd',
    ]);

    expect(columns.precioUnitIndex, 0);
    expect(columns.precioEmpaqIndex, 1);
    expect(columns.ifaIndex, 2);
    expect(columns.codProdIndex, 3);
  });

  test('normalizes accents and punctuation and matches header prefixes', () {
    final columns = ReportColumnMapper.fromHeaders([
      ' COD-PROD (DIGEMID)',
      'Nombre Producto - detalle',
      'FECHA ACTUALIZACIÓN (UTC)',
      'Laboratorio / fabricante',
      'IFA: descripción',
      'Precio Empaq. (S/)',
      'Precio Unit. (S/)',
    ]);

    expect(columns.codProdIndex, 0);
    expect(columns.nombreProductoIndex, 1);
    expect(columns.fechaActualizacionIndex, 2);
    expect(columns.laboratorioIndex, 3);
    expect(columns.ifaIndex, 4);
    expect(columns.precioEmpaqIndex, 5);
    expect(columns.precioUnitIndex, 6);
  });
}
