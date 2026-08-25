import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil/core/app_navigator.dart';
import 'package:movil/screens/login_screen.dart';

class DioClient {
  static Dio? _instancia;
  static bool _redirigiendoAlLogin = false;

  static Dio get dio {
    _instancia ??= _crear();
    return _instancia!;
  }

  static Dio _crear() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://agropecuariorebeca.onrender.com/api',
      // El plan Free de Render "duerme" la instancia tras un rato de
      // inactividad, y el primer request tras eso puede tardar 50s+
      // solo en levantar el servidor (antes de que llegue a responder
      // nada). 20s se cortaba ANTES de que el server llegara a
      // contestar. Con 60s le damos margen real a ese arranque en frío.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      // El token dura 30 minutos (igual que en la web). Sin esto, la
      // pantalla se queda mostrando el error de "Sesión expirada"
      // con un botón "Reintentar" que va a volver a fallar siempre
      // — acá se detecta el 401, se borra la sesión vieja, y se
      // manda directo al login con un aviso claro.
      //
      // OJO: el login (contraseña incorrecta) TAMBIÉN responde 401
      // ("Credenciales incorrectas"), pero eso no es una sesión
      // vencida — ahí nunca hubo sesión. Por eso solo se activa este
      // mensaje si la petición llevaba un token guardado (es decir,
      // ya había una sesión que se cortó a mitad de camino).
      onError: (error, handler) async {
        final llevabaToken =
            error.requestOptions.headers['Authorization'] != null;
        if (error.response?.statusCode == 401 &&
            llevabaToken &&
            !_redirigiendoAlLogin) {
          _redirigiendoAlLogin = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          final nav = navigatorKey.currentState;
          if (nav != null) {
            nav.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final ctx = navigatorKey.currentContext;
              if (ctx != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Tu sesión expiró, vuelve a iniciar sesión.'),
                  ),
                );
              }
            });
          }
          _redirigiendoAlLogin = false;
        }
        handler.next(error);
      },
    ));

    return dio;
  }
}
