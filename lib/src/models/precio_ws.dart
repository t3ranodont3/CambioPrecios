import 'package:xml/xml.dart';

/// Modelo que representa la estructura Precio del Web Service DIGEMID.
class PrecioWS {
  final int idProducto;
  final double precioMinUnit;
  final double precioMaxEmpaq;
  final double precioPromedio;
  final DateTime fecha;

  PrecioWS({
    required this.idProducto,
    required this.precioMinUnit,
    required this.precioMaxEmpaq,
    required this.precioPromedio,
    required this.fecha,
  });

  /// Crea un PrecioWS a partir de un elemento XML `Precio`.
  factory PrecioWS.fromXmlElement(XmlElement el) {
    String text(String tag) =>
        el.findElements(tag).firstOrNull?.innerText ?? '';

    return PrecioWS(
      idProducto: int.tryParse(text('IdProducto')) ?? 0,
      precioMinUnit: double.tryParse(text('PrecioMinUnit')) ?? 0.0,
      precioMaxEmpaq: double.tryParse(text('PrecioMaxEmpaq')) ?? 0.0,
      precioPromedio: double.tryParse(text('PrecioPromedio')) ?? 0.0,
      fecha: DateTime.tryParse(text('Fecha')) ?? DateTime.now(),
    );
  }

  /// Genera el fragmento XML para un <pre> (parámetro de ActualizarProducto).
  String toXmlFragment() {
    return '''
        <pre>
          <IdProducto>$idProducto</IdProducto>
          <PrecioMinUnit>$precioMinUnit</PrecioMinUnit>
          <PrecioMaxEmpaq>$precioMaxEmpaq</PrecioMaxEmpaq>
          <PrecioPromedio>$precioPromedio</PrecioPromedio>
          <Fecha>${fecha.toUtc().toIso8601String()}</Fecha>
        </pre>''';
  }

  @override
  String toString() =>
      'PrecioWS(id=$idProducto, minUnit=$precioMinUnit, maxEmpaq=$precioMaxEmpaq, prom=$precioPromedio, fecha=$fecha)';
}
