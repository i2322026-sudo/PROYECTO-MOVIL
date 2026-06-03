import 'package:dio/dio.dart';
import '../models/producto_model.dart';
import 'dio_client.dart';
import 'api_config.dart';

class ProductoService {
  final Dio _dio = DioClient.dio;

  Future<List<Producto>> getProductos() async {
    try {
      final res = await _dio.get(ApiConfig.productos);
      return (res.data as List)
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // GET /api/inventario/bajo-stock
  Future<List<Producto>> getBajoStock({String? idTipoAnimal}) async {
    try {
      final res = await _dio.get(
        ApiConfig.bajoStock,
        queryParameters: idTipoAnimal != null
            ? {'id_tipo_animal': idTipoAnimal}
            : null,
      );
      return (res.data as List)
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // GET /api/inventario/por-vencer
  Future<List<Producto>> getProximosVencer({int dias = 30}) async {
    try {
      final res = await _dio.get(
        ApiConfig.porVencer,
        queryParameters: {'dias': dias},
      );
      return (res.data as List)
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // GET /api/inventario/buscar-codigo/:codigo
  Future<Producto?> buscarPorCodigo(String codigo) async {
    try {
      final res = await _dio.get('${ApiConfig.buscarCodigo}/$codigo');
      return Producto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(_error(e));
    }
  }

  // PUT /api/inventario/actualizar-stock/:id
  Future<void> actualizarStock(
      int idProducto, int cantidad, String? fechaVencimiento) async {
    try {
      await _dio.put(
        '${ApiConfig.actualizarStock}/$idProducto',
        data: {
          'cantidad': cantidad,
          if (fechaVencimiento != null)
            'fecha_vencimiento': fechaVencimiento,
        },
      );
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // POST /api/productos
  Future<void> crearProducto(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConfig.productos, data: data);
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // PUT /api/productos/:id
  Future<void> actualizarProducto(
      int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('${ApiConfig.productos}/$id', data: data);
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  String _error(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sin conexión. Verifica la IP en api_config.dart';
    }
    final msg = e.response?.data?['mensaje'];
    return msg as String? ??
        'Error ${e.response?.statusCode ?? "desconocido"}';
  }
}