import 'package:flutter/material.dart';
import 'package:movil/models/cliente_model.dart';
import 'package:movil/services/cliente_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/widgets/exportar_menu_button.dart';

// ─────────────────────────────────────────────────────────────
//  ClientesScreen — misma estructura que "Clientes Registrados"
//  del panel web (dashboard.js -> cargarClientes/toggleCliente):
//  nombre, correo, teléfono, documento, fecha, badge de Estado
//  (ACTIVO/INACTIVO) y botón Activar/Desactivar.
//
//  Antes tenía un filtro por rango de fecha (Día/Semana/Quincena/
//  Mes/Año) que NO existe en la web — se quitó para que ambas
//  pantallas queden con la misma estructura.
// ─────────────────────────────────────────────────────────────
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _service = ClienteService();
  List<Cliente> _clientes = [];
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
      final lista = await _service.getClientes();
      setState(() {
        _clientes = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '-';
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return fecha;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Activar/Desactivar — mismo texto de confirmación que
  /// toggleCliente() en dashboard.js.
  Future<void> _toggleEstado(Cliente c) async {
    final activando = c.estado == 'INACTIVO';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activando ? 'Activar cliente' : 'Desactivar cliente'),
        content: Text(
          activando
              ? '¿Reactivar a "${c.nombres}"? Podrá iniciar sesión y comprar de nuevo.'
              : '¿Desactivar a "${c.nombres}"? No podrá iniciar sesión ni hacer nuevos pedidos, pero su historial de compras se conserva.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(activando ? 'Sí, activar' : 'Sí, desactivar',
                style: TextStyle(
                    color: activando ? Colors.green : Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.cambiarEstado(
          c.idPersona, activando ? 'ACTIVO' : 'INACTIVO');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Cliente ${activando ? 'activado' : 'desactivado'} correctamente')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes Registrados'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: const [
          ExportarMenuButton(entidad: 'clientes', nombreArchivo: 'clientes'),
        ],
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _clientes.isEmpty,
        mensajeVacio: 'No hay clientes registrados',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _clientes.length,
            itemBuilder: (ctx, i) {
              final c = _clientes[i];
              final inactivo = c.estado == 'INACTIVO';
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.verde.withOpacity(0.12),
                            child: Text(
                              c.nombres.isNotEmpty
                                  ? c.nombres[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.verde,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.nombres,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (c.correo != null) Text(c.correo!),
                                Row(
                                  children: [
                                    Text(c.telefono ?? '-'),
                                    const SizedBox(width: 12),
                                    Text('Doc: ${c.numeroDocumento ?? "-"}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatearFecha(c.fechaRegistro),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Badge de Estado — mismo criterio de color
                          // que la web (verde=ACTIVO, gris=INACTIVO).
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: inactivo
                                  ? Colors.grey.shade300
                                  : AppColors.verde,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c.estado,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    inactivo ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _toggleEstado(c),
                            icon: Icon(
                              inactivo
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 16,
                            ),
                            label: Text(inactivo ? 'Activar' : 'Desactivar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  inactivo ? AppColors.verde : Colors.orange,
                              side: BorderSide(
                                color: inactivo
                                    ? AppColors.verde
                                    : Colors.orange,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
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
    );
  }
}
