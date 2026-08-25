import 'package:dio/dio.dart';
import '../models/colaborador_model.dart';
import 'api_config.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  ColaboradorService — el backend REAL (ALIVETagroveterinaria)
//  SÍ tiene estas rutas implementadas (colaborador.routes.js).
//  Antes decía que no existían porque solo conocía el proyecto
//  SISTEMA-WEB viejo, que no las tenía. Ya corregido.
// ─────────────────────────────────────────────────────────────
class ColaboradorService extends BaseService {
  Future<List<Colaborador>> getColaboradores() async {
    try {
      final res = await dio.get(ApiConfig.colaboradores);
      return (res.data as List)
          .map((e) => Colaborador.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<List<Cargo>> getCargos() async {
    try {
      final res = await dio.get(ApiConfig.cargos);
      return (res.data as List)
          .map((e) => Cargo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PASO 1 — POST /api/colaboradores/solicitar-creacion. Manda un
  /// código de 5 dígitos al correo cargado (igual que el registro
  /// de clientes) y devuelve un `pendingId` para el paso 2. NO crea
  /// todavía ninguna fila en la base — así se valida que el correo
  /// exista de verdad antes de dar de alta a alguien.
  Future<String> solicitarCreacion({
    required String nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    required String correo,
    String? telefono,
    required String password,
    required String dni,
    required int idCargo,
  }) async {
    try {
      // "usuario" ya no se pide en el formulario — el backend lo genera
      // solo a partir del correo (igual que en la web).
      final res = await dio.post('${ApiConfig.colaboradores}/solicitar-creacion', data: {
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'correo': correo,
        'telefono': telefono,
        'password': password,
        'dni': dni,
        'id_cargo': idCargo,
      });
      return res.data['pendingId'] as String;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PASO 2 — POST /api/colaboradores/confirmar-creacion. Si el
  /// código coincide, recién acá se crea la fila real.
  Future<void> confirmarCreacion({
    required String pendingId,
    required String otp,
  }) async {
    try {
      await dio.post('${ApiConfig.colaboradores}/confirmar-creacion', data: {
        'pendingId': pendingId,
        'otp': otp,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['mensaje'] ?? 'Código incorrecto');
      }
      throw errorDe(e);
    }
  }

  /// PUT /api/colaboradores/:id — requiere: nombres, apellido_paterno,
  /// apellido_materno, telefono, id_cargo, estado. "usuario" ya no se
  /// pide en el formulario — si no se manda, el backend conserva el
  /// que ya tenía (no lo borra).
  Future<void> actualizarColaborador({
    required int id,
    required String nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
    required int idCargo,
    required String estado,
  }) async {
    try {
      await dio.put('${ApiConfig.colaboradores}/$id', data: {
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'telefono': telefono,
        'id_cargo': idCargo,
        'estado': estado,
      });
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PASO 1 — PUT /api/colaboradores/:id/solicitar-reset-password.
  /// Igual que "Mi perfil": valida la contraseña actual + política de
  /// la nueva, y manda un código de 5 dígitos al correo del colaborador.
  /// Devuelve el `pendingId` para el paso 2. Todavía NO cambia nada.
  Future<String> solicitarResetPassword({
    required int id,
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      final res = await dio.put(
        ApiConfig.solicitarResetPasswordColaborador(id),
        data: {'passwordActual': passwordActual, 'passwordNueva': passwordNueva},
      );
      return res.data['pendingId'] as String;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PASO 2 — PUT /api/colaboradores/:id/confirmar-reset-password.
  /// Si el código coincide, recién ahí se guarda la nueva contraseña.
  Future<void> confirmarResetPassword({
    required int id,
    required String pendingId,
    required String otp,
  }) async {
    try {
      await dio.put(
        ApiConfig.confirmarResetPasswordColaborador(id),
        data: {'pendingId': pendingId, 'otp': otp},
      );
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// DELETE /api/colaboradores/:id — borrado físico real. El
  /// backend lo bloquea con 409 si el colaborador sigue ACTIVO
  /// (mismo criterio que Productos: desactivar antes de eliminar).
  Future<void> eliminarColaborador(int id) async {
    try {
      await dio.delete('${ApiConfig.colaboradores}/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(e.response?.data['mensaje'] ??
            'No se puede eliminar un colaborador activo. Desactívalo primero.');
      }
      throw errorDe(e);
    }
  }
}
