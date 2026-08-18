import 'package:dio/dio.dart';
import 'dio_client.dart';

abstract class BaseService {
  final Dio dio = DioClient.dio;

  Exception errorDe(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado. Intenta de nuevo.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Sin conexión. Verifica que el servidor esté corriendo.');
    }
    final data = e.response?.data;
    final mensaje = data is Map ? data['mensaje'] : null;
    return Exception(mensaje ?? 'Error ${e.response?.statusCode ?? "desconocido"}');
  }
}
