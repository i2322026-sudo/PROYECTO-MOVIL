class TipoAnimal {
  final int idTipoAnimal;
  final String nombre;
  final String estado;
  // 'MAYOR' | 'MENOR' — SELECT * FROM tipo_animal ya lo devuelve
  // (animal.model.js), solo no se estaba leyendo del lado del móvil.
  // Se usa para el filtro en cascada "Grupo de Animal" -> "Tipo de
  // Animal" del formulario de Nuevo Producto, igual que en la web.
  final String grupo;

  TipoAnimal({
    required this.idTipoAnimal,
    required this.nombre,
    required this.estado,
    this.grupo = 'MENOR',
  });

  factory TipoAnimal.fromJson(Map<String, dynamic> json) => TipoAnimal(
        idTipoAnimal: (json['id_tipo_animal'] as int?) ?? 0,
        nombre: (json['nombre'] as String?) ?? '',
        estado: (json['estado'] as String?) ?? 'ACTIVO',
        grupo: (json['grupo'] as String?) ?? 'MENOR',
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'estado': estado,
        'grupo': grupo,
      };
}
