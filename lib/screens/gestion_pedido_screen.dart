import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movil/models/pedido_model.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/services/reporte_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  GestionPedidoScreen — lista de pedidos (GET /api/pedidos) con
//  cambio de estado (PUT /api/pedidos/:id/estado).
//
//  FILTRO POR FECHA: tu backend (reporte.model.js) no soporta
//  filtrar por rango de fechas en las exportaciones — siempre
//  trae el historial completo. Por eso el filtro Día/Semana/
//  Quincena/Mes se aplica AQUÍ, en la app, sobre los pedidos que
//  ya tenemos cargados, y "Exportar Excel" genera un CSV (se abre
//  en Excel/WPS normal) con SOLO lo que está filtrado en pantalla
//  — así el archivo sí refleja el rango elegido.
//  "Exportar PDF" sigue yendo a tu backend (con estilos reales),
//  pero ese sí trae el historial completo siempre, porque no hay
//  forma de filtrarlo sin cambiar el backend.
// ─────────────────────────────────────────────────────────────
class GestionPedidoScreen extends StatefulWidget {
  const GestionPedidoScreen({super.key});

  @override
  State<GestionPedidoScreen> createState() => _GestionPedidoScreenState();
}

enum _Rango { todos, dia, semana, quincena, mes }

class _GestionPedidoScreenState extends State<GestionPedidoScreen> {
  final _service = PedidoService();
  final _reporteService = ReporteService();
  List<Pedido> _pedidos = [];
  bool _cargando = true;
  bool _exportando = false;
  String? _error;
  _Rango _rango = _Rango.todos;

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

  /// Pedidos que caen dentro del rango de fecha elegido.
  List<Pedido> get _pedidosFiltrados {
    if (_rango == _Rango.todos) return _pedidos;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    late DateTime desde;
    switch (_rango) {
      case _Rango.dia:
        desde = hoy;
        break;
      case _Rango.semana:
        desde = hoy.subtract(const Duration(days: 7));
        break;
      case _Rango.quincena:
        desde = hoy.subtract(const Duration(days: 15));
        break;
      case _Rango.mes:
        desde = hoy.subtract(const Duration(days: 30));
        break;
      case _Rango.todos:
        desde = DateTime(2000);
    }
    return _pedidos.where((p) {
      final f = p.fechaComoDateTime;
      return f != null && !f.isBefore(desde);
    }).toList();
  }

  String get _etiquetaRango {
    switch (_rango) {
      case _Rango.dia:
        return 'Hoy';
      case _Rango.semana:
        return 'Últimos 7 días';
      case _Rango.quincena:
        return 'Últimos 15 días';
      case _Rango.mes:
        return 'Últimos 30 días';
      case _Rango.todos:
        return 'Todos';
    }
  }

  Future<void> _exportarExcelFiltrado() async {
    setState(() => _exportando = true);
    try {
      final filtrados = _pedidosFiltrados;
      final buffer = StringBuffer();
      buffer.writeln('Pedido,Cliente,Dirección,Total,Estado,Fecha');
      for (final p in filtrados) {
        final fecha = p.fecha?.split('T').first ?? '';
        String csvSafe(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
        buffer.writeln(
          '${p.codigoPedido},${csvSafe(p.cliente)},${csvSafe(p.direccion)},'
          '${p.total.toStringAsFixed(2)},${csvSafe(p.estado)},$fecha',
        );
      }
      final bytes = utf8.encode(buffer.toString());
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'pedidos_${_rango.name}.csv',
          mimeType: 'text/csv',
        ),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el archivo: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarPdfCompleto() async {
    setState(() => _exportando = true);
    try {
      final bytes = await _reporteService.exportar('pedidos', 'pdf');
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'pedidos.pdf',
          mimeType: 'application/pdf',
        ),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _cambiarEstado(Pedido p, String nuevoEstado) async {
    try {
      await _service.actualizarEstado(p.idPedido, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${p.codigoPedido} → $nuevoEstado')),
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
    final pedidosFiltrados = _pedidosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: [
          _exportando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.download_outlined, color: Colors.white),
                  tooltip: 'Exportar',
                  onSelected: (v) {
                    if (v == 'excel') _exportarExcelFiltrado();
                    if (v == 'pdf') _exportarPdfCompleto();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'excel',
                      child: Text('Exportar Excel ($_etiquetaRango)'),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Text('Exportar PDF (historial completo)'),
                    ),
                  ],
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipRango('Todos', _Rango.todos),
                  const SizedBox(width: 6),
                  _chipRango('Hoy', _Rango.dia),
                  const SizedBox(width: 6),
                  _chipRango('Semana', _Rango.semana),
                  const SizedBox(width: 6),
                  _chipRango('Quincena', _Rango.quincena),
                  const SizedBox(width: 6),
                  _chipRango('Mes', _Rango.mes),
                ],
              ),
            ),
          ),
          Expanded(
            child: EstadoLista(
              cargando: _cargando,
              error: _error,
              vacio: pedidosFiltrados.isEmpty,
              mensajeVacio: _rango == _Rango.todos
                  ? 'No hay pedidos registrados'
                  : 'No hay pedidos en este rango de fechas',
              onReintentar: _cargar,
              builder: () => RefreshIndicator(
                onRefresh: _cargar,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidosFiltrados.length,
                  itemBuilder: (ctx, i) {
                    final p = pedidosFiltrados[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                                    color: _colorEstado(p.estado)
                                        .withOpacity(0.12),
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
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (nuevo) {
                                if (nuevo != null) _cambiarEstado(p, nuevo);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipRango(String texto, _Rango valor) {
    final seleccionado = _rango == valor;
    return ChoiceChip(
      label: Text(texto),
      selected: seleccionado,
      onSelected: (_) => setState(() => _rango = valor),
      selectedColor: AppColors.verde,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : Colors.black87,
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
