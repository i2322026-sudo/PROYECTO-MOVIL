// ─────────────────────────────────────────────────────────────
//  ApiConfig — verificado contra el backend REAL desplegado
//  (ALIVETagroveterinaria, no el SISTEMA-WEB viejo). Todas estas
//  rutas se confirmaron leyendo src/app.js y cada archivo de
//  src/routes/*.js del proyecto actualizado.
// ─────────────────────────────────────────────────────────────
class ApiConfig {
  static const String base =
      'https://agropecuariorebeca.onrender.com/api';

  // Mismo dominio que 'base' pero SIN el sufijo '/api' — se usa para
  // armar la URL de las imágenes servidas como archivos estáticos
  // (Express: app.use(express.static(PUBLIC_DIR))), que NO viven bajo
  // /api sino directo en /img/productos/... (igual que dashboard.js).
  static const String host = 'https://agropecuariorebeca.onrender.com';

  // Verificado contra dashboard.js (líneas 264-265 y 619) y
  // producto.js (RUTA_IMG = '/img/productos/'):
  //  - Si `imagen` ya es una URL completa (empieza con "http"), tal
  //    cual como llega — pasa con imágenes externas o subidas a MinIO.
  //  - Si es solo el nombre del archivo (ej. "croquetas.webp"), se arma
  //    contra /img/productos/ del MISMO backend (carpeta pública, no /api).
  //  - Si no hay imagen, null — quien lo use debe mostrar un ícono de
  //    reemplazo (igual que la web cae a /img/logo.jpeg).
  // Verificado contra minio.service.js: todas las imágenes reales de
  // producto se suben a un bucket público de Cloudflare R2
  // (pub-xxxxx.r2.dev). Ese bucket NO manda cabeceras CORS, así que
  // Flutter WEB (que decodifica la imagen por fetch, a diferencia de
  // un <img> normal de HTML) la rechaza en silencio — por eso en
  // Chrome no cargaban aunque la URL fuera 100% válida y la propia
  // web (con <img> normal) sí las mostrara. En Android/iOS nativos
  // esto no pasa (ahí no aplica CORS), pero como esta app también se
  // prueba en Chrome, se resuelve igual para los dos casos pasando
  // TODA imagen de R2 por el proxy propio del backend (que sí tiene
  // CORS abierto, ver imagen.routes.js -> /proxy/imagen).
  static const String _r2Base =
      'https://pub-43de94155d9a4dc7af7ced67344c5419.r2.dev';

  static String? urlImagen(String? imagen) {
    if (imagen == null || imagen.trim().isEmpty) return null;
    if (imagen.startsWith(_r2Base)) {
      return '$base/imagenes/proxy/imagen?url=${Uri.encodeQueryComponent(imagen)}';
    }
    if (imagen.startsWith('http://') || imagen.startsWith('https://')) {
      return imagen;
    }
    return '$host/img/productos/$imagen';
  }

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
  static String buscarPedidoPorCodigo(String codigo) =>
      '/pedidos/buscar-codigo/$codigo';
  static String evidenciaCancelacion(int id) =>
      '/pedidos/$id/evidencia-cancelacion';

  // CLIENTES
  static const String clientes = '/clientes';

  // COLABORADORES — src/routes/colaborador.routes.js (ya existe de verdad)
  static const String colaboradores = '/colaboradores';
  static const String cargos = '/colaboradores/cargos';
  // Reemplaza al viejo endpoint de reset directo — ahora es un flujo de
  // 2 pasos con OTP (igual que "Mi perfil"): pide contraseña actual +
  // nueva, manda el código al correo, y recién con el código confirma.
  static String solicitarResetPasswordColaborador(int id) =>
      '/colaboradores/$id/solicitar-reset-password';
  static String confirmarResetPasswordColaborador(int id) =>
      '/colaboradores/$id/confirmar-reset-password';

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
  static const String topClientesBase = '/dashboard/top-clientes';

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
