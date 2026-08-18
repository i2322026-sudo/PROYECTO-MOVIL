import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'base_service.dart';

class UsuarioService extends BaseService {
  /// Paso 1 — POST /api/auth/login. Si es un colaborador, el
  /// backend YA NO devuelve el token acá: manda un código al
  /// correo y responde con `pendingLoginId`. Un cliente (si algún
  /// día esta app lo permitiera) entraría directo, sin OTP.
  Future<LoginResultado> login(String correo, String password) async {
    try {
      final res = await dio.post(
        ApiConfig.login,
        data: {'correo': correo, 'password': password},
      );
      if (res.data['requiereOtp'] == true) {
        return LoginResultado.requiereOtp(res.data['pendingLoginId'] as String);
      }
      await _guardarSesion(res.data, correo);
      return LoginResultado.completo();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception(e.response?.data['mensaje'] ?? 'Correo o contraseña incorrectos');
      }
      if (e.response?.statusCode == 429) {
        throw Exception(e.response?.data['mensaje'] ??
            'Demasiados intentos. Intenta de nuevo en unos minutos.');
      }
      throw errorDe(e);
    }
  }

  /// Paso 2 — POST /api/auth/login-verificar-otp. Recién acá llega
  /// el token real, si el código coincide con el que se mandó al
  /// correo en login(). Se llama por cada inicio de sesión de
  /// colaborador, no solo la primera vez.
  Future<void> verificarOtpLogin({
    required String pendingLoginId,
    required String otp,
    required String correo,
  }) async {
    try {
      final res = await dio.post(ApiConfig.loginVerificarOtp, data: {
        'pendingLoginId': pendingLoginId,
        'otp': otp,
      });
      await _guardarSesion(res.data, correo);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['mensaje'] ?? 'Código incorrecto');
      }
      throw errorDe(e);
    }
  }

  Future<void> _guardarSesion(Map<String, dynamic> data, String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token'] ?? '');
    await prefs.setString('nombre', data['nombre'] ?? '');
    await prefs.setString('correo', correo);
    await prefs.setString('rol', data['rol'] ?? 'CLIENTE');
    await prefs.setString('cargo', data['cargo'] ?? '');
  }

  Future<void> registrar({
    required String nombres,
    required String apellidoPaterno,
    required String correo,
    required String password,
    String? apellidoMaterno,
    String? telefono,
    String tipoDocumento = 'DNI',
    String? numeroDocumento,
  }) async {
    try {
      final res = await dio.post(ApiConfig.registro, data: {
        'nombres': nombres,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'correo': correo,
        'password': password,
        'telefono': telefono,
        'tipoDocumento': tipoDocumento,
        'numeroDocumento': numeroDocumento,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token'] ?? '');
      await prefs.setString('nombre', res.data['nombre'] ?? nombres);
      await prefs.setString('correo', correo);
      await prefs.setString('rol', res.data['rol'] ?? 'CLIENTE');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['mensaje'] ?? 'Error en el registro');
      }
      throw errorDe(e);
    }
  }

  Future<Map<String, dynamic>> getPerfil() async {
    try {
      final res = await dio.get(ApiConfig.perfil);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> actualizarPerfil({
    required String nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
  }) async {
    try {
      await dio.put(ApiConfig.actualizarPerfil, data: {
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'telefono': telefono,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre', nombres);
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// Paso 1 — PUT /api/auth/cambiar-password. Si es colaborador, el
  /// backend YA NO cambia la clave directo: manda un OTP y responde
  /// requiereOtp:true + pendingId. El cambio real ocurre en el
  /// paso 2 (verificarOtpCambioPassword). Un cliente cambia directo.
  Future<CambioPasswordResultado> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      final res = await dio.put(ApiConfig.cambiarPassword, data: {
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
      });
      if (res.data['requiereOtp'] == true) {
        return CambioPasswordResultado.requiereOtp(res.data['pendingId'] as String);
      }
      return CambioPasswordResultado.completo();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['mensaje'] ?? 'Contraseña actual incorrecta');
      }
      throw errorDe(e);
    }
  }

  /// Paso 2 — PUT /api/auth/cambiar-password-verificar-otp.
  Future<void> verificarOtpCambioPassword({
    required String pendingId,
    required String otp,
  }) async {
    try {
      await dio.put(ApiConfig.cambiarPasswordVerificarOtp, data: {
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

  Future<bool> estaLogueado() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString('token') ?? '').isNotEmpty;
  }

  /// Token JWT guardado (para armar links que se abren fuera de la
  /// app, ej. "Abrir en el navegador" de los reportes en PDF).
  Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  /// Cargo del colaborador logueado (Administrador/Gerente/Vendedor/
  /// Asistente de ventas) — usado para ocultar del dashboard las
  /// secciones exclusivas del Administrador (Colaboradores,
  /// Promociones). Vacío si el token es de antes de este cambio;
  /// en ese caso conviene pedir que vuelva a iniciar sesión.
  Future<String> getCargo() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('cargo') ?? '';
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

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}

/// Resultado de login() — o queda completo de una (cliente), o
/// falta el paso 2 con el código OTP (colaborador).
class LoginResultado {
  final bool requiereOtp;
  final String? pendingLoginId;

  LoginResultado._(this.requiereOtp, this.pendingLoginId);

  factory LoginResultado.completo() => LoginResultado._(false, null);
  factory LoginResultado.requiereOtp(String pendingLoginId) =>
      LoginResultado._(true, pendingLoginId);
}

/// Resultado de cambiarPassword() — igual patrón que LoginResultado.
class CambioPasswordResultado {
  final bool requiereOtp;
  final String? pendingId;

  CambioPasswordResultado._(this.requiereOtp, this.pendingId);

  factory CambioPasswordResultado.completo() => CambioPasswordResultado._(false, null);
  factory CambioPasswordResultado.requiereOtp(String pendingId) =>
      CambioPasswordResultado._(true, pendingId);
}
