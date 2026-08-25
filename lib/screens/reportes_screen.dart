import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movil/models/pedido_model.dart';
import 'package:movil/services/reporte_service.dart';
import 'package:movil/services/dashboard_service.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/widgets/tarjeta_resumen.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  ReportesScreen — calcada de la web (public/reportes.html +
//  public/js/reportes.js):
//   1) KPIs: Ventas Hoy, Ventas del Mes, Productos Activos, Alertas
//      de Stock (GET /api/reportes/resumen).
//   2) Productos con Stock Bajo (GET /api/reportes/productos-stock-bajo).
//   3) Gráficos: Ventas por Categoría, Productos Más Vendidos, Top
//      Clientes y Pedidos por Estado — mismos datos que la web, más
//      2 gráficos extra que la web no tiene (Top Clientes y Pedidos
//      por Estado).
//   4) Exportar Datos: mismos 3 botones que la web —
//      - Reporte de Ventas (PDF), con el mismo filtro de mes/año que
//        se agregó en reportes.js.
//      - Inventario Completo (Excel, ya viene filtrado a solo
//        productos ACTIVOS desde el backend).
//      - Datos para Power BI (Excel crudo).
// ─────────────────────────────────────────────────────────────
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _service = ReporteService();
  final _dashboardService = DashboardService();
  final _pedidoService = PedidoService();

  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _resumen;
  List<Map<String, dynamic>> _stockBajo = [];

  // ── Datos de los gráficos ──
  List<Map<String, dynamic>> _ventasPorCategoria = [];
  List<Map<String, dynamic>> _masVendidos = [];
  List<Map<String, dynamic>> _topClientes = [];
  List<Pedido> _pedidos = [];

  static const _coloresDona = [
    AppColors.verde,
    AppColors.verdeClaro,
    AppColors.azul,
    AppColors.dorado,
    AppColors.naranja,
  ];

  static const _coloresEstado = {
    'PENDIENTE': Colors.orange,
    'PAGADO': Colors.blue,
    'ENVIADO': Colors.indigo,
    'ENTREGADO': Colors.green,
    'CANCELADO': Colors.red,
  };

  int? _mesPdf;
  int? _anioPdf;
  bool _exportando = false;

  static const _nombresMes = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
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
      final resumen = await _service.getResumen();
      final stockBajo = await _service.getProductosStockBajo();
      final ventasPorCategoria = await _service.getVentasPorCategoria();
      final masVendidos = await _dashboardService.getProductosMasVendidos();
      final topClientes = await _dashboardService.getTopClientes(limite: 10);
      final pedidos = await _pedidoService.getPedidos();
      setState(() {
        _resumen = resumen;
        _stockBajo = stockBajo;
        _ventasPorCategoria = ventasPorCategoria;
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

  double _totalCategoria(Map<String, dynamic> m) =>
      double.tryParse(m['total'].toString()) ?? 0.0;

  double _totalVendido(Map<String, dynamic> m) =>
      double.tryParse(m['total_vendido'].toString()) ?? 0.0;

  int _totalPedidosCliente(Map<String, dynamic> m) =>
      int.tryParse(m['total_pedidos'].toString()) ?? 0;

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

  String _soles(dynamic n) {
    final v = double.tryParse('$n') ?? 0;
    return 'S/. ${v.toStringAsFixed(2)}';
  }

  Future<void> _compartirBytes(
      List<int> bytes, String nombre, bool esExcel) async {
    await Share.shareXFiles([
      XFile.fromData(
        Uint8List.fromList(bytes),
        name: nombre,
        mimeType: esExcel
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf',
      ),
    ]);
  }

  Future<void> _exportarVentasPdf() async {
    setState(() => _exportando = true);
    try {
      final bytes =
          await _service.exportarVentasPdf(mes: _mesPdf, anio: _anioPdf);
      String nombre = 'reporte-ventas.pdf';
      if (_mesPdf != null && _anioPdf != null) {
        nombre =
            'reporte-ventas-${_nombresMes[_mesPdf! - 1].toLowerCase()}-$_anioPdf.pdf';
      } else if (_anioPdf != null) {
        nombre = 'reporte-ventas-$_anioPdf.pdf';
      } else if (_mesPdf != null) {
        nombre = 'reporte-ventas-${_nombresMes[_mesPdf! - 1].toLowerCase()}.pdf';
      }
      await _compartirBytes(bytes, nombre, false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarInventario() async {
    setState(() => _exportando = true);
    try {
      final bytes = await _service.exportarInventarioActivoExcel();
      await _compartirBytes(bytes, 'inventario.xlsx', true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarPowerBI() async {
    setState(() => _exportando = true);
    try {
      final bytes = await _service.exportarVentasPowerBI();
      await _compartirBytes(bytes, 'ventas-powerbi.xlsx', true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anioActual = DateTime.now().year;
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      appBar: AppBar(
        title: const Text('Reportes y Analítica'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 60),
                      Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                            onPressed: _cargar, child: const Text('Reintentar')),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── KPIs (2x2, igual que la web) ──
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          TarjetaResumen(
                            titulo: 'Ventas Hoy',
                            valor: _soles(_resumen?['ventasHoy']),
                            icono: Icons.point_of_sale_outlined,
                            color: AppColors.verde,
                          ),
                          TarjetaResumen(
                            titulo: 'Ventas del Mes',
                            valor: _soles(_resumen?['ventasMes']),
                            icono: Icons.show_chart,
                            color: AppColors.azul,
                          ),
                          TarjetaResumen(
                            titulo: 'Productos Activos',
                            valor: '${_resumen?['productosActivos'] ?? 0}',
                            icono: Icons.inventory_2_outlined,
                            color: AppColors.dorado,
                          ),
                          TarjetaResumen(
                            titulo: 'Alertas de Stock',
                            valor: '${_resumen?['alertasStock'] ?? 0}',
                            icono: Icons.warning_amber_outlined,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Gráficos ──
                      _tarjetaGrafico(
                        titulo: 'Ventas por Categoría',
                        icono: Icons.bar_chart,
                        child: _ventasPorCategoria.isEmpty
                            ? _sinDatosGrafico('Sin ventas registradas todavía')
                            : _barrasVentasPorCategoria(),
                      ),
                      const SizedBox(height: 16),
                      _tarjetaGrafico(
                        titulo: 'Productos Más Vendidos',
                        icono: Icons.emoji_events_outlined,
                        child: _masVendidos.isEmpty
                            ? _sinDatosGrafico('Aún no hay productos vendidos')
                            : _donaMasVendidos(),
                      ),
                      const SizedBox(height: 16),
                      _tarjetaGrafico(
                        titulo: 'Top 10 Clientes que Más Compran',
                        icono: Icons.people_alt_outlined,
                        child: _topClientes.isEmpty
                            ? _sinDatosGrafico('Aún no hay clientes con compras')
                            : _donaTopClientes(),
                      ),
                      const SizedBox(height: 16),
                      _tarjetaGrafico(
                        titulo: 'Pedidos por Estado',
                        icono: Icons.pie_chart_outline,
                        child: _pedidos.isEmpty
                            ? _sinDatosGrafico('Aún no hay pedidos registrados')
                            : _donaPedidosPorEstado(),
                      ),
                      const SizedBox(height: 24),

                      // ── Productos con Stock Bajo ──
                      const Text('Productos con Stock Bajo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (_stockBajo.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('Sin alertas de stock bajo',
                              style: TextStyle(color: Colors.grey.shade600)),
                        )
                      else
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: _stockBajo.map((p) {
                              return ListTile(
                                dense: true,
                                title: Text('${p['nombre'] ?? ''}'),
                                subtitle: Text('${p['categoria'] ?? '-'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text('${p['stock_actual'] ?? 0}'),
                                      backgroundColor: Colors.red.shade50,
                                      labelStyle:
                                          const TextStyle(color: Colors.red),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('/ ${p['stock_minimo'] ?? 0}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // ── Exportar Datos (igual que la web) ──
                      const Text('Exportar Datos',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      // Reporte de Ventas (PDF) con filtro mes/año
                      _tarjetaExportar(
                        icono: Icons.picture_as_pdf,
                        color: Colors.red,
                        titulo: 'Reporte de Ventas',
                        subtitulo: 'Documento PDF con el detalle tabular de ventas.',
                        contenidoExtra: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _mesPdf,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Mes',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('Todos')),
                                  for (var i = 0; i < 12; i++)
                                    DropdownMenuItem(
                                        value: i + 1,
                                        child: Text(_nombresMes[i])),
                                ],
                                onChanged: (v) => setState(() => _mesPdf = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _anioPdf,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Año',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('Todos')),
                                  for (var a = anioActual; a >= anioActual - 4; a--)
                                    DropdownMenuItem(
                                        value: a, child: Text('$a')),
                                ],
                                onChanged: (v) => setState(() => _anioPdf = v),
                              ),
                            ),
                          ],
                        ),
                        botonTexto: 'Descargar PDF',
                        botonColor: Colors.red,
                        onPressed: _exportando ? null : _exportarVentasPdf,
                      ),
                      const SizedBox(height: 14),

                      // Inventario Completo (Excel, solo activos)
                      _tarjetaExportar(
                        icono: Icons.grid_on,
                        color: AppColors.verde,
                        titulo: 'Inventario Completo',
                        subtitulo:
                            'Excel con los productos activos y su stock.',
                        botonTexto: 'Descargar Excel',
                        botonColor: AppColors.verde,
                        onPressed: _exportando ? null : _exportarInventario,
                      ),
                      const SizedBox(height: 14),

                      // Datos para Power BI
                      _tarjetaExportar(
                        icono: Icons.bar_chart,
                        color: AppColors.dorado,
                        titulo: 'Datos para Power BI',
                        subtitulo:
                            'Excel crudo (solo datos) para analítica externa.',
                        botonTexto: 'Descargar datos',
                        botonColor: Colors.grey.shade700,
                        onPressed: _exportando ? null : _exportarPowerBI,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }

  // ── Tarjeta contenedora, mismo estilo "card" que usa la web ──
  Widget _tarjetaGrafico({
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
              Icon(icono, color: AppColors.verde, size: 18),
              const SizedBox(width: 8),
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.verdeOscuro,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _sinDatosGrafico(String texto) => SizedBox(
        height: 140,
        child: Center(
          child: Text(texto,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
      );

  // ── 1) Ventas por Categoría — barras verdes, IGUAL que
  //      reportes.html (public/js/reportes.js -> chartCategorias:
  //      backgroundColor rgba(6,160,73,0.75), borderRadius, sin
  //      leyenda, eje Y desde 0). Reemplaza al viejo gráfico de
  //      línea "Ventas por Mes" que no correspondía a nada real de
  //      la web y aparecía vacío/roto.
  Widget _barrasVentasPorCategoria() {
    final valores = _ventasPorCategoria.map(_totalCategoria).toList();
    final maxY = valores.isEmpty
        ? 10.0
        : (valores.reduce((a, b) => a > b ? a : b) * 1.2);

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                'S/. ${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  'S/.${value.toInt()}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _ventasPorCategoria.length) {
                    return const SizedBox.shrink();
                  }
                  final nombre =
                      (_ventasPorCategoria[i]['categoria'] ?? '-').toString();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      nombre.length > 10
                          ? '${nombre.substring(0, 10)}…'
                          : nombre,
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(_ventasPorCategoria.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _totalCategoria(_ventasPorCategoria[i]),
                  // rgba(6,160,73,0.75) — mismo verde y opacidad que
                  // usa reportes.js en la web.
                  color: AppColors.verde.withOpacity(0.75),
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
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

  // ── Top 10 Clientes que Más Compran — dona (igual que
  //     dashboard.js -> cargarGraficoTopClientes): el tamaño de
  //     cada porción es la CANTIDAD DE PEDIDOS, no el monto gastado
  //     — así un pedido de prueba con un monto absurdo (ej.
  //     S/. 1,069,160 cancelado) no revienta el gráfico con un
  //     96%/4% que no refleja nada real. El monto sí se sigue
  //     mostrando, pero como dato aparte en el tooltip/leyenda.
  Widget _donaTopClientes() {
    final totalPedidos = _topClientes.fold<int>(
        0, (s, m) => s + _totalPedidosCliente(m));
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 45,
              sections: List.generate(_topClientes.length, (i) {
                final pedidos = _totalPedidosCliente(_topClientes[i]);
                final pct =
                    totalPedidos == 0 ? 0 : (pedidos / totalPedidos * 100);
                return PieChartSectionData(
                  value: pedidos.toDouble(),
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
        // Leyenda simple (nombre + color), igual que la web —
        // el correo/monto/N° de pedidos queda solo al tocar la
        // porción (ver SnackBar abajo), no ocupando espacio fijo.
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: List.generate(_topClientes.length, (i) {
            final nombre = (_topClientes[i]['nombres'] ??
                    _topClientes[i]['correo'] ??
                    'Cliente')
                .toString();
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

  Widget _tarjetaExportar({
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    required String botonTexto,
    required Color botonColor,
    required VoidCallback? onPressed,
    Widget? contenidoExtra,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitulo,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          if (contenidoExtra != null) ...[
            const SizedBox(height: 10),
            contenidoExtra,
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: _exportando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download, size: 18),
              label: Text(botonTexto),
              style: ElevatedButton.styleFrom(
                backgroundColor: botonColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
