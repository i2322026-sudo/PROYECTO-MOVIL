import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'MiPerfil_Screen.dart';
import '../models/producto_model.dart';
import '../services/producto_service.dart';

// ─────────────────────────────────────────────────────────────
//  BajoStockScreen — lista productos con stock <= stock_minimo
//  Datos reales desde: GET /api/productos/bajostock
// ─────────────────────────────────────────────────────────────
class BajoStockScreen extends StatefulWidget {
  const BajoStockScreen({super.key});

  @override
  State<BajoStockScreen> createState() => _BajoStockScreenState();
}

class _BajoStockScreenState extends State<BajoStockScreen> {
  final ProductoService      _service    = ProductoService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Producto> _todos     = [];
  List<Producto> _filtrados = [];
  bool   _cargando = true;
  String _error    = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final data = await _service.getBajoStock();
      setState(() {
        _todos     = data;
        _filtrados = data;
        _cargando  = false;
      });
    } catch (e) {
      setState(() {
        _error    = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  void _buscar(String q) {
    setState(() {
      _filtrados = _todos
          .where((p) => p.nombre.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Color _colorStock(Producto p) {
    final alerta = p.stockAlerta ?? 3;
    return p.stockActual <= alerta ? Colors.red : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Agroveterinario ALEVET',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Productos con bajo stock',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                // Badge con conteo real
                if (!_cargando && _error.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '${_filtrados.length} ítems',
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged:  _buscar,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search,
                      size: 20, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  hintText: 'Buscar producto...',
                  hintStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),

          const Divider(thickness: 1),

          // Cabecera tabla
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Row(
              children: const [
                Expanded(
                    flex: 5,
                    child: Text('PRODUCTO',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.black54))),
                SizedBox(
                    width: 70,
                    child: Center(
                      child: Text('STOCK',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.black54)),
                    )),
                SizedBox(
                    width: 70,
                    child: Center(
                      child: Text('MÍNIMO',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.black54)),
                    )),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1),

          // Lista
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B9B5E)))
                : _error.isNotEmpty
                    ? _buildError()
                    : _filtrados.isEmpty
                        ? _buildVacio()
                        : ListView.separated(
                            itemCount: _filtrados.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) =>
                                _buildItem(_filtrados[i]),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildItem(Producto p) {
    final color = _colorStock(p);
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 16),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: Colors.grey, size: 26),
          ),
          const SizedBox(width: 12),
          // Nombre + categoría
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (p.categoria != null)
                  Text(p.categoria!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          // Stock actual
          SizedBox(
            width: 70,
            child: Center(
              child: Text('${p.stockActual}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
          ),
          // Stock mínimo
          SizedBox(
            width: 70,
            child: Center(
              child: Text('${p.stockMinimo}',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B9B5E),
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
          SizedBox(height: 12),
          Text('¡Todo en orden!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          SizedBox(height: 6),
          Text('No hay productos con bajo stock',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  BottomNavigationBar _bottomNav() {
    return BottomNavigationBar(
      backgroundColor:     const Color(0xFF1B9B5E),
      selectedItemColor:   Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 0,
      onTap: (i) {
        if (i == 0) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const MiPerfilScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home),   label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi cuenta'),
      ],
    );
  }
}
