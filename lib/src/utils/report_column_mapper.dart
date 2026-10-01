class ReportColumnMapper {
  const ReportColumnMapper({
    required this.codProdIndex,
    required this.nombreProductoIndex,
    required this.fechaActualizacionIndex,
    required this.laboratorioIndex,
    required this.ifaIndex,
    required this.precioEmpaqIndex,
    required this.precioUnitIndex,
  });

  final int? codProdIndex;
  final int? nombreProductoIndex;
  final int? fechaActualizacionIndex;
  final int? laboratorioIndex;
  final int? ifaIndex;
  final int? precioEmpaqIndex;
  final int? precioUnitIndex;

  factory ReportColumnMapper.fromHeaders(List<String?> headers) {
    final normalizedHeaders = headers
        .map((header) => _normalize(header ?? ''))
        .toList();

    int? findIndex(List<String> prefixes) {
      final normalizedPrefixes = prefixes.map(_normalize).toList();
      for (var index = 0; index < normalizedHeaders.length; index++) {
        final header = normalizedHeaders[index];
        if (normalizedPrefixes.any(header.startsWith)) return index;
      }
      return null;
    }

    return ReportColumnMapper(
      codProdIndex: findIndex(['CodProd']),
      nombreProductoIndex: findIndex(['Nombre Producto']),
      fechaActualizacionIndex: findIndex(['Fecha Actualización', 'Fecha Act.']),
      laboratorioIndex: findIndex(['Laboratorio']),
      ifaIndex: findIndex(['IFA']),
      precioEmpaqIndex: findIndex(['Precio Empaq.', 'Precio Empaque']),
      precioUnitIndex: findIndex(['Precio Unit.']),
    );
  }

  static String _normalize(String value) {
    final withoutDiacritics = value
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
    return withoutDiacritics.replaceAll(RegExp('[^a-z0-9]'), '');
  }
}
