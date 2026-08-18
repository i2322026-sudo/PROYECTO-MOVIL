import 'package:flutter/material.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/widgets/tarjeta_producto.dart';
import 'package:movil/widgets/estado_lista.dart';

// ─────────────────────────────────────────────────────────────
//  BajoStockScreen — GET /api/inventario/bajo-stock SÍ existe
//  de verdad en el backend real y ya filtra en el servidor
//  (stock_actual <= stock_minimo). Ya no hace falta traer todo
//  el inventario y filtrar en la app.
// ─────────────────────────────────────────────────────────────
class BajoStockScreen extends StatefulWidget {
  const BajoStockScreen({super.key});

  @override
  State<BajoStockScreen> createState() => _BajoStockScreenState();
}

class _BajoStockScreenState extends State<BajoStockScreen> {
  final _service = ProductoService();
  List<Producto> _productos = [];
  bool _cargando = true;
  String? _error;

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
      final productos = await _service.getBajoStock();
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
        title: const Text('Productos con Stock Bajo'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _productos.isEmpty,
        mensajeVacio: '¡Todo el inventario está en buen nivel! 🎉',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            itemCount: _productos.length,
            itemBuilder: (ctx, i) => TarjetaProducto(producto: _productos[i]),
          ),
        ),
      ),
    );
  }
}
