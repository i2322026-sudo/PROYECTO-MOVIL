import 'package:flutter/material.dart';
import 'package:movil/models/pedido_model.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/services/dashboard_service.dart';
import 'package:movil/services/usuario_service.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/widgets/tarjeta_resumen.dart';
import 'package:movil/screens/productos_screen.dart';
import 'package:movil/screens/gestion_pedido_screen.dart';
import 'package:movil/screens/bajo_stock_screen.dart';
import 'package:movil/screens/pronto_vencer_screen.dart';
import 'package:movil/screens/grafico_ventas_screen.dart';
import 'package:movil/screens/gestion_ventas_screen.dart';
import 'package:movil/screens/escanear_producto_screen.dart';
import 'package:movil/screens/promociones_screen.dart';
import 'package:movil/screens/nuevo_producto_screen.dart';
import 'package:movil/screens/mi_perfil_screen.dart';
import 'package:movil/screens/categorias_screen.dart';
import 'package:movil/screens/animales_screen.dart';
import 'package:movil/screens/clientes_screen.dart';
import 'package:movil/screens/colaboradores_screen.dart';
import 'package:movil/screens/login_screen.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  DashboardScreen — pantalla principal tras el login.
//  Trae el resumen real de GET /api/dashboard y da acceso
//  a las demás secciones (mismo mapa que el dashboard web).
// ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();
  final _usuarioService = UsuarioService();
  final _pedidoService = PedidoService();
  final _productoService = ProductoService();

  Map<String, dynamic>? _resumen;
  List<Pedido> _recientes = [];
  int _totalPedidos = 0;
  int _porVencer = 0;
  bool _esAdministrador = false;
  bool _puedeGestionarInventario = false; // Administrador o Gerente
  bool _cargando = true;
  String? _error;
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final nombre = await _usuarioService.getNombre();
      final cargo = await _usuarioService.getCargo();
      final puedeGestionarInventario =
          cargo == 'Administrador' || cargo == 'Gerente';

      final resumen = await _dashboardService.getResumen();
      final pedidos = await _pedidoService.getPedidos();
      // "Por vencer" es exclusivo de Administrador/Gerente en el
      // backend (inventario.routes.js) — si lo pedimos igual para
      // Vendedor/Asistente de ventas, el 403 corta TODO el resumen
      // (Pedidos, Productos activos, Stock bajo también), aunque
      // esas otras sí estén permitidas. Por eso se pide solo si
      // corresponde, en vez de siempre.
      final porVencer = puedeGestionarInventario
          ? await _productoService.getProximosVencer()
          : <Producto>[];

      setState(() {
        _nombre = nombre;
        _esAdministrador = cargo == 'Administrador';
        _puedeGestionarInventario = puedeGestionarInventario;
        _resumen = resumen;
        // El backend (/api/dashboard) solo cuenta pedidos en estado
        // PENDIENTE, no el total real. Como ya traemos la lista
        // completa de pedidos, usamos su longitud como el total.
        _totalPedidos = pedidos.length;
        _porVencer = porVencer.length;
        _recientes = pedidos.take(5).toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    await _usuarioService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoVerdeSuave,
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MiPerfilScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $_nombre 👋',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    TarjetaResumen(
                      titulo: 'Pedidos',
                      valor: '$_totalPedidos',
                      icono: Icons.receipt_long_outlined,
                      color: AppColors.verde,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GestionPedidoScreen()),
                      ),
                    ),
                    // "Por vencer", "Productos activos" y "Stock bajo"
                    // llevan a pantallas de gestión de inventario
                    // (editar/eliminar productos, ajustar stock) —
                    // igual que "Nuevo producto"/"Gráficos": exclusivo
                    // de Administrador y Gerente. El backend también
                    // lo bloquea (inventario.routes.js), esto es solo
                    // para no mostrar una tarjeta que va a fallar.
                    if (_puedeGestionarInventario) ...[
                      TarjetaResumen(
                        titulo: 'Por vencer',
                        valor: '$_porVencer',
                        icono: Icons.hourglass_bottom,
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProntoVencerScreen()),
                        ),
                      ),
                      TarjetaResumen(
                        titulo: 'Productos activos',
                        valor: '${_resumen?['productos'] ?? 0}',
                        icono: Icons.inventory_2_outlined,
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProductosScreen()),
                        ),
                      ),
                      TarjetaResumen(
                        titulo: 'Stock bajo',
                        valor: '${_resumen?['stockBajo'] ?? 0}',
                        icono: Icons.warning_amber_outlined,
                        color: Colors.red,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BajoStockScreen()),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 24),
              const Text('Pedidos recientes',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (!_cargando && _error == null)
                _recientes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No hay pedidos todavía',
                            style: TextStyle(color: Colors.grey.shade600)),
                      )
                    : Column(
                        children: _recientes
                            .map((p) => _filaPedido(context, p))
                            .toList(),
                      ),
              const SizedBox(height: 24),
              const Text('Accesos rápidos',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  _accesoRapido(
                    context,
                    icono: Icons.barcode_reader,
                    texto: 'Escanear',
                    destino: const EscanearProductoScreen(),
                  ),
                  _accesoRapido(
                    context,
                    icono: Icons.receipt_long_outlined,
                    texto: 'Ventas',
                    destino: const GestionVentasScreen(),
                  ),
                  _accesoRapido(
                    context,
                    icono: Icons.people_alt_outlined,
                    texto: 'Clientes',
                    destino: const ClientesScreen(),
                  ),
                  // Nuevo producto / Gráficos / Categorías / Animales:
                  // gestión de catálogo e información de negocio —
                  // Administrador y Gerente, no Vendedor ni Asistente
                  // de ventas (mismo criterio que el resumen de arriba).
                  if (_puedeGestionarInventario) ...[
                    _accesoRapido(
                      context,
                      icono: Icons.add_box_outlined,
                      texto: 'Nuevo producto',
                      destino: const NuevoProductoScreen(),
                    ),
                    _accesoRapido(
                      context,
                      icono: Icons.show_chart,
                      texto: 'Gráficos',
                      destino: const GraficoVentasScreen(),
                    ),
                    _accesoRapido(
                      context,
                      icono: Icons.category_outlined,
                      texto: 'Categorías',
                      destino: const CategoriasScreen(),
                    ),
                    _accesoRapido(
                      context,
                      icono: Icons.pets,
                      texto: 'Animales',
                      destino: const AnimalesScreen(),
                    ),
                  ],
                  // Colaboradores y Promociones son exclusivos del
                  // Administrador — el resto de los cargos (Gerente,
                  // Vendedor, Asistente de ventas) no las ve. El
                  // backend también las bloquea (verificarCargo), esto
                  // es solo para que ni aparezcan en pantalla.
                  if (_esAdministrador) ...[
                    _accesoRapido(
                      context,
                      icono: Icons.badge_outlined,
                      texto: 'Colaboradores',
                      destino: const ColaboradoresScreen(),
                    ),
                    _accesoRapido(
                      context,
                      icono: Icons.campaign_outlined,
                      texto: 'Promociones',
                      destino: const PromocionesScreen(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaPedido(BuildContext context, Pedido p) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GestionPedidoScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${p.codigoPedido} — ${p.cliente ?? "Cliente"}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('S/. ${p.total.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.verde)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _colorEstado(p.estado).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.estado ?? '-',
                style: TextStyle(
                    color: _colorEstado(p.estado),
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'PAGADO':
        return Colors.blue;
      case 'ENVIADO':
        return Colors.indigo;
      case 'ENTREGADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  Widget _accesoRapido(BuildContext context,
      {required IconData icono,
      required String texto,
      required Widget destino}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: AppColors.verde),
            const SizedBox(height: 6),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
