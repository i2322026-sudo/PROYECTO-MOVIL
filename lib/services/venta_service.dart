import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'base_service.dart';
import '../models/venta_model.dart';

// ─────────────────────────────────────────────────────────────
//  VentaService — GET /api/ventas (venta.routes.js real).
//  Mismos filtros que la web (public/js hace lo mismo con
//  fetch + querystring): estado, desde, hasta. El backend solo
//  considera venta a los pedidos PAGADO o ENTREGADO.
// ─────────────────────────────────────────────────────────────
class VentaService extends BaseService {
  Future<List<Venta>> listar({
    String? estado,
    String? desde,
    String? hasta,
  }) async {
    try {
      final res = await dio.get(ApiConfig.ventas, queryParameters: {
        if (estado != null && estado.isNotEmpty) 'estado': estado,
        if (desde != null && desde.isNotEmpty) 'desde': desde,
        if (hasta != null && hasta.isNotEmpty) 'hasta': hasta,
        // Traemos hasta 200 de una — la web pagina de a 20, pero en
        // el celular es más cómodo scrollear una sola lista larga
        // que agregar controles de paginado.
        'limite': 200,
      });
      final data = res.data as Map<String, dynamic>;
      final lista = (data['ventas'] as List? ?? []);
      return lista
          .map((e) => Venta.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// GET /api/ventas/exportar-excel — mismos filtros que listar().
  Future<List<int>> exportarExcel({
    String? estado,
    String? desde,
    String? hasta,
  }) async {
    try {
      final res = await dio
          .get(
            ApiConfig.ventasExportarExcel,
            queryParameters: {
              if (estado != null && estado.isNotEmpty) 'estado': estado,
              if (desde != null && desde.isNotEmpty) 'desde': desde,
              if (hasta != null && hasta.isNotEmpty) 'hasta': hasta,
            },
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
              'Intenta de nuevo en unos segundos.',
            ),
          );
      return res.data as List<int>;
    } on DioException catch (e) {
      throw _errorExportacion(e);
    }
  }

  Exception _errorExportacion(DioException e) {
    final data = e.response?.data;
    if (data is List<int>) {
      try {
        final texto = utf8.decode(data);
        final json = jsonDecode(texto);
        if (json is Map && json['mensaje'] != null) {
          return Exception(json['mensaje']);
        }
      } catch (_) {}
    }
    return errorDe(e);
  }
}
