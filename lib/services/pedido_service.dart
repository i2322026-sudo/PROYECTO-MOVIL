import 'package:dio/dio.dart';
import '../models/pedido_model.dart';
import 'dio_client.dart';
import 'api_config.dart';

class PedidoService {
  final Dio _dio = DioClient.dio;

  // GET /api/pedidos — todos los pedidos
  Future<List<Pedido>> getPedidos() async {
    try {
      final res = await _dio.get(ApiConfig.pedidos);
      return (res.data as List)
          .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // GET /api/pedidos/:id — detalle completo
  Future<Map<String, dynamic>> getDetalle(int idPedido) async {
    try {
      final res = await _dio.get('${ApiConfig.pedidos}/$idPedido');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_error(e));
    }
  }

  // PUT /api/pedidos/:id/estado
  Future<void> actualizarEstado(int idPedido, String estado) async {
    try {
      await _dio.put(
        '${ApiConfig.pedidos}/$idPedido/estado',
        data: {'estado': estado},
      );
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
      return 'Sin conexión. Verifica que el servidor esté corriendo.';
    }
    final msg = e.response?.data?['mensaje'];
    return msg as String? ??
        'Error ${e.response?.statusCode ?? "desconocido"}';
  }
}