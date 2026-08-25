import 'package:flutter/material.dart';
import 'package:movil/models/detalle_venta_model.dart';
import 'package:movil/services/venta_service.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/services/api_config.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  DetalleVentaScreen — pantalla completa con el mismo contenido
//  que el modal "Detalle de Venta" del panel web: comprobante,
//  cliente + documento, tabla de productos, y los totales
//  (Subtotal / IGV / Total General).
// ─────────────────────────────────────────────────────────────
class DetalleVentaScreen extends StatefulWidget {
  final int idPedido;
  const DetalleVentaScreen({super.key, required this.idPedido});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  final _service = VentaService();
  final _pedidoService = PedidoService();
  DetalleVenta? _detalle;
  bool _cargando = true;
  bool _actualizandoEstado = false;
  String? _error;

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
      final detalle = await _service.obtenerDetalle(widget.idPedido);
      setState(() {
        _detalle = detalle;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _actualizandoEstado = true);
    try {
      await _pedidoService.actualizarEstado(widget.idPedido, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${widget.idPedido} → $nuevoEstado')),
      );
      // Se vuelve a cargar el detalle completo para reflejar el nuevo
      // estado en pantalla (igual que hace la web al refrescar la tabla).
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actualizandoEstado = false);
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '-';
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return fecha;
    final hora = TimeOfDay.fromDateTime(dt);
    final hh = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final ampm = hora.period == DayPeriod.am ? 'a. m.' : 'p. m.';
    return '${dt.day}/${dt.month}/${dt.year}, '
        '$hh:${hora.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: false,
        mensajeVacio: '',
        onReintentar: _cargar,
        builder: () {
          final d = _detalle!;
          final c = d.comprobante;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: AppColors.fondoClaro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${c.tipo} ${c.numero}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text('Pedido #${c.idPedido}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Fecha: ${_formatearFecha(c.fecha)}',
                          style: TextStyle(color: Colors.grey.shade700)),
                      const Divider(height: 20),
                      Text('Cliente: ${c.cliente}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (c.documento.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(c.documento,
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Detalle de entrega ──
              // Separado del comprobante porque "Cliente" arriba puede
              // ser la razón social (en factura) — acá siempre se
              // muestra la PERSONA real de contacto, sin importar si
              // es boleta o factura.
              Builder(builder: (_) {
                final esRecojo = c.tipoEntrega == 'RECOJO_TIENDA';
                return Card(
                  elevation: 0,
                  color: AppColors.fondoClaro,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(esRecojo ? Icons.storefront : Icons.local_shipping,
                                size: 18, color: AppColors.verde),
                            const SizedBox(width: 6),
                            const Text('Detalle de entrega',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.verde)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: esRecojo
                                ? Colors.grey.shade300
                                : AppColors.verde.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            esRecojo ? 'Recojo en tienda' : 'Delivery',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: esRecojo
                                  ? Colors.grey.shade800
                                  : AppColors.verde,
                            ),
                          ),
                        ),
                        if (c.direccionEntrega.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Dirección: ${c.direccionEntrega}',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                        if (!esRecojo && c.referencia.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Referencia: ${c.referencia}',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                        if (!esRecojo) ...[
                          const SizedBox(height: 8),
                          Text(
                              'Costo de envío: S/. ${c.costoEnvio.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${esRecojo ? 'Quién recoge' : 'Quién recibe'}: '
                          '${c.contactoNombre.isNotEmpty ? c.contactoNombre : '—'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Teléfono: ${c.contactoTelefono.isNotEmpty ? c.contactoTelefono : 'No registrado'}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        // Foto de evidencia — solo aparece si el pedido
                        // se canceló desde "Evidencia" en el móvil
                        // (repartidor no pudo entregar, cliente rechazó
                        // el producto, etc.). Mismo lugar donde ya se
                        // ve el resto de la info de entrega.
                        if (c.evidenciaUrl != null) ...[
                          const SizedBox(height: 14),
                          const Divider(),
                          Row(
                            children: const [
                              Icon(Icons.camera_alt_outlined,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 6),
                              Text('Evidencia de cancelación',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: InteractiveViewer(
                                        child: Image.network(
                                          ApiConfig.urlImagen(
                                                  c.evidenciaUrl) ??
                                              c.evidenciaUrl!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      style: IconButton.styleFrom(
                                          backgroundColor: Colors.black45,
                                          padding: EdgeInsets.zero),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                ApiConfig.urlImagen(c.evidenciaUrl) ??
                                    c.evidenciaUrl!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('Productos',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...d.productos.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: AppColors.fondoClaro,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.producto,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (p.color.isNotEmpty || p.talla.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                [
                                  if (p.color.isNotEmpty) 'Color: ${p.color}',
                                  if (p.talla.isNotEmpty) 'Talla: ${p.talla}',
                                ].join('  •  '),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${p.cantidad} x S/. ${p.precioUnitario.toStringAsFixed(2)}'),
                              Text(
                                'S/. ${p.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.verde),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: AppColors.fondoClaro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _filaTotal('Subtotal:',
                          'S/. ${d.totales.subtotal.toStringAsFixed(2)}'),
                      _filaTotal('IGV (18%):',
                          'S/. ${d.totales.igv.toStringAsFixed(2)}'),
                      const Divider(),
                      _filaTotal(
                        'Total General:',
                        'S/. ${d.totales.total.toStringAsFixed(2)}',
                        destacado: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Cambiar estado — mismo endpoint que usa la web ──
              Card(
                elevation: 0,
                color: AppColors.fondoClaro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _estados.contains(c.estado) ? c.estado : null,
                    decoration: InputDecoration(
                      labelText: 'Cambiar estado',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: _actualizandoEstado
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    items: _estados
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: _actualizandoEstado
                        ? null
                        : (nuevo) {
                            if (nuevo != null) _cambiarEstado(nuevo);
                          },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filaTotal(String etiqueta, String valor, {bool destacado = false}) {
    final estilo = destacado
        ? const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.verde)
        : const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: estilo),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
