import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'base_service.dart';
import '../models/venta_model.dart';
import '../models/detalle_venta_model.dart';

// ─────────────────────────────────────────────────────────────
//  VentaService — GET /api/ventas (venta.routes.js real).
//  Mismos filtros que la web (public/js hace lo mismo con
//  fetch + querystring): estado, desde, hasta. El backend solo
//  considera venta a los pedidos PAGADO o ENTREGADO.
// ─────────────────────────────────────────────────────────────
class VentaService extends BaseService {
  // Se guarda la URL COMPLETA (dominio + ruta + parámetros) de la
  // última consulta a /ventas, tal como Dio la terminó armando y
  // enviando de verdad. Sirve para mostrarla en pantalla y confirmar
  // a qué servidor está llegando realmente, sin necesitar DevTools.
  static String? ultimaUrlConsultada;

  Future<List<Venta>> listar({
    String? estado,
    String? desde,
    String? hasta,
    // Búsqueda por código de comprobante — el backend acepta serie
    // ("B001"), número ("000069"/"69") o el código completo.
    String? codigo,
    // 'DELIVERY' o 'RECOJO_TIENDA' — igual que el filtro de la web.
    String? tipoEntrega,
    // 'activos' o 'historial' — igual que las pestañas de la web.
    // null = sin filtrar por vista (no debería pasar en la práctica,
    // la pantalla siempre manda una).
    String? vista,
  }) async {
    try {
      final res = await dio.get(
        ApiConfig.ventas,
        queryParameters: {
          if (estado != null && estado.isNotEmpty) 'estado': estado,
          if (desde != null && desde.isNotEmpty) 'desde': desde,
          if (hasta != null && hasta.isNotEmpty) 'hasta': hasta,
          if (codigo != null && codigo.trim().isNotEmpty) 'codigo': codigo.trim(),
          if (tipoEntrega != null && tipoEntrega.isNotEmpty)
            'tipoEntrega': tipoEntrega,
          if (vista != null && vista.isNotEmpty) 'vista': vista,
          // Traemos hasta 200 de una — la web pagina de a 20, pero en
          // el celular es más cómodo scrollear una sola lista larga
          // que agregar controles de paginado.
          'limite': 200,
          // Anti-caché: en Flutter Web, el navegador puede reciclar la
          // respuesta de una URL idéntica en vez de volver a preguntarle
          // al servidor. Al agregar un valor único (timestamp) en cada
          // llamada, la URL nunca se repite exactamente, así que el
          // navegador siempre pide la respuesta fresca.
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
        ),
      );
      // res.requestOptions.uri es la URL final REAL que salió,
      // no la que nosotros armamos a mano — por eso es confiable.
      ultimaUrlConsultada = res.requestOptions.uri.toString();
      final data = res.data as Map<String, dynamic>;
      final lista = (data['ventas'] as List? ?? []);
      return lista
          .map((e) => Venta.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // También se guarda si falla, para poder diagnosticar errores
      // de conexión (por ejemplo, si apunta a una URL que no responde).
      ultimaUrlConsultada = e.requestOptions.uri.toString();
      throw errorDe(e);
    }
  }

  /// GET /api/ventas/exportar-excel — mismos filtros que listar().
  Future<List<int>> exportarExcel({
    String? estado,
    String? desde,
    String? hasta,
    String? codigo,
    String? tipoEntrega,
    String? vista,
  }) async {
    try {
      final res = await dio
          .get(
            ApiConfig.ventasExportarExcel,
            queryParameters: {
              if (estado != null && estado.isNotEmpty) 'estado': estado,
              if (desde != null && desde.isNotEmpty) 'desde': desde,
              if (hasta != null && hasta.isNotEmpty) 'hasta': hasta,
              if (codigo != null && codigo.trim().isNotEmpty) 'codigo': codigo.trim(),
              if (tipoEntrega != null && tipoEntrega.isNotEmpty)
                'tipoEntrega': tipoEntrega,
              if (vista != null && vista.isNotEmpty) 'vista': vista,
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

  /// GET /api/ventas/:idPedido — detalle completo de un comprobante
  /// emitido (productos, DNI/RUC del cliente, subtotal/IGV/total).
  /// Igual que el modal "Detalle de Venta" del panel web.
  Future<DetalleVenta> obtenerDetalle(int idPedido) async {
    try {
      final res = await dio.get(
        ApiConfig.detalleVenta(idPedido),
        queryParameters: {
          // Anti-caché: como cada pedido tiene su propia URL fija
          // (/ventas/67, /ventas/60...), si abres el MISMO pedido
          // varias veces en pruebas distintas, el navegador puede
          // reciclar la respuesta vieja de la primera vez — aunque el
          // servidor ya haya sido corregido después. Mismo problema
          // (y misma solución) que ya resolvimos en listar().
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      return DetalleVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw errorDe(e);
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
