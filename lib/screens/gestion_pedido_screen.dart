import 'package:flutter/material.dart';
import 'package:movil/models/pedido_model.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/screens/detalle_venta_screen.dart';

// ─────────────────────────────────────────────────────────────
//  GestionPedidoScreen — lista de pedidos (GET /api/pedidos) con
//  cambio de estado (PUT /api/pedidos/:id/estado).
//
//  Simplificada a pedido del usuario: sin filtros de rango de
//  fecha (Hoy/Semana/Quincena/Mes) ni exportar — solo "Todos".
//  Al tocar una tarjeta, abre el mismo detalle que usa "Gestión
//  de Ventas" (funciona para cualquier estado, incluido
//  PENDIENTE/CANCELADO, porque el backend no filtra por estado
//  ahí — ver venta.model.js -> obtenerComprobante).
// ─────────────────────────────────────────────────────────────
class GestionPedidoScreen extends StatefulWidget {
  const GestionPedidoScreen({super.key});

  @override
  State<GestionPedidoScreen> createState() => _GestionPedidoScreenState();
}

class _GestionPedidoScreenState extends State<GestionPedidoScreen> {
  final _service = PedidoService();
  List<Pedido> _pedidos = [];
  bool _cargando = true;
  String? _error;

  static const _estados = [
    'PENDIENTE',
    'PAGADO',
    'ENVIADO',
    'ENTREGADO',
    'CANCELADO'
  ];

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
      final pedidos = await _service.getPedidos();
      setState(() {
        _pedidos = pedidos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _cambiarEstado(Pedido p, String nuevoEstado) async {
    try {
      await _service.actualizarEstado(p.idPedido, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${p.codigoPedido} -> $nuevoEstado')),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _pedidos.isEmpty,
        mensajeVacio: 'No hay pedidos registrados',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _pedidos.length,
            itemBuilder: (ctx, i) {
              final p = _pedidos[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetalleVentaScreen(idPedido: p.idPedido),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pedido #${p.codigoPedido}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
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
                        const SizedBox(height: 6),
                        Text(p.cliente ?? 'Cliente sin nombre'),
                        if (p.direccion != null) Text(p.direccion!),
                        const SizedBox(height: 6),
                        Text(
                          'S/. ${p.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppColors.verde,
                              fontWeight: FontWeight.bold),
                        ),
                        if (p.fechaComoDateTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${p.fechaComoDateTime!.day.toString().padLeft(2, '0')}/'
                              '${p.fechaComoDateTime!.month.toString().padLeft(2, '0')}/'
                              '${p.fechaComoDateTime!.year}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue:
                              _estados.contains(p.estado) ? p.estado : null,
                          decoration: const InputDecoration(
                            labelText: 'Cambiar estado',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: _estados
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (nuevo) {
                            if (nuevo != null) _cambiarEstado(p, nuevo);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
