class ApiConfig {
  // ⚠️ Corre "ipconfig" en CMD y pon tu IPv4 aquí
  // Ejemplo: static const String _ip = '192.168.1.105';
  static const String _ip = 'TU_IP_AQUI';

  // Tu backend Node.js corre en el puerto 3000
  static const String baseUrl = 'http://$_ip:3000/api';

  // ── PRODUCTOS ──────────────────────────────────────────
  // GET  /api/productos         → todos los productos activos
  // GET  /api/productos/bajostock → productos con bajo stock
  // GET  /api/productos/porvencer → productos próximos a vencer
  // POST /api/productos         → crear nuevo producto
  static const String productos = '$baseUrl/productos';
  static const String productosBajoStock = '$baseUrl/productos/bajostock';
  static const String productosProximosVencer = '$baseUrl/productos/porvencer';

  // ── PEDIDOS ────────────────────────────────────────────
  // GET  /api/pedidos           → todos los pedidos
  // POST /api/pedidos           → crear nuevo pedido
  static const String pedidos = '$baseUrl/pedidos';

  // ── AUTH ───────────────────────────────────────────────
  // POST /api/auth/login        → login con correo y password
  static const String login = '$baseUrl/auth/login';
}
