import 'package:dio/dio.dart';
import '../models/animal_model.dart';
import 'api_config.dart';
import 'base_service.dart';

class AnimalService extends BaseService {
  Future<List<TipoAnimal>> getAnimales() async {
    try {
      final res = await dio.get(ApiConfig.animales);
      return (res.data as List)
          .map((e) => TipoAnimal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> crear(TipoAnimal animal) async {
    try {
      await dio.post(ApiConfig.animales, data: animal.toJson());
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> actualizar(int id, TipoAnimal animal) async {
    try {
      await dio.put('${ApiConfig.animales}/$id', data: animal.toJson());
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  /// El backend rechaza el borrado si el tipo de animal tiene
  /// productos activos asociados.
  Future<void> eliminar(int id) async {
    try {
      await dio.delete('${ApiConfig.animales}/$id');
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
