import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  ReporteService — GET /api/reportes/exportar/:entidad/:formato
//  (reporte.routes.js real). Requiere estar logueado como
//  COLABORADOR (dio ya manda el token solo).
//
//  Entidades válidas: productos, clientes, pedidos, categorias,
//  animales, colaboradores. Formatos: excel, pdf.
//
//  IMPORTANTE: el backend carga pdfkit/exceljs de forma "perezosa"
//  — si esas librerías no están instaladas en el servidor,
//  responde 503 con un JSON explicando qué falta, en vez del
//  archivo. Como pedimos la respuesta en bytes (responseType:
//  bytes) para poder descargar el archivo, dio NO parsea ese
//  JSON de error automáticamente — hay que decodificarlo a mano
//  para mostrar el mensaje real en vez de fallar en silencio.
// ─────────────────────────────────────────────────────────────
class ReporteService extends BaseService {
  Future<List<int>> exportar(String entidad, String formato) async {
    try {
      // IMPORTANTE: receiveTimeout de Dio es un timeout "por inactividad"
      // — solo corta si el servidor deja de mandar datos por completo
      // durante ese tiempo. Si el servidor va mandando el archivo muy
      // lento pero sin cortarse del todo (o se queda colgado generando
      // el PDF), Dio NUNCA lo detecta y la app puede quedar cargando
      // literalmente para siempre. Por eso agregamos ACÁ un límite
      // duro de tiempo total con .timeout(), que sí corta pase lo que
      // pase del lado del servidor.
      final res = await dio
          .get(
            '/reportes/exportar/$entidad/$formato',
            options: Options(
              responseType: ResponseType.bytes,
              sendTimeout: const Duration(seconds: 90),
              receiveTimeout: const Duration(seconds: 90),
            ),
          )
          .timeout(
            const Duration(seconds: 100),
            onTimeout: () => throw Exception(
              'El servidor está tardando demasiado en generar el archivo. '
              'Si estaba inactivo puede necesitar un minuto para reactivarse '
              '— intenta de nuevo.',
            ),
          );
      return res.data as List<int>;
    } on DioException catch (e) {
      throw _errorExportacion(e);
    }
  }

  Exception _errorExportacion(DioException e) {
    // Si el servidor respondió con error, e.response.data llega
    // como bytes crudos (por el responseType.bytes) aunque el
    // servidor haya mandado JSON. Intentamos decodificarlo.
    final data = e.response?.data;
    if (data is List<int>) {
      try {
        final texto = utf8.decode(data);
        final json = jsonDecode(texto);
        if (json is Map && json['mensaje'] != null) {
          return Exception(json['mensaje']);
        }
      } catch (_) {
        // No era JSON válido, seguimos con el mensaje genérico
      }
    }
    return errorDe(e);
  }

  /// URL directa para abrir el reporte en el navegador del celular
  /// (Chrome, etc.) en vez de compartirlo. El navegador no puede
  /// mandar el header Authorization, así que el token va como
  /// "?token=" — el backend (auth.middleware.js) ya lo acepta como
  /// respaldo cuando no llega el header.
  String urlParaNavegador(String entidad, String formato, String token) {
    final base = dio.options.baseUrl; // https://.../api
    return '$base/reportes/exportar/$entidad/$formato?token=$token';
  }
}
