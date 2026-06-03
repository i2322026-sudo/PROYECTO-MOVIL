import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

// ─────────────────────────────────────────────────────────────
//  DioClient — instancia única de Dio para toda la app.
//
//  Hace dos cosas automáticamente en CADA petición:
//    1. Agrega el token JWT en el header Authorization
//    2. Imprime errores claros en consola para depurar
// ─────────────────────────────────────────────────────────────
class DioClient {
  static Dio? _instancia;

  // Accede siempre con: DioClient.dio
  static Dio get dio {
    _instancia ??= _construir();
    return _instancia!;
  }

  static Dio _construir() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.base,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // Antes de cada request: inyecta el token si existe
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token') ?? '';
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        // En cada error: imprime info útil para depurar
        onError: (DioException e, handler) {
          final status = e.response?.statusCode ?? 'sin respuesta';
          final path = e.requestOptions.path;
          debugPrint('❌ DioError [$status] → $path');
          debugPrint('   Tipo:    ${e.type}');
          debugPrint('   Mensaje: ${e.message}');
          handler.next(e);
        },
      ),
    );

    return dio;
  }
}
