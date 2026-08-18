import 'package:dio/dio.dart';
import '../models/categoria_model.dart';
import 'api_config.dart';
import 'base_service.dart';

class CategoriaService extends BaseService {
  Future<List<Categoria>> getCategorias() async {
    try {
      final res = await dio.get(ApiConfig.categorias);
      return (res.data as List)
          .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> crear(Categoria categoria) async {
    try {
      await dio.post(ApiConfig.categorias, data: categoria.toJson());
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> actualizar(int id, Categoria categoria) async {
    try {
      await dio.put('${ApiConfig.categorias}/$id', data: categoria.toJson());
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// El backend rechaza el borrado si la categoría tiene productos
  /// activos asociados — el mensaje de error ya viene explicado.
  Future<void> eliminar(int id) async {
    try {
      await dio.delete('${ApiConfig.categorias}/$id');
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
