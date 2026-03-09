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
  });

  // Días restantes para vencer (usado en ProntoVencer_Screen)
  int? get diasParaVencer {
    if (fechaVencimiento == null) return null;
    final fecha = DateTime.tryParse(fechaVencimiento!);
    if (fecha == null) return null;
    return fecha.difference(DateTime.now()).inDays;
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: json['id_producto'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      precioVenta: double.tryParse(json['precio_venta'].toString()) ?? 0.0,
      codigoBarra: json['codigo_barra'],
      idCategoria: json['id_categoria'],
      idTipoAnimal: json['id_tipo_animal'],
      stockActual: json['stock_actual'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 0,
      stockAlerta: json['stock_alerta'],
      fechaVencimiento: json['fecha_vencimiento'],
      estado: json['estado'] ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_venta': precioVenta,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'id_categoria': idCategoria,
      'id_tipo_animal': idTipoAnimal,
      'fecha_vencimiento': fechaVencimiento,
    };
  }
}
