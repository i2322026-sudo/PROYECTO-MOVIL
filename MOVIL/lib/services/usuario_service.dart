import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import 'api_config.dart';

class UsuarioService {

  // POST /api/auth/login → para LoginScreen en main.dart
  // Envía: { correo, password }
  // Recibe: { mensaje, token, usuario: { id, nombre, correo } }
  Future<Usuario> login(String correo, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'correo': correo,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final usuario = Usuario.fromJson(data);

        // Guardar sesión localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', usuario.token);
        await prefs.setString('nombre', usuario.nombre);
        await prefs.setString('correo', usuario.correo);
        await prefs.setInt('id', usuario.id);

        return usuario;
      } else if (response.statusCode == 401) {
        final data = json.decode(response.body);
        throw Exception(data['mensaje'] ?? 'Credenciales incorrectas');
      } else {
        throw Exception('Error al iniciar sesión');
      }
    } catch (e) {
      throw Exception('Sin conexión al servidor: $e');
    }
  }

  // Verificar si hay sesión guardada
  Future<bool> estaLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // Obtener nombre del usuario guardado
  Future<String> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre') ?? '';
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
