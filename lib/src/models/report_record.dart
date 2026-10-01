class ReportRecord {
  final String codProd;
  String nombreProducto;
  String fechaActualizacion;
  String laboratorio;
  String ifa;
  double precioEmpaq;
  double precioUnit;

  ReportRecord({
    required this.codProd,
    required this.nombreProducto,
    required this.fechaActualizacion,
    required this.laboratorio,
    required this.ifa,
    required this.precioEmpaq,
    required this.precioUnit,
  });

  factory ReportRecord.fromMap(Map<String, dynamic> map) => ReportRecord(
    codProd: map['codProd'] ?? '',
    nombreProducto: map['nombreProducto'] ?? '',
    fechaActualizacion: map['fechaActualizacion'] ?? '',
    laboratorio: map['laboratorio'] ?? '',
    ifa: map['ifa'] ?? '',
    precioEmpaq: (map['precioEmpaq'] as num?)?.toDouble() ?? 0.0,
    precioUnit: (map['precioUnit'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'codProd': codProd,
    'nombreProducto': nombreProducto,
    'fechaActualizacion': fechaActualizacion,
    'laboratorio': laboratorio,
    'ifa': ifa,
    'precioEmpaq': precioEmpaq,
    'precioUnit': precioUnit,
  };
}
