// ✅ CONFIRMADO: el backend real (ALIVETagroveterinaria) SÍ tiene
// implementadas las rutas /api/colaboradores (colaborador.routes.js,
// colaborador.controller.js, colaborador.model.js). El aviso
// anterior era por el proyecto SISTEMA-WEB viejo, que no las tenía.
//
// ─────────────────────────────────────────────────────────────
//  Colaborador — mapea la respuesta de GET /api/colaboradores,
//  que viene de colaborador.model.js:
//
//    SELECT col.id_colaborador, col.dni, col.usuario, col.estado,
//           per.nombres, per.apellido_paterno, per.apellido_materno,
//           per.correo, per.telefono, per.id_persona,
//           car.nombre AS cargo, col.id_cargo
//    FROM colaborador col
//    JOIN persona per    ON col.id_persona = per.id_persona
//    LEFT JOIN cargo car ON col.id_cargo   = car.id_cargo
//
//  Usado por: nuevo_colaborador_screen.dart
// ─────────────────────────────────────────────────────────────
class Colaborador {
  final int idColaborador;
  final int? idPersona;
  final String? dni;
  final String? usuario;
  final String estado; // 'ACTIVO' | 'INACTIVO'
  final String nombres;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? correo;
  final String? telefono;
  final int? idCargo;
  final String? cargo;

  Colaborador({
    required this.idColaborador,
    this.idPersona,
    this.dni,
    this.usuario,
    required this.estado,
    required this.nombres,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.correo,
    this.telefono,
    this.idCargo,
    this.cargo,
  });

  String get nombreCompleto =>
      [nombres, apellidoPaterno, apellidoMaterno]
          .where((p) => p != null && p.isNotEmpty)
          .join(' ');

  factory Colaborador.fromJson(Map<String, dynamic> json) {
    return Colaborador(
      idColaborador: (json['id_colaborador'] as int?) ?? 0,
      idPersona: json['id_persona'] as int?,
      dni: json['dni'] as String?,
      usuario: json['usuario'] as String?,
      estado: (json['estado'] as String?) ?? 'ACTIVO',
      nombres: (json['nombres'] as String?) ?? '',
      apellidoPaterno: json['apellido_paterno'] as String?,
      apellidoMaterno: json['apellido_materno'] as String?,
      correo: json['correo'] as String?,
      telefono: json['telefono'] as String?,
      idCargo: json['id_cargo'] as int?,
      cargo: json['cargo'] as String?,
    );
  }

  /// Para enviar al crear/actualizar (POST/PUT /api/colaboradores)
  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'correo': correo,
        'telefono': telefono,
        'dni': dni,
        'id_cargo': idCargo,
        'usuario': usuario,
        'estado': estado,
      };
}

// ─────────────────────────────────────────────────────────────
//  Cargo — mapea GET /api/colaboradores/cargos
//    SELECT * FROM cargo WHERE estado='ACTIVO'
// ─────────────────────────────────────────────────────────────
class Cargo {
  final int idCargo;
  final String nombre;
  final String? descripcion;

  Cargo({required this.idCargo, required this.nombre, this.descripcion});

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(
      idCargo: (json['id_cargo'] as int?) ?? 0,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: json['descripcion'] as String?,
    );
  }
}
