import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/precio_ws.dart';

/// Servicio para comunicarse con el Web Service SOAP ServicePrecios de DIGEMID.
class DigemidService {
  /// URL base del ASMX. Se puede ajustar desde la config.
  String baseUrl;

  /// Credenciales SOAP (AuthHeader).
  final String wsUsername;
  final String wsPassword;

  DigemidService({
    required this.baseUrl,
    required this.wsUsername,
    required this.wsPassword,
  });

  // ---------------------------------------------------------------------------
  // 1. ObtenerListaProductos
  // ---------------------------------------------------------------------------
  /// Obtiene la lista de precios de una sucursal.
  Future<List<PrecioWS>> obtenerListaProductos(String idSucursal) async {
    final body = _buildEnvelope(
      soapAction: 'ObtenerListaProductos',
      bodyContent: '''
    <ObtenerListaProductos xmlns="http://tempuri.org/">
      <idSucursal>$idSucursal</idSucursal>
    </ObtenerListaProductos>''',
    );

    final response = await _postSoap(
      soapAction: 'http://tempuri.org/ObtenerListaProductos',
      body: body,
    );

    final doc = XmlDocument.parse(response.body);
    final precios = doc
        .findAllElements('Precio')
        .map((el) => PrecioWS.fromXmlElement(el))
        .toList();

    return precios;
  }

  // ---------------------------------------------------------------------------
  // 2. ActualizarProducto
  // ---------------------------------------------------------------------------
  /// Actualiza un producto de una sucursal.
  Future<String> actualizarProducto({
    required String idSucursal,
    required PrecioWS precio,
  }) async {
    final body = _buildEnvelope(
      soapAction: 'ActualizarProducto',
      bodyContent: '''
    <ActualizarProducto xmlns="http://tempuri.org/">
      <idSucursal>$idSucursal</idSucursal>
${precio.toXmlFragment()}
    </ActualizarProducto>''',
    );

    final response = await _postSoap(
      soapAction: 'http://tempuri.org/ActualizarProducto',
      body: body,
    );

    final doc = XmlDocument.parse(response.body);
    final result =
        doc.findAllElements('ActualizarProductoResult').firstOrNull?.innerText ??
            'Sin respuesta';
    return result;
  }

  // ---------------------------------------------------------------------------
  // 3. DeshabilitarProducto
  // ---------------------------------------------------------------------------
  /// Deshabilita un producto de una sucursal.
  Future<String> deshabilitarProducto({
    required String idSucursal,
    required String idProducto,
  }) async {
    final body = _buildEnvelope(
      soapAction: 'DeshabilitarProducto',
      bodyContent: '''
    <DeshabilitarProducto xmlns="http://tempuri.org/">
      <idSucursal>$idSucursal</idSucursal>
      <idProducto>$idProducto</idProducto>
    </DeshabilitarProducto>''',
    );

    final response = await _postSoap(
      soapAction: 'http://tempuri.org/DeshabilitarProducto',
      body: body,
    );

    final doc = XmlDocument.parse(response.body);
    final result = doc
            .findAllElements('DeshabilitarProductoResult')
            .firstOrNull
            ?.innerText ??
        'Sin respuesta';
    return result;
  }

  // ---------------------------------------------------------------------------
  // 4. ReplicarPrecios
  // ---------------------------------------------------------------------------
  /// Replica los precios de una sucursal.
  Future<String> replicarPrecios(String idSucursal) async {
    final body = _buildEnvelope(
      soapAction: 'ReplicarPrecios',
      bodyContent: '''
    <ReplicarPrecios xmlns="http://tempuri.org/">
      <idSucursal>$idSucursal</idSucursal>
    </ReplicarPrecios>''',
    );

    final response = await _postSoap(
      soapAction: 'http://tempuri.org/ReplicarPrecios',
      body: body,
    );

    final doc = XmlDocument.parse(response.body);
    final result =
        doc.findAllElements('ReplicarPreciosResult').firstOrNull?.innerText ??
            'Sin respuesta';
    return result;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Construye el envelope SOAP 1.1 con AuthHeader.
  String _buildEnvelope({
    required String soapAction,
    required String bodyContent,
  }) {
    return '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>
    <AuthHeader xmlns="http://tempuri.org/">
      <Username>$wsUsername</Username>
      <Password>$wsPassword</Password>
    </AuthHeader>
  </soap:Header>
  <soap:Body>
$bodyContent
  </soap:Body>
</soap:Envelope>''';
  }

  /// Envía la petición POST SOAP.
  Future<http.Response> _postSoap({
    required String soapAction,
    required String body,
  }) async {
    final uri = Uri.parse(baseUrl);

    debugPrint('SOAP → $soapAction');
    debugPrint('URL  → $baseUrl');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': soapAction,
      },
      body: body,
    );

    debugPrint('SOAP ← status ${response.statusCode}');

    if (response.statusCode != 200) {
      throw DigemidServiceException(
        'Error HTTP ${response.statusCode}: ${response.reasonPhrase}',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    // Verificar si la respuesta contiene un Fault SOAP
    if (response.body.contains('soap:Fault') ||
        response.body.contains('soap12:Fault')) {
      final doc = XmlDocument.parse(response.body);
      final faultString =
          doc.findAllElements('faultstring').firstOrNull?.innerText ??
              'Error SOAP desconocido';
      throw DigemidServiceException('SOAP Fault: $faultString');
    }

    return response;
  }
}

/// Excepción personalizada para errores del servicio DIGEMID.
class DigemidServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  DigemidServiceException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => 'DigemidServiceException: $message';
}
