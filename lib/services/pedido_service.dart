import 'package:dio/dio.dart';
import '../models/pedido_model.dart';
import 'api_config.dart';
import 'base_service.dart';

class PedidoService extends BaseService {
  Future<List<Pedido>> getPedidos() async {
    try {
      final res = await dio.get(ApiConfig.pedidosAdmin);
      return (res.data as List)
          .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<List<Pedido>> getMisPedidos() async {
    try {
      final res = await dio.get(ApiConfig.misPedidos);
      return (res.data as List)
          .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> crearPedido(Map<String, dynamic> data) async {
    try {
      await dio.post(ApiConfig.pedidosCrear, data: data);
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> actualizarEstado(int idPedido, String estado) async {
    try {
      await dio.put(
        ApiConfig.actualizarEstadoPedido(idPedido),
        data: {'estado': estado},
      );
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// GET /api/pedidos/buscar-codigo/:codigo — identifica el pedido por
  /// su N° de boleta/factura (ej. "F001-000065", o solo el número)
  /// ANTES de subir la foto de evidencia.
  /// GET /api/pedidos/con-evidencia — pestaña "Historial" de Gestión
  /// de Evidencias: todos los pedidos que ya tienen foto subida.
  Future<List<Map<String, dynamic>>> getConEvidencia() async {
    try {
      final res = await dio.get('/pedidos/con-evidencia');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<Map<String, dynamic>> buscarPorCodigo(String codigo) async {
    try {
      final res = await dio.get(ApiConfig.buscarPedidoPorCodigo(codigo));
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PUT /api/pedidos/:id/evidencia-cancelacion — sube la foto y en el
  /// mismo paso el backend marca el pedido como CANCELADO.
  Future<void> subirEvidenciaCancelacion({
    required int idPedido,
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'imagen': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
      });
      await dio.put(
        ApiConfig.evidenciaCancelacion(idPedido),
        data: formData,
      );
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
