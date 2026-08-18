import 'package:dio/dio.dart';
import 'api_config.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  PromocionService — POST /api/auth/enviar-promocion
//  (promocion.controller.js real). Multipart/form-data:
//    correo  (opcional — si se omite, se manda a TODOS los
//             clientes registrados)
//    asunto  (obligatorio)
//    mensaje (obligatorio)
//    imagen  (opcional — el backend la sube a Cloudflare R2 y
//             la incrusta en el correo)
//  Requiere estar logueado como COLABORADOR (dio ya manda el
//  token solo).
// ─────────────────────────────────────────────────────────────
class PromocionService extends BaseService {
  Future<void> enviar({
    String? correo,
    required String asunto,
    required String mensaje,
    List<int>? imagenBytes,
    String? imagenNombre,
  }) async {
    try {
      final data = FormData.fromMap({
        if (correo != null && correo.isNotEmpty) 'correo': correo,
        'asunto': asunto,
        'mensaje': mensaje,
        if (imagenBytes != null)
          'imagen': MultipartFile.fromBytes(
            imagenBytes,
            filename: imagenNombre ?? 'promocion.jpg',
          ),
      });
      await dio.post(
        ApiConfig.enviarPromocion,
        data: data,
        options: Options(
          // El envío a TODOS los clientes manda un correo por
          // cada uno en un bucle secuencial del lado del servidor
          // — puede tardar bastante más que un request normal.
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// El backend solo acepta UN correo por request (o ninguno = todos),
  /// no una lista. Para mandarle a varios clientes elegidos a mano
  /// (ej. el Top 10), se llama una vez por cada uno acá mismo. Se
  /// reporta el progreso con [onProgreso] y se listan los que
  /// fallaron al final en vez de cortar todo el envío.
  Future<List<String>> enviarAVarios({
    required List<String> correos,
    required String asunto,
    required String mensaje,
    List<int>? imagenBytes,
    String? imagenNombre,
    void Function(int enviados, int total)? onProgreso,
  }) async {
    final fallidos = <String>[];
    for (var i = 0; i < correos.length; i++) {
      try {
        await enviar(
          correo: correos[i],
          asunto: asunto,
          mensaje: mensaje,
          imagenBytes: imagenBytes,
          imagenNombre: imagenNombre,
        );
      } catch (_) {
        fallidos.add(correos[i]);
      }
      onProgreso?.call(i + 1, correos.length);
    }
    return fallidos;
  }
}
