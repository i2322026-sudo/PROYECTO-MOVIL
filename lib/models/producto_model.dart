// ─────────────────────────────────────────────────────────────
//  Producto — modelo que mapea la respuesta JSON del backend
// ─────────────────────────────────────────────────────────────
class Producto {
  final int idProducto;
  final String nombre;
  final String? descripcion;
  final String? imagen;
  final double precioVenta;
  final String? codigoBarra;
  final int? idCategoria;
  final int? idTipoAnimal;
  final int stockActual;
  final int stockMinimo;
  final int? stockAlerta;
  final String? fechaVencimiento;
  final String estado;
  final String? categoria;
  final String? tipoAnimal;
  final int? diasRestantes; // ← NUEVO: viene del backend

  Producto({
    required this.idProducto,
    required this.nombre,
    this.descripcion,
    this.imagen,
    required this.precioVenta,
    this.codigoBarra,
    this.idCategoria,
    this.idTipoAnimal,
    required this.stockActual,
    required this.stockMinimo,
    this.stockAlerta,
    this.fechaVencimiento,
    required this.estado,
    this.categoria,
    this.tipoAnimal,
    this.diasRestantes,
  });

  // Usa diasRestantes del backend, si no lo calcula localmente
  int? get diasParaVencer {
    if (diasRestantes != null) return diasRestantes;
    if (fechaVencimiento == null) return null;
    // Soporta "2026-12-31" y "2026-12-31T00:00:00.000Z"
    final limpio = fechaVencimiento!.split('T').first.trim();
    final fecha = DateTime.tryParse(limpio);
    if (fecha == null) return null;
    final hoy =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return fecha.difference(hoy).inDays;
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: (json['id_producto'] as int?) ?? 0,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: json['descripcion'] as String?,
      imagen: json['imagen'] as String?,
      precioVenta: double.tryParse(json['precio_venta'].toString()) ?? 0.0,
      codigoBarra: json['codigo_barra'] as String?,
      idCategoria: json['id_categoria'] as int?,
      idTipoAnimal: json['id_tipo_animal'] as int?,
      stockActual: (json['stock_actual'] as int?) ?? 0,
      stockMinimo: (json['stock_minimo'] as int?) ?? 0,
      stockAlerta: json['stock_alerta'] as int?,
      fechaVencimiento: json['fecha_vencimiento'] as String?,
      estado: (json['estado'] as String?) ?? 'ACTIVO',
      categoria: json['categoria'] as String?,
      tipoAnimal: json['tipo_animal'] as String?,
      diasRestantes: json['dias_restantes'] != null
          ? int.tryParse(json['dias_restantes'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio_venta': precioVenta,
        'codigo_barra': codigoBarra,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        'stock_alerta': stockAlerta,
        'id_categoria': idCategoria,
        'id_tipo_animal': idTipoAnimal,
        'fecha_vencimiento': fechaVencimiento,    
      };
}
