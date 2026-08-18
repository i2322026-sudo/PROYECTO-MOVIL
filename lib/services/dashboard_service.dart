import 'package:dio/dio.dart';
import 'api_config.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  DashboardService — verificado contra dashboard.routes.js real.
//  SÍ existen /ventas-mes, /productos-vendidos y /stock (se
//  habían quitado por error creyendo que no existían).
// ─────────────────────────────────────────────────────────────
class DashboardService extends BaseService {
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
      final res = await dio.get(ApiConfig.topClientes(limite: limite));
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
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
