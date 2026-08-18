// ─────────────────────────────────────────────────────────────
//  Producto — verificado contra el backend REAL
//  (ALIVETagroveterinaria, src/models/producto.model.js) y la
//  tabla `producto` real de alivetagroveterinaria_empresa.
//
//  SÍ existen: marca, ficha_tecnica, colores, composicion,
//  modo_uso, peso_presentacion, tallas — se habían quitado por
//  error antes, con el proyecto SISTEMA-WEB viejo. Ya restaurados.
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
  final String? fechaVencimiento;
  final String estado; // 'ACTIVO' | 'INACTIVO'

  // Campos de ficha técnica — sí existen en la tabla real
  final String? marca;
  final String? pesoPresentacion;
  final String? colores;
  final String? tallas;
  final String? fichaTecnica;
  final String? composicion;
  final String? modoUso;

  // Datos que llegan por JOIN, solo para mostrar
  final String? categoria;
  final String? tipoAnimal;

  // Presente en respuestas de /api/inventario/por-vencer
  final int? diasRestantes;

  // Fecha en que se creó el producto — sí existe en la tabla real
  // (columna fecha_creacion), se usa para el filtro Hoy/Semana/
  // Quincena/Mes en la pantalla de Inventario.
  final String? fechaCreacion;

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
    this.fechaVencimiento,
    required this.estado,
    this.marca,
    this.pesoPresentacion,
    this.colores,
    this.tallas,
    this.fichaTecnica,
    this.composicion,
    this.modoUso,
    this.categoria,
    this.tipoAnimal,
    this.diasRestantes,
    this.fechaCreacion,
  });

  bool get stockBajo => stockActual <= stockMinimo;

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
      fechaVencimiento: json['fecha_vencimiento'] as String?,
      estado: (json['estado'] as String?) ?? 'ACTIVO',
      marca: json['marca'] as String?,
      pesoPresentacion: json['peso_presentacion'] as String?,
      colores: json['colores'] as String?,
      tallas: json['tallas'] as String?,
      fichaTecnica: json['ficha_tecnica'] as String?,
      composicion: json['composicion'] as String?,
      modoUso: json['modo_uso'] as String?,
      categoria: json['categoria'] as String?,
      tipoAnimal: json['tipo_animal'] as String?,
      diasRestantes: json['dias_restantes'] != null
          ? int.tryParse(json['dias_restantes'].toString())
          : null,
      fechaCreacion: json['fecha_creacion'] as String?,
    );
  }

  /// Para crear/actualizar (POST/PUT /api/productos) — coincide
  /// exactamente con los campos que lee producto.model.js.
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'imagen': imagen,
        'precio_venta': precioVenta,
        'codigo_barra': codigoBarra,
        'id_categoria': idCategoria,
        'id_tipo_animal': idTipoAnimal,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        'fecha_vencimiento': fechaVencimiento,
        'marca': marca,
        'peso_presentacion': pesoPresentacion,
        'colores': colores,
        'tallas': tallas,
        'ficha_tecnica': fichaTecnica,
        'composicion': composicion,
        'modo_uso': modoUso,
      };
}
