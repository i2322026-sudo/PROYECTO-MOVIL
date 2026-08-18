// ─────────────────────────────────────────────────────────────
//  ApiConfig — verificado contra el backend REAL desplegado
//  (ALIVETagroveterinaria, no el SISTEMA-WEB viejo). Todas estas
//  rutas se confirmaron leyendo src/app.js y cada archivo de
//  src/routes/*.js del proyecto actualizado.
// ─────────────────────────────────────────────────────────────
class ApiConfig {
  static const String base =
      'https://alivetagroveterinaria-web.onrender.com/api';

  // AUTH — src/routes/auth.routes.js
  static const String login = '/auth/login';
  static const String loginVerificarOtp = '/auth/login-verificar-otp';
  static const String registro = '/auth/registro';
  static const String perfil = '/auth/perfil';
  static const String actualizarPerfil = '/auth/actualizar-perfil';
  static const String cambiarPassword = '/auth/cambiar-password';
  static const String cambiarPasswordVerificarOtp = '/auth/cambiar-password-verificar-otp';
  static const String fcmToken = '/auth/fcm-token';

  // PRODUCTOS — src/routes/producto.routes.js
  static const String productos = '/productos';
  static String cambiarEstadoProducto(int id) => '/productos/$id/estado';

  // INVENTARIO — src/routes/inventario.routes.js (todo requiere COLABORADOR)
  static const String bajoStock = '/inventario/bajo-stock';
  static const String porVencer = '/inventario/por-vencer';
  static String buscarPorCodigo(String codigo) =>
      '/inventario/buscar-codigo/$codigo';
  static String actualizarStock(int id) => '/inventario/actualizar-stock/$id';

  // CATÁLOGOS
  static const String categorias = '/categorias';
  static const String animales = '/animales';

  // PEDIDOS — src/routes/pedido.routes.js (cliente) y
  // src/routes/dashboard.routes.js (panel admin)
  static const String pedidosCrear = '/pedidos/crear';
  static const String misPedidos = '/pedidos/mispedidos';
  static const String pedidosAdmin = '/pedidos';
  static String actualizarEstadoPedido(int id) => '/pedidos/$id/estado';
  static String detallePedidoAdmin(int id) => '/pedidos/$id';

  // CLIENTES
  static const String clientes = '/clientes';

  // COLABORADORES — src/routes/colaborador.routes.js (ya existe de verdad)
  static const String colaboradores = '/colaboradores';
  static const String cargos = '/colaboradores/cargos';
  static String resetPasswordColaborador(int id) =>
      '/colaboradores/$id/reset-password';

  // UBIGEO
  static const String departamentos = '/ubigeo/departamentos';
  static String provincias(int idDepartamento) =>
      '/ubigeo/provincias/$idDepartamento';
  static String distritos(int idProvincia) =>
      '/ubigeo/distritos/$idProvincia';

  // DASHBOARD — src/routes/dashboard.routes.js
  static const String dashboard = '/dashboard';
  static const String ventasPorMes = '/dashboard/ventas-mes';
  static const String productosMasVendidos = '/dashboard/productos-vendidos';
  static const String stockProductos = '/dashboard/stock';
  static String topClientes({int limite = 10}) =>
      '/dashboard/top-clientes?limite=$limite';

  // NOTIFICACIONES — registradas directo en src/app.js
  static const String notificaciones = '/notificaciones';
  static String marcarNotificacionLeida(int id) => '/notificaciones/$id/leer';

  // GESTIÓN DE VENTAS (comprobantes) — src/routes/venta.routes.js
  static const String ventas = '/ventas';
  static const String ventasExportarExcel = '/ventas/exportar-excel';
  static String detalleVenta(int idPedido) => '/ventas/$idPedido';

  // PROMOCIONES — registrada en src/rutas/auth.routes.js
  // (comparte controlador con auth, no tiene archivo de rutas propio)
  static const String enviarPromocion = '/auth/enviar-promocion';
}
