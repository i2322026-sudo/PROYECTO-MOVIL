import 'package:flutter/material.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/services/api_config.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/app_colors.dart';

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

  /// Foto real del producto (misma resolución de URL que usa
  /// TarjetaProducto/dashboard.js) con un badge pequeño superpuesto
  /// que conserva la señal de "vencido"/"por vencer" que antes daba
  /// el ícono solo. Si no hay imagen o falla la carga, cae al mismo
  /// ícono de reloj/error que se usaba antes.
  Widget _miniaturaConEstado(Producto p, bool vencido) {
    final url = ApiConfig.urlImagen(p.imagen);
    final colorEstado = vencido ? Colors.red : Colors.orange;
    final iconoEstado =
        vencido ? Icons.error_outline : Icons.hourglass_bottom;

    Widget base;
    if (url == null) {
      base = CircleAvatar(
        backgroundColor: colorEstado.withOpacity(0.12),
        child: Icon(iconoEstado, color: colorEstado),
      );
    } else {
      base = ClipOval(
        child: Image.network(
          url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progreso) => progreso == null
              ? child
              : Container(
                  width: 40,
                  height: 40,
                  color: colorEstado.withOpacity(0.12),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (ctx, error, stack) => Container(
            width: 40,
            height: 40,
            color: colorEstado.withOpacity(0.12),
            child: Icon(iconoEstado, color: colorEstado, size: 20),
          ),
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          base,
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: colorEstado, width: 1),
              ),
              child: Icon(iconoEstado, color: colorEstado, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos a Vencer'),
        backgroundColor: AppColors.verde,
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
                      leading: _miniaturaConEstado(p, vencido),
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
