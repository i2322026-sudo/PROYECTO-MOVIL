class Categoria {
  final int idCategoria;
  final String nombre;
  final String? descripcion;
  final String estado;

  Categoria({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
    required this.estado,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        idCategoria: (json['id_categoria'] as int?) ?? 0,
        nombre: (json['nombre'] as String?) ?? '',
        descripcion: json['descripcion'] as String?,
        estado: (json['estado'] as String?) ?? 'ACTIVO',
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': estado,
      };
}
