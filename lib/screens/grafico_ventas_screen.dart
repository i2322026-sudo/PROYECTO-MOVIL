import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:movil/models/pedido_model.dart';
import 'package:movil/services/dashboard_service.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/widgets/estado_lista.dart';

// ─────────────────────────────────────────────────────────────
//  GraficoVentasScreen — calcada del panel "Reportes" de la web:
//   1) Ventas por Mes (últimos 6 meses) → gráfico de área/línea,
//      igual que el de reportes.html (antes era de barras acá).
//   2) Productos Más Vendidos (top 5)   → dona, igual que la web.
//   3) Pedidos por Estado               → dona NUEVA, no existe
//      en la web todavía. Muestra de un vistazo cuántos pedidos
//      están en cada estado (PENDIENTE/PAGADO/ENVIADO/ENTREGADO/
//      CANCELADO) — útil para detectar cuellos de botella (muchos
//      PENDIENTE sin pagar) o una tasa de CANCELADO alta. Se
//      calcula en la app a partir de GET /api/pedidos (ya se pide
//      en el Dashboard), no requiere endpoint nuevo en el backend.
// ─────────────────────────────────────────────────────────────
class GraficoVentasScreen extends StatefulWidget {
  const GraficoVentasScreen({super.key});

  @override
  State<GraficoVentasScreen> createState() => _GraficoVentasScreenState();
}

class _GraficoVentasScreenState extends State<GraficoVentasScreen> {
  final _dashboardService = DashboardService();
  final _pedidoService = PedidoService();

  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _meses = [];
  List<Map<String, dynamic>> _masVendidos = [];
  List<Map<String, dynamic>> _topClientes = [];
  List<Pedido> _pedidos = [];

  static const _coloresDona = [
    Color(0xFF06A049),
    Color(0xFF2FBE73),
    Color(0xFF3B82C4),
    Color(0xFFF5C242),
    Color(0xFFEF7B45),
  ];

