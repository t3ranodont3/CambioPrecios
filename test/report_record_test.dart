import 'package:flutter_test/flutter_test.dart';
import 'package:appnew_0/src/models/report_record.dart';

void main() {
  test('ReportRecord toMap and fromMap round trip', () {
    final r = ReportRecord(
      codProd: '12345',
      nombreProducto: 'Producto de Prueba',
      fechaActualizacion: '2026-03-07',
      laboratorio: 'Lab S.A.',
      ifa: 'IFA1',
      precioEmpaq: 12.5,
      precioUnit: 0.5,
    );

    final map = r.toMap();
    final r2 = ReportRecord.fromMap(Map<String, dynamic>.from(map));

    expect(r2.codProd, equals(r.codProd));
    expect(r2.nombreProducto, equals(r.nombreProducto));
    expect(r2.fechaActualizacion, equals(r.fechaActualizacion));
    expect(r2.laboratorio, equals(r.laboratorio));
    expect(r2.ifa, equals(r.ifa));
    expect(r2.precioEmpaq, equals(r.precioEmpaq));
    expect(r2.precioUnit, equals(r.precioUnit));
  });
}
