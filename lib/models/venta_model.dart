// ─────────────────────────────────────────────────────────────
//  Venta — una fila de la lista de "Gestión de Ventas" (comprobante
//  emitido). Verificado contra venta.model.js: SELECT_LISTA
//  devuelve id_pedido, comprobante, fecha, cliente, tipo, total,
//  metodo_pago, estado.
// ─────────────────────────────────────────────────────────────
class Venta {
  final int idPedido;
  final String comprobante;
  final String? fecha;
  final String cliente;
  final String tipo; // BOLETA | FACTURA
  final double total;
  final String metodoPago;
  final String estado; // PAGADO | ENTREGADO

  Venta({
    required this.idPedido,
    required this.comprobante,
    this.fecha,
    required this.cliente,
    required this.tipo,
    required this.total,
    required this.metodoPago,
    required this.estado,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idPedido: (json['id_pedido'] as int?) ?? 0,
      comprobante: (json['comprobante'] as String?) ?? '-',
      fecha: json['fecha'] as String?,
      cliente: (json['cliente'] as String?) ?? 'Cliente',
      tipo: (json['tipo'] as String?) ?? 'BOLETA',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      metodoPago: (json['metodo_pago'] as String?) ?? '-',
      estado: (json['estado'] as String?) ?? '-',
    );
  }
}