  static const _coloresEstado = {
    'PENDIENTE': Colors.orange,
    'PAGADO': Colors.blue,
    'ENVIADO': Colors.indigo,
    'ENTREGADO': Colors.green,
    'CANCELADO': Colors.red,
  };

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
      final meses = await _dashboardService.getVentasPorMes();
      final masVendidos = await _dashboardService.getProductosMasVendidos();
      final topClientes = await _dashboardService.getTopClientes(limite: 10);
      final pedidos = await _pedidoService.getPedidos();
      setState(() {
        _meses = meses;
        _masVendidos = masVendidos;
        _topClientes = topClientes;
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

  double _totalVentas(Map<String, dynamic> m) =>
      double.tryParse(m['total_ventas'].toString()) ?? 0.0;

  double _totalVendido(Map<String, dynamic> m) =>
      double.tryParse(m['total_vendido'].toString()) ?? 0.0;

  double _totalGastado(Map<String, dynamic> m) =>
      double.tryParse(m['total_gastado'].toString()) ?? 0.0;

  /// Conteo de pedidos agrupados por estado, en el mismo orden que
  /// usa el resto de la app (pantalla de Gestión de Pedidos).
  Map<String, int> get _pedidosPorEstado {
    final conteo = <String, int>{
      'PENDIENTE': 0,
      'PAGADO': 0,
      'ENVIADO': 0,
      'ENTREGADO': 0,
      'CANCELADO': 0,
    };
    for (final p in _pedidos) {
      if (conteo.containsKey(p.estado)) {
        conteo[p.estado!] = conteo[p.estado]! + 1;
      }
    }
    return conteo;
  }

  @override
  Widget build(BuildContext context) {
    final totalGeneral = _meses.fold<double>(0, (s, m) => s + _totalVentas(m));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _meses.isEmpty && _masVendidos.isEmpty && _pedidos.isEmpty,
        mensajeVacio: 'No hay datos de ventas todavía',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total (últimos 6 meses): S/. ${totalGeneral.toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Solo pedidos PAGADO, ENVIADO o ENTREGADO',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                _tarjeta(
                  titulo: 'Ventas por Mes',
                  icono: Icons.show_chart,
                  child: _meses.isEmpty
                      ? _sinDatos('Sin ventas en este período')
                      : _graficoArea(),
                ),
                const SizedBox(height: 16),
                _tarjeta(
                  titulo: 'Productos Más Vendidos',
                  icono: Icons.emoji_events_outlined,
                  child: _masVendidos.isEmpty
                      ? _sinDatos('Aún no hay productos vendidos')
                      : _donaMasVendidos(),
                ),
                const SizedBox(height: 16),
                _tarjeta(
                  titulo: 'Top 10 Clientes',
                  icono: Icons.people_alt_outlined,
                  child: _topClientes.isEmpty
                      ? _sinDatos('Aún no hay clientes con compras')
                      : _donaTopClientes(),
                ),
                const SizedBox(height: 16),
                _tarjeta(
                  titulo: 'Pedidos por Estado',
                  icono: Icons.pie_chart_outline,
                  child: _pedidos.isEmpty
                      ? _sinDatos('Aún no hay pedidos registrados')
                      : _donaPedidosPorEstado(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tarjeta contenedora, mismo estilo "card" que usa la web ──
  Widget _tarjeta({
    required String titulo,
    required IconData icono,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFF06A049), size: 18),
              const SizedBox(width: 8),
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047a37),
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _sinDatos(String texto) => SizedBox(
        height: 140,
        child: Center(
          child: Text(texto,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
      );

  // ── 1) Ventas por Mes — gráfico de área/línea (como reportes.html) ──
  Widget _graficoArea() {
    final spots = List.generate(
      _meses.length,
      (i) => FlSpot(i.toDouble(), _totalVentas(_meses[i])),
    );
    final maxY = _meses.map(_totalVentas).reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map((s) => LineTooltipItem(
                        'S/. ${s.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 2 : maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _meses.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      (_meses[i]['mes_label'] ?? '').toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF06A049),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF06A049).withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2) Productos Más Vendidos — dona (como el panel de reportes web) ──
  Widget _donaMasVendidos() {
    final total = _masVendidos.fold<double>(0, (s, m) => s + _totalVendido(m));
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 45,
              sections: List.generate(_masVendidos.length, (i) {
                final cantidad = _totalVendido(_masVendidos[i]);
                final pct = total == 0 ? 0 : (cantidad / total * 100);
                return PieChartSectionData(
                  value: cantidad,
                  color: _coloresDona[i % _coloresDona.length],
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 46,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: List.generate(_masVendidos.length, (i) {
            final nombre = (_masVendidos[i]['nombre'] ?? '-').toString();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _coloresDona[i % _coloresDona.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(nombre, style: const TextStyle(fontSize: 12)),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ── Top 10 Clientes — dona (mismo estilo que Productos Más Vendidos) ──
  Widget _donaTopClientes() {
    final total = _topClientes.fold<double>(0, (s, m) => s + _totalGastado(m));
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 45,
              sections: List.generate(_topClientes.length, (i) {
                final gastado = _totalGastado(_topClientes[i]);
                final pct = total == 0 ? 0 : (gastado / total * 100);
                return PieChartSectionData(
                  value: gastado,
                  color: _coloresDona[i % _coloresDona.length],
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 46,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_topClientes.length, (i) {
            final nombre = (_topClientes[i]['nombres'] ?? '-').toString();
            final correo = (_topClientes[i]['correo'] ?? '-').toString();
            final pedidos = _topClientes[i]['total_pedidos'] ?? 0;
            final gastado = _totalGastado(_topClientes[i]);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _coloresDona[i % _coloresDona.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(correo,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                        Text(
                          'S/. ${gastado.toStringAsFixed(2)} · $pedidos pedido(s)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── 3) Pedidos por Estado — dona NUEVA recomendada ──
  Widget _donaPedidosPorEstado() {
    final conteo = _pedidosPorEstado;
    final entradas =
        conteo.entries.where((e) => e.value > 0).toList(growable: false);
    final totalPedidos = _pedidos.length;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                  sections: entradas.map((e) {
                    final pct = totalPedidos == 0
                        ? 0
                        : (e.value / totalPedidos * 100);
                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      color: _coloresEstado[e.key] ?? Colors.grey,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$totalPedidos',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('pedidos',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: entradas.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _coloresEstado[e.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text('${e.key} (${e.value})',
                    style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
