import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/producto_model.dart';
import '../services/producto_service.dart';
import '../services/reporte_service.dart';
import '../widgets/tarjeta_producto.dart';
import '../widgets/estado_lista.dart';
import 'nuevo_producto_screen.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  ProductosScreen — lista el inventario real conectado a
//  GET /api/productos, con búsqueda en vivo, activar/desactivar
//  (endpoint dedicado PUT /:id/estado), eliminar (borrado físico
//  real, bloqueado si hay pedidos asociados) y crear/editar.
// ─────────────────────────────────────────────────────────────
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

/// Filtro rápido sobre el inventario por fecha de creación — mismo
/// patrón y mismas opciones que el rango de fechas en Gestión de
/// Pedidos (Todos/Hoy/Semana/Quincena/Mes), conectado a la descarga.
enum _FiltroProducto { todos, dia, semana, quincena, mes }

class _ProductosScreenState extends State<ProductosScreen> {
  final _service = ProductoService();
  final _reporteService = ReporteService();
  final _buscadorCtrl = TextEditingController();
  Timer? _debounce;
  bool _exportando = false;

  List<Producto> _productos = [];
  bool _cargando = true;
  String? _error;
  _FiltroProducto _filtro = _FiltroProducto.todos;

  // 'activos' (todo menos lo archivado) o 'archivados' — misma
  // pestaña que tiene el panel web sobre la tabla de Inventario.
  String _vista = 'activos';

  /// Productos cuya fecha de creación cae dentro del rango elegido.
  List<Producto> get _productosFiltrados {
    if (_filtro == _FiltroProducto.todos) return _productos;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    late DateTime desde;
    switch (_filtro) {
      case _FiltroProducto.dia:
        desde = hoy;
        break;
      case _FiltroProducto.semana:
        desde = hoy.subtract(const Duration(days: 7));
        break;
      case _FiltroProducto.quincena:
        desde = hoy.subtract(const Duration(days: 15));
        break;
      case _FiltroProducto.mes:
        desde = hoy.subtract(const Duration(days: 30));
        break;
      case _FiltroProducto.todos:
        desde = DateTime(2000);
    }
    return _productos.where((p) {
      final f = p.fechaCreacion == null
          ? null
          : DateTime.tryParse(p.fechaCreacion!);
      return f != null && !f.isBefore(desde);
    }).toList();
  }

  String get _mensajeVacioFiltro {
    if (_vista == 'archivados') return 'No hay productos archivados';
    switch (_filtro) {
      case _FiltroProducto.todos:
        return 'No hay productos registrados';
      default:
        return 'No hay productos creados en este rango de fechas';
    }
  }

  void _cambiarVista(String vista) {
    if (vista == _vista) return;
    setState(() => _vista = vista);
    _cargarProductos();
  }

  String get _etiquetaFiltro {
    switch (_filtro) {
      case _FiltroProducto.dia:
        return 'Hoy';
      case _FiltroProducto.semana:
        return 'Semana';
      case _FiltroProducto.quincena:
        return 'Quincena';
      case _FiltroProducto.mes:
        return 'Mes';
      case _FiltroProducto.todos:
        return 'Todos';
    }
  }

