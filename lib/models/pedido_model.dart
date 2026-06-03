class Pedido {
  final int     idPedido;
  final String? fecha;
  final double  total;
  final String? cliente;
  final String? estado;
  final String? direccion;
  final List<dynamic> detalles;

  Pedido({
    required this.idPedido,
    this.fecha,
    required this.total,
    this.cliente,
    this.estado,
    this.direccion,
    this.detalles = const [],
  });

  String get codigoPedido => idPedido.toString().padLeft(8, '0');

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido:  (json['id_pedido'] as int?) ?? 0,
      fecha:      json['fecha_pedido'] as String?,
      total:      double.tryParse(json['total'].toString()) ?? 0.0,
      // el backend devuelve cliente_nombre del JOIN
      cliente:    json['cliente_nombre'] as String? ??
                  json['cliente'] as String?,
      estado:     json['estado'] as String?,
      direccion:  json['direccion_entrega'] as String?,
      detalles:  (json['detalles'] as List?) ?? [],
    );
  }
}