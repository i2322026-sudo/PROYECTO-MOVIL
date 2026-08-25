// ─────────────────────────────────────────────────────────────
//  Subcategoria — GET /api/categorias/:id/subcategorias (pública,
//  usada en cascada al elegir Categoría, igual que
//  cargarSubcategorias() en dashboard.js).
// ─────────────────────────────────────────────────────────────
class Subcategoria {
  final int idSubcategoria;
  final String nombre;
  final String? descripcion;
  final String estado;
  final int idCategoria;

  Subcategoria({
    required this.idSubcategoria,
    required this.nombre,
    this.descripcion,
    this.estado = 'ACTIVO',
    required this.idCategoria,
  });

  factory Subcategoria.fromJson(Map<String, dynamic> json) => Subcategoria(
        idSubcategoria: (json['id_subcategoria'] as int?) ?? 0,
        nombre: (json['nombre'] as String?) ?? '',
        descripcion: json['descripcion'] as String?,
        estado: (json['estado'] as String?) ?? 'ACTIVO',
        idCategoria: (json['id_categoria'] as int?) ?? 0,
      );
}
