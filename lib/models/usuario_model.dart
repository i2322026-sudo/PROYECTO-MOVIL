// ─────────────────────────────────────────────────────────────
//  Usuario — mapea la respuesta de POST /api/auth/login
//  y POST /api/auth/register (auth.controller.js):
//
//    res.json({ token, rol, nombre, apellido })
//
//  Hoy, usuario_service.dart guarda estos campos sueltos en
//  SharedPreferences. Este modelo deja listo el camino para
//  reemplazar esos Strings sueltos por un único objeto Usuario
//  más adelante, sin romper nada (es opcional, no se está
//  forzando ese cambio todavía).
// ─────────────────────────────────────────────────────────────
class Usuario {
  final String token;
  final String nombre;
  final String? apellido;
  final String correo;
  final String rol; // 'COLABORADOR' | 'CLIENTE'

  Usuario({
    required this.token,
    required this.nombre,
    this.apellido,
    required this.correo,
    this.rol = 'CLIENTE',
  });

  String get nombreCompleto =>
      apellido != null && apellido!.isNotEmpty ? '$nombre $apellido' : nombre;

  bool get esColaborador => rol == 'COLABORADOR';

  /// [correo] se pasa aparte porque el backend no lo devuelve en el
  /// login (solo token/rol/nombre/apellido) — viene del formulario.
  factory Usuario.fromJson(Map<String, dynamic> json, {required String correo}) {
    return Usuario(
      token: json['token'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String?,
      correo: correo,
      rol: json['rol'] as String? ?? 'CLIENTE',
    );
  }
}
