import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';
import '../services/api_config.dart';

class GraficoVentas extends StatefulWidget {
  const GraficoVentas({super.key});
  @override
  State<GraficoVentas> createState() => _GraficoVentasState();
}

class _GraficoVentasState extends State<GraficoVentas> {
  final Dio _dio = DioClient.dio;
  List<Map<String, dynamic>> _datos = [];
  bool _cargando = true;
  int? _tocado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await _dio.get(ApiConfig.productosMasVendidos);
      setState(() {
       _datos = (res.data as List).map((e) {
  final item = e as Map<String, dynamic>;
  return {
    'nombre': item['nombre'] as String,
    'total_vendido': double.tryParse(
        item['total_vendido'].toString()) ?? 0.0,
    'total_ingresos': double.tryParse(
        item['total_ingresos'].toString()) ?? 0.0,
  };
}).toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  // Colores para cada barra
  final List<Color> _colores = [
    const Color(0xFF1B9B5E),
    const Color(0xFF26C67A),
    const Color(0xFF4CAF50),
    const Color(0xFF81C784),
    const Color(0xFFA5D6A7),
  ];

  // Nombre corto para el eje X
  String _nombreCorto(String nombre) {
    final palabras = nombre.trim().split(' ');
    if (palabras.length == 1) {
      return nombre.length > 8
          ? '${nombre.substring(0, 8)}.'
          : nombre;
    }
    return palabras.take(2).map((p) =>
        p.length > 6 ? '${p.substring(0, 6)}.' : p).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFF1B9B5E)),
        ),
      );
    }

    if (_datos.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Sin ventas registradas',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final maxY = _datos
        .map((e) => (e['total_vendido'] as double))
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: Color(0xFF1B9B5E), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Productos más vendidos',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _cargar,
                child: const Icon(Icons.refresh,
                    size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Top ${_datos.length} productos',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          // Gráfico
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.3,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= _datos.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _nombreCorto(
                                _datos[i]['nombre'] as String),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: _tocado == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _tocado == i
                                  ? const Color(0xFF1B9B5E)
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(_datos.length, (i) {
                  final valor = (_datos[i]['total_vendido'] as double);
                  final esTocado = _tocado == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: valor,
                        width: esTocado ? 28 : 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        color: _colores[i % _colores.length],
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.3,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null &&
                          event is! FlTapUpEvent) {
                        _tocado = response!
                            .spot!.touchedBarGroupIndex;
                      } else {
                        _tocado = null;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        const Color(0xFF1B9B5E),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, gI, rod, rI) {
                      final nombre =
                          _datos[group.x]['nombre'] as String;
                      final total = rod.toY.toInt();
                      return BarTooltipItem(
                        '$nombre\n',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        children: [
                          TextSpan(
                            text: '$total vendidos',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Leyenda
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(_datos.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colores[i % _colores.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _datos[i]['nombre'] as String,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}