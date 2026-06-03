class ApiConfig {
  static const String base =
      'https://alivetagroveterinaria-web.onrender.com/api';

  // AUTH
  static const String login = '$base/auth/login';
  static const String registro = '$base/auth/registro';
  static const String perfil = '$base/auth/perfil';
  static const String fcmToken = '$base/auth/fcm-token';

  // PRODUCTOS
  static const String productos = '$base/productos';
  static const String bajoStock = '$base/inventario/bajo-stock';
  static const String porVencer = '$base/inventario/por-vencer';
  static const String buscarCodigo = '$base/inventario/buscar-codigo';
  static const String actualizarStock = '$base/inventario/actualizar-stock';
  static const String productosMasVendidos =
      '$base/dashboard/productos-vendidos';

  // PEDIDOS
  static const String pedidos = '$base/pedidos';
  static const String actualizarEstado = '$base/pedidos/:id/estado';

  // CATÁLOGOS
  static const String categorias = '$base/categorias';
  static const String animales = '$base/animales';
  static const String dashboard = '$base/dashboard';

  //COLABORADORES
  static const String colaboradores = '$base/colaboradores';
  static const String cargos = '$base/colaboradores/cargos';
}
