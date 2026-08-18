import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movil/models/venta_model.dart';
import 'package:movil/services/venta_service.dart';
import 'package:movil/widgets/estado_lista.dart';

// ─────────────────────────────────────────────────────────────
//  GestionVentasScreen — calcada de "Gestión de Ventas" del panel
//  web (public/ventas.html): filtros Estado / Desde / Hasta,
//  botón Filtrar, exportar a Excel y la tabla de comprobantes.
// ─────────────────────────────────────────────────────────────
class GestionVentasScreen extends StatefulWidget {
  const GestionVentasScreen({super.key});

  @override
  State<GestionVentasScreen> createState() => _GestionVentasScreenState();
}

class _GestionVentasScreenState extends State<GestionVentasScreen> {
  final _service = VentaService();

  List<Venta> _ventas = [];
  bool _cargando = true;
  bool _exportando = false;
  String? _error;

  String? _estado; // null = Todos
  DateTime? _desde;
  DateTime? _hasta;

  static const _estados = ['PAGADO', 'ENTREGADO'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String? get _desdeStr =>
      _desde == null ? null : _desde!.toIso8601String().split('T').first;
  String? get _hastaStr =>
      _hasta == null ? null : _hasta!.toIso8601String().split('T').first;

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ventas = await _service.listar(
        estado: _estado,
        desde: _desdeStr,
        hasta: _hastaStr,
      );
      setState(() {
        _ventas = ventas;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _exportarExcel() async {
    setState(() => _exportando = true);
    try {
      final bytes = await _service.exportarExcel(
        estado: _estado,
        desde: _desdeStr,
        hasta: _hastaStr,
      );
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'ventas.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
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

  Future<void> _elegirFecha({required bool esDesde}) async {
    final inicial = esDesde ? (_desde ?? DateTime.now()) : (_hasta ?? DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (fecha == null) return;
    setState(() {
      if (esDesde) {
        _desde = fecha;
      } else {
        _hasta = fecha;
      }
    });
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PAGADO':
        return Colors.blue;
      case 'ENTREGADO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _fmtFecha(String? f) {
    if (f == null) return '-';
    final dt = DateTime.tryParse(f);
    if (dt == null) return f.split('T').first;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ventas'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
        actions: [
          _exportando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Exportar Excel',
                  onPressed: _exportarExcel,
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros: Estado / Desde / Hasta ──
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESTADO',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String?>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ..._estados.map(
                        (e) => DropdownMenuItem(value: e, child: Text(e))),
                  ],
                  onChanged: (v) => setState(() => _estado = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _campoFecha(
                        'DESDE',
                        _desde,
                        () => _elegirFecha(esDesde: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campoFecha(
                        'HASTA',
                        _hasta,
                        () => _elegirFecha(esDesde: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Filtrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B9B5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: EstadoLista(
              cargando: _cargando,
              error: _error,
              vacio: _ventas.isEmpty,
              mensajeVacio: 'No hay ventas con estos filtros',
              onReintentar: _cargar,
              builder: () => RefreshIndicator(
                onRefresh: _cargar,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _ventas.length,
                  itemBuilder: (ctx, i) {
                    final v = _ventas[i];
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(v.comprobante,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(v.tipo,
                                      style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(v.cliente),
                            Text(_fmtFecha(v.fecha),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('S/. ${v.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Color(0xFF1B9B5E),
                                        fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Text(v.metodoPago,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _colorEstado(v.estado)
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        v.estado,
                                        style: TextStyle(
                                            color: _colorEstado(v.estado),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _campoFecha(String etiqueta, DateTime? valor, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  valor == null
                      ? 'dd/mm/aaaa'
                      : '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}',
                  style: TextStyle(
                      color: valor == null ? Colors.grey.shade500 : Colors.black,
                      fontSize: 13),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
