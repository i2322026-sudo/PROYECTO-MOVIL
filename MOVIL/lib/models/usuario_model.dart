class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String token;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.token,
  });

  // El backend retorna: { mensaje, token, usuario: { id, nombre, correo } }
  factory Usuario.fromJson(Map<String, dynamic> json) {
    final u = json['usuario'];
    return Usuario(
      id: u['id'] ?? 0,
      nombre: u['nombre'] ?? '',
      correo: u['correo'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
