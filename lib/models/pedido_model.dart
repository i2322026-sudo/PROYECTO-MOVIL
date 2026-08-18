// ─────────────────────────────────────────────────────────────
//  Pedido — mapea la respuesta REAL de GET /api/pedidos
//  (dashboard.model.js → getPedidos):
//
//    SELECT p.id_pedido, p.fecha_pedido, p.total, p.costo_envio,
//           p.direccion_entrega, p.estado,
//           per.nombres   AS cliente_nombre,
//           z.nombre_zona AS zona,
//           tc.nombre     AS tipo_comprobante
//    FROM pedido p
//    JOIN cliente c ON p.id_cliente = c.id_cliente
//    JOIN persona per ON c.id_persona = per.id_persona
//    LEFT JOIN zona_envio z ON p.id_zona = z.id_zona
//    LEFT JOIN tipo_comprobante tc ON p.id_tipo_comprobante = tc.id_tipo_comprobante
//
//  NOTA: el backend NO tiene un endpoint GET /api/pedidos/:id que
//  devuelva el detalle línea por línea (productos del pedido con
//  color/talla/marca). Por eso este modelo ya NO incluye
//  `detalles` / `DetallePedidoItem` — esa función no existe todavía
//  en tu Express. Si la necesitas, hay que crear esa ruta primero.
// ─────────────────────────────────────────────────────────────
class Pedido {
  final int idPedido;
  final String? fecha;
  final double total;
  final double? costoEnvio;
  final String? cliente;
  final String? estado; // PENDIENTE | PAGADO | ENVIADO | ENTREGADO | CANCELADO
  final String? direccion;
  final String? zona;
  final String? tipoComprobante;

  Pedido({
    required this.idPedido,
    this.fecha,
    required this.total,
    this.costoEnvio,
    this.cliente,
    this.estado,
    this.direccion,
    this.zona,
    this.tipoComprobante,
  });

  /// Código corto tipo "#00000123" para mostrar en listas
  /// Mismo formato que usa la web (#3, #21, #20...): el número
  /// de id_pedido tal cual, sin ceros de relleno. Antes tenía
  /// padLeft(8,'0') y mostraba "#00000003" en vez de "#3" —
  /// ya no coincidía con el dashboard web.
  String get codigoPedido => idPedido.toString();

  DateTime? get fechaComoDateTime =>
      fecha != null ? DateTime.tryParse(fecha!) : null;

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: (json['id_pedido'] as int?) ?? 0,
      fecha: json['fecha_pedido'] as String?,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      costoEnvio: json['costo_envio'] != null
          ? double.tryParse(json['costo_envio'].toString())
          : null,
      cliente: json['cliente_nombre'] as String?,
      estado: json['estado'] as String?,
      direccion: json['direccion_entrega'] as String?,
      zona: json['zona'] as String?,
      tipoComprobante: json['tipo_comprobante'] as String?,
    );
  }
}
