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
}
