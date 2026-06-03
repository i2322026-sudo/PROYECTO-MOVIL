import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_client.dart';
import 'api_config.dart';

// ─────────────────────────────────────────────────────────────
//  UsuarioService — login, registro, sesión local
// ─────────────────────────────────────────────────────────────
class UsuarioService {
  final Dio _dio = DioClient.dio;

  // ── LOGIN ─────────────────────────────────────────────────
  Future<void> login(String correo, String password) async {
    try {
      final res = await _dio.post(
        ApiConfig.login,
        data: {'correo': correo, 'password': password},
      );

      // Guardar sesión en el dispositivo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token'] ?? '');
      await prefs.setString('nombre', res.data['nombre'] ?? '');
      await prefs.setString('correo', correo);
      await prefs.setString('rol', res.data['rol'] ?? 'CLIENTE');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception(
          e.response?.data['mensaje'] ?? 'Correo o contraseña incorrectos',
        );
      }
      throw Exception(_error(e));
    }
  }

  // ── REGISTRO ──────────────────────────────────────────────
  Future<void> registrar({
    required String nombres,
    required String apellidoPaterno,
    required String correo,
    required String password,
    String? telefono,
    String tipoDocumento = 'DNI',
    String? numeroDocumento,
  }) async {
    try {
      final res = await _dio.post(
        ApiConfig.registro,
        data: {
          'nombres': nombres,
          'apellidoPaterno': apellidoPaterno,
          'correo': correo,
          'password': password,
          'telefono': telefono,
          'tipoDocumento': tipoDocumento,
          'numeroDocumento': numeroDocumento,
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token'] ?? '');
      await prefs.setString('nombre', res.data['nombre'] ?? nombres);
      await prefs.setString('correo', correo);
      await prefs.setString('rol', res.data['rol'] ?? 'CLIENTE');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(
          e.response?.data['mensaje'] ?? 'Error en el registro',
        );
      }
      throw Exception(_error(e));
    }
  }

  // ── GETTERS DE SESIÓN LOCAL ───────────────────────────────
  Future<bool> estaLogueado() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString('token') ?? '').isNotEmpty;
  }

  Future<String> getNombre() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('nombre') ?? 'Usuario';
  }

  Future<String> getCorreo() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('correo') ?? '';
  }

  Future<String> getRol() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('rol') ?? 'CLIENTE';
  }

  // ── CERRAR SESIÓN ─────────────────────────────────────────
  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  // ── HELPER ERRORES ────────────────────────────────────────
  String _error(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Intenta de nuevo.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sin conexión. Verifica que el servidor esté '
          'corriendo y que la IP en api_config.dart sea correcta.';
    }
    return 'Error ${e.response?.statusCode ?? "desconocido"}';
  }
}
