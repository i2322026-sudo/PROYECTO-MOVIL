import 'package:flutter/material.dart';
import 'package:movil/models/cliente_model.dart';
import 'package:movil/services/cliente_service.dart';
import 'package:movil/widgets/estado_lista.dart';

// ─────────────────────────────────────────────────────────────
//  ClientesScreen — mismas columnas que "Clientes Registrados"
//  del panel web: nombre, correo, teléfono, documento, fecha.
//  Filtro por rango de fecha de registro (Día/Semana/Quincena/
//  Mes/Año), igual patrón que Gestión de Pedidos — se aplica en
//  la app sobre la lista ya cargada, sin tocar el backend.
// ─────────────────────────────────────────────────────────────
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

enum _RangoCliente { todos, dia, semana, quincena, mes, anio }

class _ClientesScreenState extends State<ClientesScreen> {
  final _service = ClienteService();
  List<Cliente> _clientes = [];
  bool _cargando = true;
  String? _error;
  _RangoCliente _rango = _RangoCliente.todos;

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

  /// Clientes cuya fecha de registro cae dentro del rango elegido.
  List<Cliente> get _clientesFiltrados {
    if (_rango == _RangoCliente.todos) return _clientes;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    late DateTime desde;
    switch (_rango) {
      case _RangoCliente.dia:
        desde = hoy;
        break;
      case _RangoCliente.semana:
        desde = hoy.subtract(const Duration(days: 7));
        break;
      case _RangoCliente.quincena:
        desde = hoy.subtract(const Duration(days: 15));
        break;
      case _RangoCliente.mes:
        desde = hoy.subtract(const Duration(days: 30));
        break;
      case _RangoCliente.anio:
        desde = hoy.subtract(const Duration(days: 365));
        break;
      case _RangoCliente.todos:
        desde = DateTime(2000);
    }
    return _clientes.where((c) {
      final f = c.fechaRegistro == null
          ? null
          : DateTime.tryParse(c.fechaRegistro!);
      return f != null && !f.isBefore(desde);
    }).toList();
  }

  String get _mensajeVacioRango {
    switch (_rango) {
      case _RangoCliente.todos:
        return 'No hay clientes registrados';
      default:
        return 'No hay clientes registrados en este rango de fechas';
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '-';
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return fecha;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _eliminar(Cliente c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
            '¿Eliminar a ${c.nombres} definitivamente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.eliminarCliente(c.idPersona);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
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
    final clientesFiltrados = _clientesFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes Registrados'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipRango('Todos', _RangoCliente.todos),
                  const SizedBox(width: 6),
                  _chipRango('Día', _RangoCliente.dia),
                  const SizedBox(width: 6),
                  _chipRango('Semana', _RangoCliente.semana),
                  const SizedBox(width: 6),
                  _chipRango('Quincena', _RangoCliente.quincena),
                  const SizedBox(width: 6),
                  _chipRango('Mes', _RangoCliente.mes),
                  const SizedBox(width: 6),
                  _chipRango('Año', _RangoCliente.anio),
                ],
              ),
            ),
          ),
          Expanded(
            child: EstadoLista(
              cargando: _cargando,
              error: _error,
              vacio: clientesFiltrados.isEmpty,
              mensajeVacio: _mensajeVacioRango,
              onReintentar: _cargar,
              builder: () => RefreshIndicator(
                onRefresh: _cargar,
                child: ListView.builder(
                  itemCount: clientesFiltrados.length,
                  itemBuilder: (ctx, i) {
                    final c = clientesFiltrados[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF1B9B5E).withOpacity(0.12),
                          child: Text(
                            c.nombres.isNotEmpty
                                ? c.nombres[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Color(0xFF1B9B5E),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c.nombres,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatearFecha(c.fechaRegistro),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              tooltip: 'Eliminar',
                              onPressed: () => _eliminar(c),
                            ),
                          ],
                        ),
                        isThreeLine: true,
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

  Widget _chipRango(String texto, _RangoCliente valor) {
    final seleccionado = _rango == valor;
    return ChoiceChip(
      label: Text(texto),
      selected: seleccionado,
      onSelected: (_) => setState(() => _rango = valor),
      selectedColor: const Color(0xFF1B9B5E),
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : Colors.black87,
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
