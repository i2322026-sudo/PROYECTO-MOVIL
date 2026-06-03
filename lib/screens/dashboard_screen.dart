import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil/screens/BajoStock_Screen.dart';
import 'package:movil/screens/GestionPedido_Screen.dart';
import 'package:movil/screens/MiPerfil_Screen.dart';
import 'package:movil/screens/NuevoProducto.dart';
import 'package:movil/screens/ProntoVencer_Screeen.dart';
import 'package:movil/screens/NuevoColaborador_screen.dart';
import 'package:movil/screens/ScanearProductos_Screen.dart';
import '../services/producto_service.dart';
import 'grafico_ventas.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProductoService _service = ProductoService();

  int    _countBajoStock  = 0;
  int    _countProxVencer = 0;
  bool   _cargandoConteos = true;
  String _nombre          = '';
  String _rol             = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? 'Usuario';
      _rol    = prefs.getString('rol')    ?? '';
    });

    try {
      final bajo   = await _service.getBajoStock();
      final vencer = await _service.getProximosVencer();
      if (!mounted) return;
      setState(() {
        _countBajoStock  = bajo.length;
        _countProxVencer = vencer.length;
        _cargandoConteos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoConteos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ALEVET - Panel',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: const Color(0xFF1B9B5E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Saludo ──────────────────────────────────
              Text(
                'Hola, $_nombre 👋',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alertas de Inventario',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366)),
              ),
              const SizedBox(height: 20),

              // ── Tarjetas de alerta ───────────────────────
              Row(
                children: [
                  _buildAlertCard(
                    titulo:  'Bajo Stock',
                    conteo:  _countBajoStock,
                    color:   const Color(0xFFF7A2A2),
                    destino: const BajoStockScreen(),
                  ),
                  const SizedBox(width: 12),
                  _buildAlertCard(
                    titulo:  'Pronto a Vencer',
                    conteo:  _countProxVencer,
                    color:   const Color(0xFFC5E5D4),
                    destino: const ProntoVencer_Screen(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Gráfico ──────────────────────────────────
              const GraficoVentas(),
              const SizedBox(height: 24),

              const Divider(thickness: 1, color: Colors.black12),
              const SizedBox(height: 10),

              const Text(
                'Operaciones Rápidas',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── Acciones rápidas ─────────────────────────
              _buildTile(
                icono:   Icons.add_box,
                titulo:  'Agregar Producto',
                sub:     'Registrar nuevo ítem en inventario',
                destino: const NuevoProducto(),
              ),
              _buildTile(
                icono:   Icons.qr_code_scanner,
                titulo:  'Escanear Producto',
                sub:     'Escanear código de barras',
                destino: const ScanearProductoScreen(),
              ),
              _buildTile(
                icono:   Icons.receipt_long,
                titulo:  'Gestión de Pedidos',
                sub:     'Ver pedidos de la tienda web',
                destino: const GestionPedidoScreen(),
              ),

              // Solo visible para administradores
              if (_rol == 'COLABORADOR' || _rol == 'ADMINISTRADOR')
                _buildTile(
                  icono:   Icons.person_add,
                  titulo:  'Nuevo Colaborador',
                  sub:     'Registrar nuevo miembro del equipo',
                  destino: const NuevoColaboradorScreen(),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:     const Color(0xFF1B9B5E),
        selectedItemColor:   Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const MiPerfilScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Mi cuenta'),
        ],
      ),
    );
  }

  // ── Tarjeta de alerta ───────────────────────────────────
  Widget _buildAlertCard({
    required String  titulo,
    required int     conteo,
    required Color   color,
    required Widget  destino,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => destino)),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _cargandoConteos
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                    : Text(
                        '$conteo ítems',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tile de acción rápida ───────────────────────────────
  Widget _buildTile({
    required IconData icono,
    required String   titulo,
    required String   sub,
    required Widget   destino,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: isPrimary ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPrimary
              ? const Color(0xFF1B9B5E)
              : const Color(0xFF1B9B5E).withOpacity(0.1),
          child: Icon(icono,
              color: isPrimary
                  ? Colors.white
                  : const Color(0xFF1B9B5E)),
        ),
        title: Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: Icon(
          Icons.chevron_right,
          color: isPrimary
              ? const Color(0xFF1B9B5E)
              : Colors.black54,
          size: 28,
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => destino)),
      ),
    );
  }
}