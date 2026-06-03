import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'MiPerfil_Screen.dart';
import '../models/pedido_model.dart';
import '../services/pedido_service.dart';

class GestionPedidoScreen extends StatefulWidget {
  const GestionPedidoScreen({super.key});
  @override
  State<GestionPedidoScreen> createState() => _GestionPedidoScreenState();
}

class _GestionPedidoScreenState extends State<GestionPedidoScreen> {
  final PedidoService _service = PedidoService();

  List<Pedido> _pedidos = [];
  bool   _cargando = true;
  String _error    = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final data = await _service.getPedidos();
      setState(() { _pedidos = data; _cargando = false; });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'ENTREGADO': return Colors.green;
      case 'EN_CAMINO': return Colors.blue;
      case 'CANCELADO': return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData _iconEstado(String? estado) {
    switch (estado) {
      case 'ENTREGADO': return Icons.done_all;
      case 'EN_CAMINO': return Icons.local_shipping_outlined;
      case 'CANCELADO': return Icons.cancel_outlined;
      default:          return Icons.hourglass_empty;
    }
  }

  String _formatFecha(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agroveterinario ALEVET',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: Color(0xFF1B9B5E)),
                const SizedBox(width: 8),
                const Text('Lista de pedidos',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (!_cargando && _error.isEmpty)
                  Text('${_pedidos.length} pedidos',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B9B5E)))
                : _error.isNotEmpty
                    ? _buildError()
                    : _pedidos.isEmpty
                        ? _buildVacio()
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            color: const Color(0xFF1B9B5E),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _pedidos.length,
                              itemBuilder: (_, i) =>
                                  _buildCard(_pedidos[i]),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildCard(Pedido p) {
    final color = _colorEstado(p.estado);
    return Card(
      margin:    const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalle(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Código + badge estado
              Row(
                children: [
                  Text('# ${p.codigoPedido}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1B9B5E))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconEstado(p.estado),
                            color: color, size: 14),
                        const SizedBox(width: 4),
                        Text(p.estado ?? 'PENDIENTE',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Cliente
              if (p.cliente != null)
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(p.cliente!,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              const SizedBox(height: 4),

              // Fecha + total + flecha
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(_formatFecha(p.fecha),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                  const Spacer(),
                  Text('S/ ${p.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9B5E))),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Abre el detalle del pedido
  void _abrirDetalle(Pedido p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoScreen(pedido: p),
      ),
    ).then((_) => _cargar()); // refresca al volver
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14)),
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
      ),
    );
  }

  Widget _buildVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('Sin pedidos aún',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          SizedBox(height: 6),
          Text('Los pedidos aparecerán aquí',
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
              MaterialPageRoute(
                  builder: (_) => const DashboardScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(
                  builder: (_) => const MiPerfilScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Mi cuenta'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DetallePedidoScreen — detalle completo + cambiar estado
// ─────────────────────────────────────────────────────────────
class DetallePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const DetallePedidoScreen({super.key, required this.pedido});
  @override
  State<DetallePedidoScreen> createState() =>
      _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  final PedidoService _service = PedidoService();

  Map<String, dynamic> _detalle = {};
  String _estadoActual = 'PENDIENTE';
  bool   _cargando     = true;
  bool   _guardando    = false;

  final List<String> _estados = [
    'PENDIENTE',
    'EN_CAMINO',
    'ENTREGADO',
    'CANCELADO',
  ];

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.pedido.estado ?? 'PENDIENTE';
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data =
          await _service.getDetalle(widget.pedido.idPedido);
      setState(() {
        _detalle  = data;
        _estadoActual = data['estado'] ?? _estadoActual;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _guardando = true);
    try {
      await _service.actualizarEstado(
          widget.pedido.idPedido, nuevoEstado);
      setState(() {
        _estadoActual = nuevoEstado;
        _guardando    = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a $nuevoEstado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'ENTREGADO': return Colors.green;
      case 'EN_CAMINO': return Colors.blue;
      case 'CANCELADO': return Colors.red;
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalles =
        (_detalle['detalles'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de pedido',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1B9B5E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info general
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _fila('Pedido',
                              '# ${widget.pedido.codigoPedido}'),
                          _fila('Cliente',
                              _detalle['cliente_nombre'] ??
                                  widget.pedido.cliente ??
                                  '—'),
                          _fila('Fecha',
                              _detalle['fecha_pedido'] != null
                                  ? _detalle['fecha_pedido']
                                      .toString()
                                      .substring(0, 10)
                                  : '—'),
                          _fila('Total',
                              'S/ ${widget.pedido.total.toStringAsFixed(2)}'),
                          _fila('Dirección',
                              _detalle['direccion_entrega'] ?? '—'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Productos del pedido
                  if (detalles.isNotEmpty) ...[
                    const Text('Productos',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: detalles.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final d = detalles[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor:
                                  Color(0xFF1B9B5E),
                              child: Icon(Icons.inventory_2,
                                  color: Colors.white,
                                  size: 18),
                            ),
                            title: Text(
                                d['producto_nombre'] ?? '—'),
                            subtitle: Text(
                                'x${d['cantidad']}  •  S/ ${d['precio_unitario']}'),
                            trailing: Text(
                              'S/ ${d['subtotal']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B9B5E)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Cambiar estado
                  const Text('Cambiar estado',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _estados.map((e) {
                      final seleccionado = _estadoActual == e;
                      final color = _colorEstado(e);
                      return GestureDetector(
                        onTap: _guardando
                            ? null
                            : () => _cambiarEstado(e),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? color
                                : color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: color,
                                width:
                                    seleccionado ? 0 : 1),
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              color: seleccionado
                                  ? Colors.white
                                  : color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_guardando) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1B9B5E)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}