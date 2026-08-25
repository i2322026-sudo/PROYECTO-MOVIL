import 'package:dio/dio.dart';
import '../models/categoria_model.dart';
import '../models/subcategoria_model.dart';
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

  /// GET /api/categorias/:id/subcategorias — pública, en cascada
  /// según la categoría elegida (igual que cargarSubcategorias() en
  /// dashboard.js). Lista vacía si la categoría no tiene subcategorías
  /// registradas (es un caso normal, no un error).
  Future<List<Subcategoria>> getSubcategorias(int idCategoria) async {
    try {
      final res = await dio.get('${ApiConfig.categorias}/$idCategoria/subcategorias');
      return (res.data as List)
          .map((e) => Subcategoria.fromJson(e as Map<String, dynamic>))
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

  // ── Subcategorías (administración) — mismo CRUD que el modal
  //    "Subcategorías" de dashboard.js ────────────────────────

  /// GET /api/categorias/:id/subcategorias/admin — incluye INACTIVAS
  /// (a diferencia de getSubcategorias(), que es la pública en cascada
  /// del formulario de producto y solo trae ACTIVAS).
  Future<List<Subcategoria>> getSubcategoriasAdmin(int idCategoria) async {
    try {
      final res = await dio
          .get('${ApiConfig.categorias}/$idCategoria/subcategorias/admin');
      return (res.data as List)
          .map((e) => Subcategoria.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> crearSubcategoria({
    required int idCategoria,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      await dio.post('${ApiConfig.categorias}/subcategorias', data: {
        'id_categoria': idCategoria,
        'nombre': nombre,
        'descripcion': descripcion,
      });
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> actualizarSubcategoria({
    required int id,
    required String nombre,
    String? descripcion,
    String estado = 'ACTIVO',
  }) async {
    try {
      await dio.put('${ApiConfig.categorias}/subcategorias/$id', data: {
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': estado,
      });
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }

  Future<void> eliminarSubcategoria(int id) async {
    try {
      await dio.delete('${ApiConfig.categorias}/subcategorias/$id');
    } on DioException catch (e) {
      throw errorDe(e);
    }
  }
}
