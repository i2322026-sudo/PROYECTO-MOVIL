class Pedido {
  final int idPedido;
  final String? fecha;
  final double total;
  final String? cliente; // viene como nombre del JOIN con cliente

  Pedido({
    required this.idPedido,
    this.fecha,
    required this.total,
    this.cliente,
  });

  // Código formateado para mostrar en GestionPedido_Screen
  String get codigoPedido => idPedido.toString().padLeft(8, '0');

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: json['id_pedido'] ?? 0,
      fecha: json['fecha'],
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      cliente: json['cliente'],
    );
  }
}
