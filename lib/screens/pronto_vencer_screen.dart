import 'package:flutter/material.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/widgets/estado_lista.dart';

// ─────────────────────────────────────────────────────────────
//  ProntoVencerScreen — GET /api/inventario/por-vencer SÍ existe
//  de verdad y ya calcula dias_restantes con DATEDIFF en SQL.
//  Ya no hace falta calcular fechas en la app.
// ─────────────────────────────────────────────────────────────
class ProntoVencerScreen extends StatefulWidget {
  const ProntoVencerScreen({super.key});

  @override
  State<ProntoVencerScreen> createState() => _ProntoVencerScreenState();
}

class _ProntoVencerScreenState extends State<ProntoVencerScreen> {
  final _service = ProductoService();
  List<Producto> _productos = [];
  bool _cargando = true;
  String? _error;
  int _diasLimite = 30;

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
      final productos = await _service.getProximosVencer(dias: _diasLimite);
      setState(() {
        _productos = productos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos a Vencer'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Mostrar hasta: '),
                DropdownButton<int>(
                  value: _diasLimite,
                  items: const [7, 15, 30, 60, 90]
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text('$d días')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _diasLimite = v);
                      _cargar();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: EstadoLista(
              cargando: _cargando,
              error: _error,
              vacio: _productos.isEmpty,
              mensajeVacio: 'No hay productos por vencer en este rango',
              onReintentar: _cargar,
              builder: () => RefreshIndicator(
                onRefresh: _cargar,
                child: ListView.builder(
                  itemCount: _productos.length,
                  itemBuilder: (ctx, i) {
                    final p = _productos[i];
                    final dias = p.diasRestantes ?? 0;
                    final vencido = dias < 0;
                    return ListTile(
                      leading: Icon(
                        vencido ? Icons.error_outline : Icons.hourglass_bottom,
                        color: vencido ? Colors.red : Colors.orange,
                      ),
                      title: Text(p.nombre),
                      subtitle:
                          Text(p.fechaVencimiento?.split('T').first ?? '-'),
                      trailing: Text(
                        vencido ? 'Vencido' : 'En $dias día${dias == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: vencido ? Colors.red : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
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
}
