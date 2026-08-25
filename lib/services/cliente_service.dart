import 'package:dio/dio.dart';
import '../models/cliente_model.dart';
import 'api_config.dart';
import 'base_service.dart';

class ClienteService extends BaseService {
  /// GET /api/clientes — requiere estar logueado como COLABORADOR
  Future<List<Cliente>> getClientes() async {
    try {
      final res = await dio.get(ApiConfig.clientes);
      return (res.data as List)
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PUT /api/clientes/:idPersona/estado — activar/desactivar, igual
  /// que toggleCliente() en dashboard.js. Nunca se elimina físicamente
  /// (el cliente puede tener pedidos/comprobantes que deben conservar
  /// su referencia) — desactivar solo le impide iniciar sesión y
  /// comprar, sin perder su historial.
  Future<void> cambiarEstado(int idPersona, String estado) async {
    try {
      await dio.put(
        '${ApiConfig.clientes}/$idPersona/estado',
        data: {'estado': estado},
      );
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// DELETE /api/clientes/:idPersona — Administrador/Gerente. El
  /// backend lo bloquea con 409 si el cliente tiene pedidos
  /// registrados (no se pierde historial de ventas por error).
  Future<void> eliminarCliente(int idPersona) async {
    try {
      await dio.delete('${ApiConfig.clientes}/$idPersona');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(e.response?.data['mensaje'] ??
            'No se puede eliminar: el cliente tiene pedidos registrados.');
      }
      throw errorDe(e);
    }
  }
}
