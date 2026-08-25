import 'package:dio/dio.dart';
import 'api_config.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  DashboardService — verificado contra dashboard.routes.js real.
//  SÍ existen /ventas-mes, /productos-vendidos y /stock (se
//  habían quitado por error creyendo que no existían).
// ─────────────────────────────────────────────────────────────
class DashboardService extends BaseService {
  // Se guarda la URL COMPLETA (dominio + ruta + parámetros) de la
  // última consulta a top-clientes, tal como Dio la terminó armando y
  // enviando de verdad. Sirve para mostrarla en pantalla y confirmar
  // a qué servidor está llegando realmente, sin necesitar DevTools.
  static String? ultimaUrlTopClientes;

  /// GET /api/dashboard — incluye ventasTotal además de las 4
  /// estadísticas de siempre.
  Future<Map<String, dynamic>> getResumen() async {
    try {
      final res = await dio.get(ApiConfig.dashboard);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// GET /api/dashboard/ventas-mes — últimos 6 meses.
  Future<List<Map<String, dynamic>>> getVentasPorMes() async {
    try {
      final res = await dio.get(ApiConfig.ventasPorMes);
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// GET /api/dashboard/productos-vendidos — top 5.
  Future<List<Map<String, dynamic>>> getProductosMasVendidos() async {
    try {
      final res = await dio.get(ApiConfig.productosMasVendidos);
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// Top clientes por monto comprado — correo, nombres, total_pedidos,
  /// total_gastado. Usado en Promociones para elegir a quién mandarle.
  Future<List<Map<String, dynamic>>> getTopClientes({int limite = 10}) async {
    try {
      final res = await dio.get(
        ApiConfig.topClientesBase,
        queryParameters: {
          'limite': limite,
          // Anti-caché: en Flutter Web, el navegador puede reciclar la
          // respuesta de una URL idéntica en vez de volver a preguntarle
          // al servidor — mismo problema (y misma solución) que ya
          // resolvimos en venta_service.dart. Antes 'limite' iba pegado
          // directo en la ruta como texto y este parámetro se agregaba
          // aparte; ahora los dos van juntos en queryParameters, sin
          // ambigüedad de cómo Dio arma la URL final.
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      // res.requestOptions.uri es la URL final REAL que salió, no la
      // que nosotros armamos a mano — por eso es confiable.
      ultimaUrlTopClientes = res.requestOptions.uri.toString();
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      ultimaUrlTopClientes = e.requestOptions.uri.toString();
      throw errorDe(e);
    }
  }

  /// GET /api/dashboard/stock — top 10 con menor stock.
  Future<List<Map<String, dynamic>>> getStockProductos() async {
    try {
      final res = await dio.get(ApiConfig.stockProductos);
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
