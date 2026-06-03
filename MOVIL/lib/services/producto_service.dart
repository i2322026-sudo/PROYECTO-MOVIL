import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto_model.dart';
import 'api_config.dart';

class ProductoService {

  // GET /api/productos → para mostrar lista general
  Future<List<Producto>> getProductos() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.productos))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sin conexión al servidor: $e');
    }
  }

  // GET /api/productos/bajostock → para BajoStock_Screen
  Future<List<Producto>> getBajoStock() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.productosBajoStock))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sin conexión al servidor: $e');
    }
  }

  // GET /api/productos/porvencer → para ProntoVencer_Screen
  Future<List<Producto>> getProximosVencer() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.productosProximosVencer))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sin conexión al servidor: $e');
    }
  }

  // POST /api/productos → para NuevoProducto screen
  Future<bool> crearProducto(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.productos),
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
