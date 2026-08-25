// ─────────────────────────────────────────────────────────────
//  DetalleVenta — respuesta completa de GET /api/ventas/:idPedido
//  (venta.controller.js → exports.detalle). Trae el comprobante,
//  la lista de productos vendidos, y los totales — igual que el
//  modal "Detalle de Venta" del panel web.
// ─────────────────────────────────────────────────────────────

class ComprobanteVenta {
  final int idPedido;
  final String numero;
  final String tipo; // BOLETA | FACTURA
  final String? fecha;
  final String cliente;
  final String documento; // "DNI: 12345678" o "RUC: 20123..." o ""
  final bool esFactura;
  final String estado;
  final double costoEnvio;
  // 'DELIVERY' o 'RECOJO_TIENDA', tal cual en pedido.tipo_entrega.
  final String tipoEntrega;
  // Para RECOJO_TIENDA trae el texto fijo "Recojo en tienda — ALIVET
  // (...)"; para DELIVERY, la dirección real que puso el cliente.
  final String direccionEntrega;
  // Persona real de contacto (NO la razón social de la factura) —
  // quien recibe o recoge el pedido físicamente.
  final String contactoNombre;
  final String contactoTelefono;
  // Nota de dirección guardada por el cliente (ej. "casa azul, al lado
  // del grifo") — solo aplica cuando es Delivery.
  final String referencia;
  // Foto de evidencia de cancelación (repartidor no pudo entregar,
  // cliente rechazó el producto, etc.) — null si nunca se canceló así.
  final String? evidenciaUrl;

  ComprobanteVenta({
    required this.idPedido,
    required this.numero,
    required this.tipo,
    this.fecha,
    required this.cliente,
    required this.documento,
    required this.esFactura,
    required this.estado,
    required this.costoEnvio,
    required this.tipoEntrega,
    required this.direccionEntrega,
    required this.contactoNombre,
    required this.contactoTelefono,
    required this.referencia,
    this.evidenciaUrl,
  });

  factory ComprobanteVenta.fromJson(Map<String, dynamic> json) {
    return ComprobanteVenta(
      idPedido: (json['id_pedido'] as int?) ?? 0,
      numero: (json['numero'] as String?) ?? '-',
      tipo: (json['tipo'] as String?) ?? 'BOLETA',
      fecha: json['fecha'] as String?,
      cliente: (json['cliente'] as String?) ?? '—',
      documento: (json['documento'] as String?) ?? '',
      esFactura: (json['esFactura'] as bool?) ?? false,
      estado: (json['estado'] as String?) ?? '-',
      costoEnvio: double.tryParse(json['costo_envio'].toString()) ?? 0.0,
      tipoEntrega: (json['tipo_entrega'] as String?) ?? 'DELIVERY',
      direccionEntrega: (json['direccion_entrega'] as String?) ?? '',
      contactoNombre: (json['contacto_nombre'] as String?) ?? '',
      contactoTelefono: (json['contacto_telefono'] as String?) ?? '',
      referencia: (json['referencia'] as String?) ?? '',
      evidenciaUrl: json['evidencia_url'] as String?,
    );
  }
}

class ProductoVenta {
  final String producto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String color;
  final String talla;

  ProductoVenta({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.color,
    required this.talla,
  });

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    return ProductoVenta(
      producto: (json['producto'] as String?) ?? 'Producto',
      cantidad: (json['cantidad'] as int?) ?? 0,
      precioUnitario:
          double.tryParse(json['precio_unitario'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      color: (json['color'] as String?) ?? '',
      talla: (json['talla'] as String?) ?? '',
    );
  }
}

class TotalesVenta {
  final double subtotal;
  final double igv;
  final double total;

  TotalesVenta({required this.subtotal, required this.igv, required this.total});

  factory TotalesVenta.fromJson(Map<String, dynamic> json) {
    return TotalesVenta(
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      igv: double.tryParse(json['igv'].toString()) ?? 0.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
    );
  }
}

class DetalleVenta {
  final ComprobanteVenta comprobante;
  final List<ProductoVenta> productos;
  final TotalesVenta totales;

  DetalleVenta({
    required this.comprobante,
    required this.productos,
    required this.totales,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      comprobante:
          ComprobanteVenta.fromJson(json['comprobante'] as Map<String, dynamic>),
      productos: (json['productos'] as List? ?? [])
          .map((e) => ProductoVenta.fromJson(e as Map<String, dynamic>))
          .toList(),
      totales: TotalesVenta.fromJson(json['totales'] as Map<String, dynamic>),
    );
  }
}
