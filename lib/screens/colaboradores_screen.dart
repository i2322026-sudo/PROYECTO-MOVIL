import 'package:flutter/material.dart';
import 'package:movil/models/colaborador_model.dart';
import 'package:movil/services/colaborador_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/screens/nuevo_colaborador_screen.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/widgets/exportar_menu_button.dart';
import 'package:movil/widgets/campo_texto.dart';

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

  // Igual que "Mi perfil": PASO 1 pide contraseña actual + nueva +
  // confirmación y manda el código OTP al correo del colaborador.
  // PASO 2 pide ese código y recién ahí se guarda la nueva contraseña.
  Future<void> _resetearPassword(Colaborador c) async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();
    String? error;
    bool enviando = false;

    final pendingId = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Cambiar contraseña de ${c.nombreCompleto}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Para autorizar el cambio, confirma TU contraseña '
                    '(la de tu propia sesión), no la de este colaborador.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                CampoTexto(
                    controller: actualCtrl,
                    hint: 'Tu contraseña',
                    icono: Icons.lock_outline,
                    oculto: true),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: nuevaCtrl,
                    hint: 'Contraseña nueva',
                    icono: Icons.lock_reset,
                    oculto: true),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('Mínimo 8 caracteres, con letras y números',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: confirmarCtrl,
                    hint: 'Confirmar contraseña',
                    icono: Icons.lock_reset,
                    oculto: true),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (actualCtrl.text.isEmpty) {
                        setStateDialog(
                            () => error = 'Ingresa la contraseña actual');
                        return;
                      }
                      if (nuevaCtrl.text.isEmpty) {
                        setStateDialog(
                            () => error = 'Ingresa la nueva contraseña');
                        return;
                      }
                      if (nuevaCtrl.text != confirmarCtrl.text) {
                        setStateDialog(
                            () => error = 'Las contraseñas no coinciden');
                        return;
                      }
                      setStateDialog(() {
                        enviando = true;
                        error = null;
                      });
                      try {
                        final id = await _service.solicitarResetPassword(
                          id: c.idColaborador,
                          passwordActual: actualCtrl.text,
                          passwordNueva: nuevaCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, id);
                      } catch (e) {
                        setStateDialog(() {
                          enviando = false;
                          error = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar código'),
            ),
          ],
        ),
      ),
    );

    if (pendingId == null || !mounted) return;

    // PASO 2: pide el código que llegó al correo del colaborador.
    final otpCtrl = TextEditingController();
    String? errorOtp;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Verificar código'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ingresa el código de 5 dígitos enviado al correo '
                  'de ${c.nombreCompleto}.'),
              const SizedBox(height: 12),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: const InputDecoration(labelText: 'Código OTP'),
              ),
              if (errorOtp != null) ...[
                const SizedBox(height: 8),
                Text(errorOtp!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                if (otpCtrl.text.trim().length != 5) {
                  setStateDialog(
                      () => errorOtp = 'Ingresa el código de 5 dígitos');
                  return;
                }
                try {
                  await _service.confirmarResetPassword(
                    id: c.idColaborador,
                    pendingId: pendingId,
                    otp: otpCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setStateDialog(() => errorOtp =
                      e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (confirmado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada correctamente')));
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
        actions: [
          const ExportarMenuButton(
              entidad: 'colaboradores', nombreArchivo: 'colaboradores'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo Colaborador',
            onPressed: () async {
              final creado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => const NuevoColaboradorScreen()),
              );
              if (creado == true) _cargar();
            },
          ),
        ],
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
    );
  }
}