  Future<void> _exportarExcelFiltrado() async {
    setState(() => _exportando = true);
    try {
      final filtrados = _productosFiltrados;
      final buffer = StringBuffer();
      buffer.writeln('Producto,Categoría,Precio,Stock,Estado');
      String csvSafe(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
      for (final p in filtrados) {
        buffer.writeln(
          '${csvSafe(p.nombre)},${csvSafe(p.categoria)},'
          '${p.precioVenta.toStringAsFixed(2)},${p.stockActual},${csvSafe(p.estado)}',
        );
      }
      final bytes = utf8.encode(buffer.toString());
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'inventario_${_filtro.name}.csv',
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
      final bytes = await _reporteService.exportar('productos', 'pdf');
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'inventario.pdf',
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

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscadorCtrl.dispose();
    super.dispose();
  }

  void _onBuscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _cargarProductos(nombre: texto.trim().isEmpty ? null : texto.trim());
    });
  }

  Future<void> _cargarProductos({String? nombre}) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final productos =
          await _service.getProductos(nombre: nombre, vista: _vista);
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

  /// Activar/Desactivar en un solo botón, igual que el ícono de
  /// la web que cambia de color según el estado actual.
  Future<void> _toggleEstado(Producto p) async {
    final activarlo = p.estado != 'ACTIVO';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activarlo ? 'Activar producto' : 'Desactivar producto'),
        content: Text(
          activarlo
              ? '¿Volver a mostrar "${p.nombre}" en el catálogo?'
              : '¿Seguro que deseas desactivar "${p.nombre}"?\n\n'
                  'Dejará de verse en el catálogo, pero no se borrará.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(activarlo ? 'Activar' : 'Desactivar',
                  style: TextStyle(
                      color: activarlo ? Colors.green : Colors.orange))),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.cambiarEstado(
          p.idProducto, activarlo ? 'ACTIVO' : 'INACTIVO');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Producto ${activarlo ? 'activado' : 'desactivado'}')));
      _cargarProductos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _eliminar(Producto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que deseas eliminar "${p.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.eliminarProducto(p.idProducto);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      _cargarProductos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _verFicha(Producto p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p.marca?.isNotEmpty ?? false) _filaFicha('Marca', p.marca!),
              if (p.composicion?.isNotEmpty ?? false)
                _filaFicha('Composición', p.composicion!),
              if (p.modoUso?.isNotEmpty ?? false)
                _filaFicha('Modo de uso', p.modoUso!),
              if (p.fichaTecnica?.isNotEmpty ?? false)
                _filaFicha('Ficha técnica', p.fichaTecnica!),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _filaFicha(String titulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.verde)),
            Text(valor),
          ],
        ),
      );

  Future<void> _abrirNuevoProducto({Producto? existente}) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NuevoProductoScreen(productoExistente: existente),
      ),
    );
    if (guardado == true) _cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Productos'),
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
                        strokeWidth: 2, color: Colors.white),
                  ),
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
                      child: Text('Exportar Excel (${_etiquetaFiltro})'),
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
          // ── Pestañas Activos / Archivados — igual que la tabla web ──
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _botonPestanaVista(
                    'Activos',
                    Icons.inventory_2_outlined,
                    activo: _vista == 'activos',
                    onTap: () => _cambiarVista('activos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _botonPestanaVista(
                    'Archivados',
                    Icons.archive_outlined,
                    activo: _vista == 'archivados',
                    onTap: () => _cambiarVista('archivados'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscadorCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscadorCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _buscadorCtrl.clear();
                          _onBuscar('');
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                setState(() {});
                _onBuscar(v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: EstadoLista(
              cargando: _cargando,
              error: _error,
              vacio: _productosFiltrados.isEmpty,
              mensajeVacio: _mensajeVacioFiltro,
              onReintentar: () => _cargarProductos(),
              builder: () => RefreshIndicator(
                onRefresh: () => _cargarProductos(),
                child: ListView.builder(
                  itemCount: _productosFiltrados.length,
                  itemBuilder: (ctx, i) {
                    final p = _productosFiltrados[i];
                    return TarjetaProducto(
                      producto: p,
                      onEliminar: () => _eliminar(p),
                      onToggleEstado: () => _toggleEstado(p),
                      onEditar: () => _abrirNuevoProducto(existente: p),
                      onVerFicha: () => _verFicha(p),
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

  // ── Botón de pestaña Activos/Archivados ──
  Widget _botonPestanaVista(String texto, IconData icono,
      {required bool activo, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icono, size: 16),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: activo ? AppColors.verde : Colors.grey.shade200,
        foregroundColor: activo ? Colors.white : Colors.grey.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

}
