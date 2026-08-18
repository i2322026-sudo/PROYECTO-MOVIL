// ─────────────────────────────────────────────────────────────
//  Cliente — mapea GET /api/clientes (cliente.model.js real):
//    SELECT p.id_persona, p.nombres, p.correo, p.telefono,
//           c.numero_documento, c.fecha_registro
//    FROM cliente c JOIN persona p ON c.id_persona = p.id_persona
// ─────────────────────────────────────────────────────────────
class Cliente {
  final int idPersona;
  final String nombres;
  final String? correo;
  final String? telefono;
  final String? numeroDocumento;
  final String? fechaRegistro;

  Cliente({
    required this.idPersona,
    required this.nombres,
    this.correo,
    this.telefono,
    this.numeroDocumento,
    this.fechaRegistro,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        idPersona: (json['id_persona'] as int?) ?? 0,
        nombres: (json['nombres'] as String?) ?? '',
        correo: json['correo'] as String?,
        telefono: json['telefono'] as String?,
        numeroDocumento: json['numero_documento'] as String?,
        fechaRegistro: json['fecha_registro'] as String?,
      );
}
