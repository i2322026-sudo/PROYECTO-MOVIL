import 'package:dio/dio.dart';
import 'base_service.dart';

// ─────────────────────────────────────────────────────────────
//  UploadService — POST /api/upload/imagen-producto (real,
//  definida directo en src/app.js). Sube el archivo con multer +
//  MinIO/R2 y devuelve { url, mensaje }. Solo acepta JPEG/PNG/WEBP
//  hasta 5MB (mismo límite que valida tu backend).
// ─────────────────────────────────────────────────────────────
class UploadService extends BaseService {
  Future<String> subirImagenProducto({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'imagen': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
      });
      final res = await dio.post('/upload/imagen-producto', data: formData);
      return res.data['url'] as String;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// POST /api/upload/ficha-tecnica — sube el PDF y devuelve la URL.
  Future<String> subirFichaTecnica({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'archivo': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
      });
      final res = await dio.post('/upload/ficha-tecnica', data: formData);
      return res.data['url'] as String;
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
