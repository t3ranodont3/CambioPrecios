class ImportValidation {
  ImportValidation._();

  static String? validateCodProd(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de producto es requerido';
    }
    if (value.length > 20) {
      return 'El código no puede exceder 20 caracteres';
    }
    return null;
  }

  static String? validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del producto es requerido';
    }
    if (value.length > 200) {
      return 'El nombre no puede exceder 200 caracteres';
    }
    return null;
  }

  static String? validatePrecio(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return allowZero ? null : 'El precio es requerido';
    }
    final precio = double.tryParse(value);
    if (precio == null) {
      return 'Ingrese un número válido';
    }
    if (!allowZero && precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    if (precio > 999999.99) {
      return 'El precio excede el máximo permitido';
    }
    return null;
  }

  static String? validateRuc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El RUC es requerido';
    }
    if (value.length != 11) {
      return 'El RUC debe tener exactamente 11 dígitos';
    }
    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      return 'El RUC solo debe contener dígitos';
    }
    return null;
  }

  static String? validateEstablecimiento(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de establecimiento es requerido';
    }
    if (value.length > 7) {
      return 'El código no puede exceder 7 caracteres';
    }
    return null;
  }

  static Map<String, String> validateExcelRow({
    required String codProd,
    required String nombre,
    required String precioEmpaqStr,
    required String precioUnitStr,
  }) {
    final errors = <String, String>{};

    final codError = validateCodProd(codProd);
    if (codError != null) errors['codProd'] = codError;

    final nombreError = validateNombre(nombre);
    if (nombreError != null) errors['nombre'] = nombreError;

    if (precioEmpaqStr.isNotEmpty) {
      final p1Error = validatePrecio(precioEmpaqStr);
      if (p1Error != null) errors['precioEmpaq'] = p1Error;
    }

    if (precioUnitStr.isNotEmpty) {
      final p2Error = validatePrecio(precioUnitStr);
      if (p2Error != null) errors['precioUnit'] = p2Error;
    }

    return errors;
  }
}
