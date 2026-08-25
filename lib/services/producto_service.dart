import 'package:dio/dio.dart';
import '../models/producto_model.dart';
import 'api_config.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  ProductoService — verificado contra producto.controller.js
//  y producto.routes.js reales:
//   - GET /productos y GET /productos/:id son PÚBLICAS
//   - POST, PUT, DELETE y PUT /:id/estado requieren estar
//     logueado como COLABORADOR (dio ya manda el token solo)
//   - DELETE ahora es borrado FÍSICO permanente; falla con 409
//     si el producto tiene pedidos asociados (mensaje real del
//     servidor, no hay que adivinarlo)
// ─────────────────────────────────────────────────────────────
class ProductoService extends BaseService {
  Future<List<Producto>> getProductos({
    String? nombre,
    int? categoria,
    double? precioMin,
    double? precioMax,
    int? idTipoAnimal,
    // 'activos' (todo menos lo archivado) o 'archivados' — mismo
    // patrón que vistaProductosActual en dashboard.js. Por defecto
    // 'activos', igual que abre la pestaña web.
    String vista = 'activos',
  }) async {
    try {
      final res = await dio.get(ApiConfig.productos, queryParameters: {
        if (nombre != null) 'nombre': nombre,
        if (categoria != null) 'categoria': categoria,
        if (precioMin != null) 'precio_min': precioMin,
        if (precioMax != null) 'precio_max': precioMax,
        if (idTipoAnimal != null) 'id_tipo_animal': idTipoAnimal,
        // Esta app es solo para el panel admin: sin este parámetro
        // el backend oculta los productos INACTIVO — por eso al
        // desactivar uno "desaparecía" en vez de quedar visible
        // con el badge "Inactivo", igual que en el dashboard web.
        'incluirInactivos': true,
        'vista': vista,
        // Sin 'pagina' el backend igual pagina con LIMIT 20 por
        // defecto — subimos el límite para traer todo el inventario.
        'limite': 200,
        'pagina': 1,
      });
      // El backend responde distinto según venga o no 'pagina' en la
      // query (ver producto.controller.js -> exports.listar): con
      // 'pagina' devuelve { productos, total, ... }; sin ella, el
      // arreglo plano. Como aquí SIEMPRE mandamos 'pagina', hay que
      // leer res.data['productos'].
      final data = res.data;
      final lista = data is Map ? (data['productos'] as List? ?? []) : (data as List);
      return lista
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<Producto> getProductoPorId(int id) async {
    try {
      final res = await dio.get('${ApiConfig.productos}/$id');
      return Producto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> crearProducto(Producto producto) async {
    try {
      await dio.post(ApiConfig.productos, data: producto.toJson());
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> actualizarProducto(int id, Producto producto) async {
    try {
      await dio.put('${ApiConfig.productos}/$id', data: producto.toJson());
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// Borrado FÍSICO permanente. El backend responde 409 con un
  /// mensaje claro si el producto tiene pedidos asociados — ese
  /// mensaje llega tal cual gracias a BaseService.errorDe().
  Future<void> eliminarProducto(int id) async {
    try {
      await dio.delete('${ApiConfig.productos}/$id');
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// Activar/Desactivar — endpoint dedicado real
  /// (PUT /api/productos/:id/estado), más simple y seguro que
  /// mandar todo el producto de nuevo solo para cambiar el estado.
  Future<void> cambiarEstado(int id, String estado) async {
    try {
      await dio.put(ApiConfig.cambiarEstadoProducto(id),
          data: {'estado': estado});
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> desactivarProducto(int id) => cambiarEstado(id, 'INACTIVO');
  Future<void> activarProducto(int id) => cambiarEstado(id, 'ACTIVO');

  // ── INVENTARIO — endpoints reales dedicados ─────────────────

  /// GET /api/inventario/bajo-stock — ya filtrado en el servidor.
  Future<List<Producto>> getBajoStock({int? idTipoAnimal}) async {
    try {
      final res = await dio.get(ApiConfig.bajoStock, queryParameters: {
        if (idTipoAnimal != null) 'id_tipo_animal': idTipoAnimal,
      });
      return (res.data as List)
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// GET /api/inventario/por-vencer — incluye dias_restantes ya
  /// calculado por el servidor (DATEDIFF en SQL).
  Future<List<Producto>> getProximosVencer({int dias = 30}) async {
    try {
      final res = await dio.get(ApiConfig.porVencer, queryParameters: {
        'dias': dias,
      });
      return (res.data as List)
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// GET /api/inventario/buscar-codigo/:codigo
  Future<Producto?> buscarPorCodigo(String codigo) async {
    try {
      final res = await dio.get(ApiConfig.buscarPorCodigo(codigo));
      return Producto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw errorDe(e);
    }
  }

  /// PUT /api/inventario/actualizar-stock/:id — suma `cantidad`
  /// al stock actual (no lo reemplaza) y opcionalmente actualiza
  /// la fecha de vencimiento del nuevo lote.
  Future<void> actualizarStock(
      int idProducto, int cantidad, String? fechaVencimiento) async {
    try {
      await dio.put(ApiConfig.actualizarStock(idProducto), data: {
        'cantidad': cantidad,
        if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento,
      });
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
