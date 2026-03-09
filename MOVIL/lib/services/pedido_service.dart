import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pedido_model.dart';
import 'api_config.dart';

class PedidoService {

  // GET /api/pedidos → para GestionPedido_Screen
  Future<List<Pedido>> getPedidos() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.pedidos))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Pedido.fromJson(item)).toList();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sin conexión al servidor: $e');
    }
  }

  // POST /api/pedidos → crear nuevo pedido
  // data ejemplo: { id_cliente: 1, total: 155.00, productos: [{id_producto: 1, cantidad: 2}] }
  Future<bool> crearPedido(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.pedidos),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Sin conexión al servidor: $e');
    }
  }
}
