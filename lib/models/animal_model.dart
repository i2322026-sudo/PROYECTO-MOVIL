class TipoAnimal {
  final int idTipoAnimal;
  final String nombre;
  final String estado;

  TipoAnimal({
    required this.idTipoAnimal,
    required this.nombre,
    required this.estado,
  });

  factory TipoAnimal.fromJson(Map<String, dynamic> json) => TipoAnimal(
        idTipoAnimal: (json['id_tipo_animal'] as int?) ?? 0,
        nombre: (json['nombre'] as String?) ?? '',
        estado: (json['estado'] as String?) ?? 'ACTIVO',
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'estado': estado,
      };
}
