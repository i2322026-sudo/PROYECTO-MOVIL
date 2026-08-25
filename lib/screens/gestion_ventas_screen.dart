import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movil/models/venta_model.dart';
import 'package:movil/services/venta_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/screens/detalle_venta_screen.dart';
import 'package:movil/services/pedido_service.dart';

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
  final _pedidoService = PedidoService();

  List<Venta> _ventas = [];
  bool _cargando = true;
  bool _exportando = false;
  String? _error;

  String? _estado; // null = Todos
  DateTime? _desde;
  DateTime? _hasta;
  final _codigoCtrl = TextEditingController();

  // Fecha de HOY en hora de Perú (America/Lima, UTC-5 fijo, sin
  // horario de verano) — mismo criterio que fechaHoyPeru() en la web
  // (public/js/ventas.js). No usa DateTime.now() local del celular
  // directo, para que sea igual sin importar la zona horaria que
  // tenga puesto el dispositivo.
  DateTime _hoyPeru() {
    final ahoraUtc = DateTime.now().toUtc();
    final peru = ahoraUtc.subtract(const Duration(hours: 5));
    return DateTime(peru.year, peru.month, peru.day);
  }

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  // Mismo chequeo que aplicarFiltros()/exportarVentas() en la web:
  // ninguna fecha puede ser futura (hora Perú), y "Desde" no puede ser
  // posterior a "Hasta". Devuelve el mensaje de error, o null si está
  // todo bien.
  String? _validarRangoFechas() {
    final hoy = _hoyPeru();
    if (_desde != null && _soloFecha(_desde!).isAfter(hoy)) {
      return 'La fecha "Desde" no puede ser posterior a hoy.';
    }
    if (_hasta != null && _soloFecha(_hasta!).isAfter(hoy)) {
      return 'La fecha "Hasta" no puede ser posterior a hoy.';
    }
    if (_desde != null &&
        _hasta != null &&
        _soloFecha(_desde!).isAfter(_soloFecha(_hasta!))) {
      return 'La fecha "Desde" no puede ser posterior a la fecha "Hasta".';
    }
    return null;
  }

  // 'activos' o 'historial' — igual que las pestañas de la web.
  String _vista = 'activos';
  // null = Todos, o 'DELIVERY' / 'RECOJO_TIENDA' — igual que los
  // botones de la web.
  String? _tipoEntrega;

  // Mismo criterio que ESTADOS_POR_VISTA en ventas.js: en "activos"
  // solo tiene sentido filtrar por los estados que aún requieren
  // gestión; en "historial" solo por los que ya se cerraron.
  static const _estadosPorVista = {
    'activos': ['PENDIENTE', 'PAGADO', 'ENVIADO'],
    'historial': ['ENTREGADO', 'CANCELADO'],
  };

  // Se incrementa en cada llamada a _cargar(). Si el servidor tarda
  // (cold start de Render puede pasar de 50s), pueden quedar dos
  // peticiones "en el aire" a la vez — la inicial sin filtro y una
  // posterior ya filtrada. Sin esto, la respuesta que llega ÚLTIMO
  // gana y puede pisar el resultado bueno con uno viejo. Guardando
  // el número de la petición actual, se descarta cualquier respuesta
  // que no sea la de la llamada más reciente.
  int _idPeticionActual = 0;

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

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  String? get _desdeStr =>
      _desde == null ? null : _desde!.toIso8601String().split('T').first;
  String? get _hastaStr =>
      _hasta == null ? null : _hasta!.toIso8601String().split('T').first;

  Future<void> _cargar() async {
    // Se captura ANTES del setState/await para que el mensaje de abajo
    // muestre exactamente lo que se envió en esta llamada puntual,
    // sin importar si el usuario sigue escribiendo mientras carga.
    final codigoEnviado = _codigoCtrl.text.trim();

    // Cada llamada a _cargar() recibe su propio número. Al terminar,
    // solo se aplica el resultado si nadie más volvió a llamar a
    // _cargar() mientras tanto (si _idPeticionActual cambió, esta
    // respuesta ya quedó vieja y se ignora).
    final idEstaPeticion = ++_idPeticionActual;

    // Mismo chequeo que hace la web antes de filtrar: si el rango de
    // fechas no es válido, ni siquiera se llama al servidor.
    final errorFechas = _validarRangoFechas();
    if (errorFechas != null) {
      setState(() {
        _error = errorFechas;
        _cargando = false;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ventas = await _service.listar(
        estado: _estado,
        desde: _desdeStr,
        hasta: _hastaStr,
        codigo: codigoEnviado,
        tipoEntrega: _tipoEntrega,
        vista: _vista,
      );

      // ── Descartar si ya no es la petición más reciente ──
      // Ejemplo real: la carga inicial sin filtro (initState) puede
      // tardar por el cold start de Render; si mientras tanto ya se
      // presionó "Filtrar", esa respuesta vieja llega después y no
      // debe pisar el resultado filtrado que sí es el que importa.
      if (idEstaPeticion != _idPeticionActual) return;

      // ── Filtro de respaldo, del lado de la app ──
      // El servidor YA filtra por código, vista y tipo de entrega
      // (venta.model.js), pero por seguridad se vuelve a filtrar aquí
      // antes de mostrar: si por cualquier motivo la respuesta trae de
      // más (ej. el servidor no aplicó bien el filtro de tipo de
      // entrega — bug real que hubo: la consulta de la lista no
      // seleccionaba tipo_entrega y el WHERE tampoco se aplicaba
      // correctamente), la pantalla solo muestra lo que de verdad
      // corresponde a la pestaña, el código y el tipo de entrega
      // elegido. Nunca deja pasar un resultado que no debería estar ahí.
      final estadosValidos = _estadosPorVista[_vista]!;
      final ventasFiltradas = ventas.where((v) {
        final pasaVista = estadosValidos.contains(v.estado);
        final pasaCodigo = codigoEnviado.isEmpty ||
            v.comprobante.toUpperCase().contains(codigoEnviado.toUpperCase());
        final pasaTipoEntrega =
            _tipoEntrega == null || v.tipoEntrega == _tipoEntrega;
        return pasaVista && pasaCodigo && pasaTipoEntrega;
      }).toList();

      setState(() {
        _ventas = ventasFiltradas;
        _cargando = false;
      });
    } catch (e) {
      // Igual aquí: un error de una petición vieja tampoco debe
      // mostrarse si ya hay una más nueva en curso.
      if (idEstaPeticion != _idPeticionActual) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  // Al cambiar de pestaña, si el estado filtrado ya no pertenece a la
  // nueva vista (ej. tenías "CANCELADO" filtrado y vuelves a
  // "Activos"), se limpia — mismo criterio que pintarOpcionesEstado()
  // en la web, que reconstruye el <select> desde cero.
  void _cambiarVista(String vista) {
    setState(() {
      _vista = vista;
      if (_estado != null && !_estadosPorVista[vista]!.contains(_estado)) {
        _estado = null;
      }
    });
    _cargar();
  }

  void _cambiarTipoEntrega(String? tipo) {
    setState(() => _tipoEntrega = tipo);
    _cargar();
  }

  Future<void> _exportarExcel() async {
    final errorFechas = _validarRangoFechas();
    if (errorFechas != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorFechas)));
      return;
    }
    setState(() => _exportando = true);
    try {
      final bytes = await _service.exportarExcel(
        estado: _estado,
        desde: _desdeStr,
        hasta: _hastaStr,
        codigo: _codigoCtrl.text,
        tipoEntrega: _tipoEntrega,
        vista: _vista,
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
    final hoy = _hoyPeru();
    final inicial = esDesde ? (_desde ?? hoy) : (_hasta ?? hoy);
    // Mismo rango que la web (public/ventas.html): desde 2026-01-01
    // hasta hoy en hora de Perú — nunca deja elegir una fecha futura.
    final inicialAcotada =
        inicial.isAfter(hoy) ? hoy : (inicial.isBefore(DateTime(2026, 1, 1)) ? DateTime(2026, 1, 1) : inicial);
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicialAcotada,
      firstDate: DateTime(2026, 1, 1),
      lastDate: hoy,
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

  Future<void> _cambiarEstado(Venta v, String nuevoEstado) async {
    try {
      await _pedidoService.actualizarEstado(v.idPedido, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${v.idPedido} → $nuevoEstado')),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'PAGADO':
        return Colors.blue;
      case 'ENVIADO':
        return Colors.indigo;
      case 'ENTREGADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
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
              : IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Exportar Excel',
                  onPressed: _exportarExcel,
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Pestañas: Activos / Historial — igual que la web ──
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _botonPestana(
                    'Activos',
                    Icons.hourglass_top,
                    activo: _vista == 'activos',
                    onTap: () => _cambiarVista('activos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _botonPestana(
                    'Historial',
                    Icons.inventory_2_outlined,
                    activo: _vista == 'historial',
                    onTap: () => _cambiarVista('historial'),
                  ),
                ),
              ],
            ),
          ),
          // ── Filtro rápido: Todos / Delivery / Recojo en Tienda ──
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _botonTipoEntrega('Todos', null),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _botonTipoEntrega('Delivery', 'DELIVERY',
                      icono: Icons.local_shipping_outlined),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _botonTipoEntrega('Recojo en Tienda', 'RECOJO_TIENDA',
                      icono: Icons.storefront_outlined),
                ),
              ],
            ),
          ),
          // ── Filtros: Código / Estado / Desde / Hasta — los 4 juntos
          //    en una cuadrícula 2x2 en vez de uno debajo del otro,
          //    para que ocupen menos espacio vertical.
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('N° BOLETA/FACTURA',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _codigoCtrl,
                            enabled: !_cargando,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: 'Ej. B001-69',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              prefixIcon: Icon(Icons.search, size: 18),
                            ),
                            // Igual que "Filtrar": solo dispara la
                            // búsqueda al enviar, no en cada tecla
                            // (evita golpear la API por cada letra,
                            // sobre todo con el cold start de Render).
                            onSubmitted: (_) => _cargar(),
                            textInputAction: TextInputAction.search,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ESTADO',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String?>(
                            initialValue: _estado,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Todos')),
                              // Solo los estados de la pestaña activa —
                              // igual que pintarOpcionesEstado() en
                              // ventas.js.
                              ..._estadosPorVista[_vista]!.map((e) =>
                                  DropdownMenuItem(
                                      value: e, child: Text(e))),
                            ],
                            onChanged: (v) => setState(() => _estado = v),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    // Deshabilitado mientras carga: así es imposible que
                    // se disparen dos peticiones al mismo tiempo (la
                    // causa real de que a veces "ganara" la respuesta
                    // vieja sin filtro). El usuario tiene que esperar a
                    // que termine la consulta anterior antes de filtrar
                    // de nuevo.
                    onPressed: _cargando ? null : _cargar,
                    icon: _cargando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.filter_alt_outlined, size: 18),
                    label: Text(_cargando ? 'Buscando...' : 'Filtrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verde,
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
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetalleVentaScreen(idPedido: v.idPedido),
                          ),
                        ),
                        child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pedido #${v.idPedido}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Row(
                                  children: [
                                    // Badge de entrega — mismo criterio de
                                    // color que el modal de detalle.
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: v.tipoEntrega == 'RECOJO_TIENDA'
                                            ? Colors.grey.shade300
                                            : AppColors.verde
                                                .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        v.tipoEntrega == 'RECOJO_TIENDA'
                                            ? 'Recojo'
                                            : 'Delivery',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: v.tipoEntrega ==
                                                  'RECOJO_TIENDA'
                                              ? Colors.grey.shade800
                                              : AppColors.verde,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(v.tipo,
                                          style:
                                              const TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(v.comprobante,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 6),
                            Text(v.cliente),
                            Text(_fmtFecha(v.fecha),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('S/. ${v.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.verde,
                                    fontWeight: FontWeight.bold)),
                            Text(v.metodoPago,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  _estados.contains(v.estado) ? v.estado : null,
                              decoration: const InputDecoration(
                                labelText: 'Cambiar estado',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: _estados
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (nuevo) {
                                if (nuevo != null) _cambiarEstado(v, nuevo);
                              },
                            ),
                          ],
                        ),
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

  // ── Botón de pestaña Activos/Historial ──
  Widget _botonPestana(String texto, IconData icono,
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

  // ── Botón del filtro rápido Todos/Delivery/Recojo ──
  Widget _botonTipoEntrega(String texto, String? valor, {IconData? icono}) {
    final activo = _tipoEntrega == valor;
    return OutlinedButton.icon(
      onPressed: () => _cambiarTipoEntrega(valor),
      icon: icono == null
          ? const SizedBox.shrink()
          : Icon(icono, size: 14, color: activo ? Colors.white : AppColors.verde),
      label: Text(texto, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        backgroundColor: activo ? AppColors.verde : Colors.white,
        foregroundColor: activo ? Colors.white : AppColors.verde,
        side: BorderSide(color: AppColors.verde),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
