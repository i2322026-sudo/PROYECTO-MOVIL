import 'package:flutter/material.dart';
import 'package:movil/models/colaborador_model.dart';
import 'package:movil/services/colaborador_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/screens/nuevo_colaborador_screen.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  ColaboradoresScreen — GET /api/colaboradores (lista real,
//  con nombre completo, cargo y estado) + acceso a "Nuevo
//  Colaborador" y reseteo de contraseña.
// ─────────────────────────────────────────────────────────────
class ColaboradoresScreen extends StatefulWidget {
  const ColaboradoresScreen({super.key});

  @override
  State<ColaboradoresScreen> createState() => _ColaboradoresScreenState();
}

class _ColaboradoresScreenState extends State<ColaboradoresScreen> {
  final _service = ColaboradorService();
  List<Colaborador> _colaboradores = [];
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
      final lista = await _service.getColaboradores();
      setState(() {
        _colaboradores = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _resetearPassword(Colaborador c) async {
    final ctrl = TextEditingController();
    final nueva = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restablecer contraseña de ${c.nombreCompleto}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña nueva',
            helperText: 'Mínimo 8 caracteres, con letras y números',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Restablecer')),
        ],
      ),
    );
    if (nueva == null || nueva.trim().isEmpty) return;

    try {
      await _service.resetPassword(c.idColaborador, nueva.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña restablecida')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _eliminar(Colaborador c) async {
    if (c.estado == 'ACTIVO') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'No se puede eliminar un colaborador activo. Desactívalo primero (editar → Estado → Inactivo).'),
      ));
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar colaborador'),
        content: Text(
            '¿Eliminar a ${c.nombreCompleto} definitivamente? Esta acción no se puede deshacer.'),
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
      await _service.eliminarColaborador(c.idColaborador);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Colaborador eliminado')));
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
        title: const Text('Colaboradores'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _colaboradores.isEmpty,
        mensajeVacio: 'No hay colaboradores registrados',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            itemCount: _colaboradores.length,
            itemBuilder: (ctx, i) {
              final c = _colaboradores[i];
              return ListTile(
                onTap: () async {
                  final editado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NuevoColaboradorScreen(existente: c),
                    ),
                  );
                  if (editado == true) _cargar();
                },
                leading: CircleAvatar(
                  backgroundColor: AppColors.verde.withOpacity(0.12),
                  child: const Icon(Icons.badge_outlined,
                      color: AppColors.verde),
                ),
                title: Text(c.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c.cargo ?? "Sin cargo"} · ${c.correo ?? ""}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (c.estado == 'ACTIVO'
                                ? Colors.green
                                : Colors.grey)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c.estado,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.estado == 'ACTIVO'
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (v) async {
                        if (v == 'editar') {
                          final editado = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NuevoColaboradorScreen(existente: c),
                            ),
                          );
                          if (editado == true) _cargar();
                        }
                        if (v == 'password') _resetearPassword(c);
                        if (v == 'eliminar') _eliminar(c);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Editar / Activar-Desactivar'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'password',
                          child: Row(children: [
                            Icon(Icons.password, size: 18),
                            SizedBox(width: 8),
                            Text('Restablecer contraseña'),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'eliminar',
                          enabled: c.estado != 'ACTIVO',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 18,
                                color: c.estado != 'ACTIVO'
                                    ? Colors.red
                                    : Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(
                                color: c.estado != 'ACTIVO'
                                    ? Colors.red
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.verde,
        onPressed: () async {
          final creado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NuevoColaboradorScreen()),
          );
          if (creado == true) _cargar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
