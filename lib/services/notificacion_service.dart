import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  NotificacionService — POST /api/auth/fcm-token SÍ existe en
//  el backend real (antes decía que no). Requiere estar logueado
//  (dio ya manda el token JWT automáticamente).
// ─────────────────────────────────────────────────────────────
class NotificacionService extends BaseService {
  final FirebaseMessaging _mensajeria = FirebaseMessaging.instance;

  /// Llamar una vez, justo después de un login exitoso.
  Future<void> inicializar() async {
    try {
      final permiso = await _mensajeria.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permiso.authorizationStatus != AuthorizationStatus.authorized &&
          permiso.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = await _mensajeria.getToken();
      if (token != null) await _registrarToken(token);
      _mensajeria.onTokenRefresh.listen(_registrarToken);

      FirebaseMessaging.onMessage.listen((m) {
        debugPrint('🔔 ${m.notification?.title}');
      });
    } catch (e) {
      debugPrint('Error notificaciones: $e');
    }
  }

  Future<void> _registrarToken(String token) async {
    try {
      await dio.post(ApiConfig.fcmToken, data: {'fcm_token': token});
    } on DioException catch (e) {
      debugPrint('Error registrando token FCM: ${e.message}');
    }
  }

  /// GET /api/notificaciones — historial (últimas 50).
  Future<List<Map<String, dynamic>>> getHistorial() async {
    try {
      final res = await dio.get(ApiConfig.notificaciones);
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// PUT /api/notificaciones/:id/leer
  Future<void> marcarLeida(int id) async {
    try {
      await dio.put(ApiConfig.marcarNotificacionLeida(id));
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
