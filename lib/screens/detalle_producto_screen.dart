import 'package:flutter/material.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/screens/nuevo_producto_screen.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  DetalleProductoScreen — GET /api/productos/:id (existe de
//  verdad en producto.routes.js). Permite ir a editar, que usa
//  el mismo NuevoProductoScreen en modo edición.
// ─────────────────────────────────────────────────────────────
class DetalleProductoScreen extends StatefulWidget {
  final int idProducto;
  const DetalleProductoScreen({super.key, required this.idProducto});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final _service = ProductoService();
  Producto? _producto;
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
      final p = await _service.getProductoPorId(widget.idProducto);
      setState(() {
        _producto = p;
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
        title: Text(_producto?.nombre ?? 'Producto'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: [
          if (_producto != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final actualizado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NuevoProductoScreen(productoExistente: _producto),
                  ),
                );
                if (actualizado == true) _cargar();
              },
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _producto == null
                  ? const SizedBox()
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if ((_producto!.imagen ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _producto!.imagen!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 180,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                        if ((_producto!.imagen ?? '').isNotEmpty)
                          const SizedBox(height: 16),
                        Text(
                          _producto!.nombre,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'S/. ${_producto!.precioVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.verde,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: (_producto!.estado == 'ACTIVO'
                                        ? Colors.green
                                        : Colors.grey)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _producto!.estado,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _producto!.estado == 'ACTIVO'
                                      ? Colors.green.shade800
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (_producto!.stockBajo) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Stock bajo',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _seccion('Información general'),
                        _fila('Categoría', _producto!.categoria ?? '-'),
                        _fila('Tipo de animal', _producto!.tipoAnimal ?? '-'),
                        _fila('Marca', _producto!.marca ?? '-'),
                        _fila('Peso / Presentación',
                            _producto!.pesoPresentacion ?? '-'),
                        _fila('Stock actual', '${_producto!.stockActual}'),
                        _fila('Stock mínimo', '${_producto!.stockMinimo}'),
                        _fila('Código de barra', _producto!.codigoBarra ?? '-'),
                        _fila('Vencimiento',
                            _producto!.fechaVencimiento?.split('T').first ?? '-'),
                        if ((_producto!.colores ?? '').isNotEmpty)
                          _fila('Colores', _producto!.colores!),
                        if ((_producto!.tallas ?? '').isNotEmpty)
                          _fila('Tallas', _producto!.tallas!),
                        const SizedBox(height: 16),
                        _seccion('Descripción'),
                        Text(_producto!.descripcion ?? 'Sin descripción'),
                        if ((_producto!.composicion ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _seccion('Composición'),
                          Text(_producto!.composicion!),
                        ],
                        if ((_producto!.modoUso ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _seccion('Modo de uso'),
                          Text(_producto!.modoUso!),
                        ],
                        if ((_producto!.fichaTecnica ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _seccion('Ficha técnica'),
                          Text(_producto!.fichaTecnica!),
                        ],
                      ],
                    ),
    );
  }

  Widget _seccion(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.verdeOscuro,
                fontSize: 14)),
      );

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(etiqueta,
                  style: TextStyle(color: Colors.grey.shade700))),
          Expanded(
              child: Text(valor,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
