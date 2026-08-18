import 'package:flutter/material.dart';
import 'package:movil/models/colaborador_model.dart';
import 'package:movil/services/colaborador_service.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/screens/confirmar_otp_colaborador_screen.dart';

// ─────────────────────────────────────────────────────────────
//  NuevoColaboradorScreen — crear (POST) o editar (PUT) un
//  colaborador. Calcada del modal de la web (dashboard.js:
//  mostrarModalColaborador / editarColaborador):
//
//   - Crear: pide correo, DNI y contraseña (obligatorios).
//   - Editar: correo y DNI se muestran de solo lectura (el
//     backend PUT /:id NO los actualiza — solo nombres,
//     apellidos, teléfono, cargo, usuario y estado), y aparece
//     el selector de Estado (Activo/Inactivo) — que es la única
//     forma de "dar de baja" a un colaborador: no existe un
//     endpoint de eliminar, ni en la web ni en el backend, solo
//     desactivar (mismo criterio que Productos: se desactiva
//     primero antes de poder tocar cualquier baja).
// ─────────────────────────────────────────────────────────────
class NuevoColaboradorScreen extends StatefulWidget {
  final Colaborador? existente;

  const NuevoColaboradorScreen({super.key, this.existente});

  @override
  State<NuevoColaboradorScreen> createState() =>
      _NuevoColaboradorScreenState();
}

class _NuevoColaboradorScreenState extends State<NuevoColaboradorScreen> {
  final _service = ColaboradorService();

  late final _nombresCtrl =
      TextEditingController(text: widget.existente?.nombres ?? '');
  late final _apPaternoCtrl =
      TextEditingController(text: widget.existente?.apellidoPaterno ?? '');
  late final _apMaternoCtrl =
      TextEditingController(text: widget.existente?.apellidoMaterno ?? '');
  late final _dniCtrl =
      TextEditingController(text: widget.existente?.dni ?? '');
  late final _usuarioCtrl =
      TextEditingController(text: widget.existente?.usuario ?? '');
  late final _correoCtrl =
      TextEditingController(text: widget.existente?.correo ?? '');
  late final _telefonoCtrl =
      TextEditingController(text: widget.existente?.telefono ?? '');
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  List<Cargo> _cargos = [];
  int? _idCargo;
  String _estado = 'ACTIVO';
  bool _cargandoCargos = true;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    _idCargo = widget.existente?.idCargo;
    _estado = widget.existente?.estado ?? 'ACTIVO';
    _cargarCargos();
  }

  Future<void> _cargarCargos() async {
    try {
      final cargos = await _service.getCargos();
      setState(() {
        _cargos = cargos;
        _idCargo ??= cargos.isNotEmpty ? cargos.first.idCargo : null;
        _cargandoCargos = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargandoCargos = false;
      });
    }
  }

  Future<void> _guardar() async {
    final camposBase = _nombresCtrl.text.trim().isEmpty ||
        _usuarioCtrl.text.trim().isEmpty ||
        _idCargo == null;
    final camposCreacion = !_esEdicion &&
        (_correoCtrl.text.trim().isEmpty ||
            _passwordCtrl.text.isEmpty ||
            _dniCtrl.text.trim().isEmpty);

    if (camposBase || camposCreacion) {
      setState(() => _error = 'Completa todos los campos obligatorios');
      return;
    }

    // Igual que la web (guardarColaborador → si (pass !== pass2)):
    // valida que las dos contraseñas coincidan antes de crear.
    if (!_esEdicion && _passwordCtrl.text != _password2Ctrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      if (_esEdicion) {
        await _service.actualizarColaborador(
          id: widget.existente!.idColaborador,
          nombres: _nombresCtrl.text.trim(),
          apellidoPaterno: _apPaternoCtrl.text.trim(),
          apellidoMaterno: _apMaternoCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          idCargo: _idCargo!,
          usuario: _usuarioCtrl.text.trim(),
          estado: _estado,
        );
      } else {
        // Ya no crea el colaborador directo — pide el código OTP
        // primero, para no poder cargar un correo inventado.
        final pendingId = await _service.solicitarCreacion(
          nombres: _nombresCtrl.text.trim(),
          apellidoPaterno: _apPaternoCtrl.text.trim(),
          apellidoMaterno: _apMaternoCtrl.text.trim(),
          correo: _correoCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          password: _passwordCtrl.text,
          dni: _dniCtrl.text.trim(),
          idCargo: _idCargo!,
          usuario: _usuarioCtrl.text.trim(),
        );
        if (!mounted) return;
        final creado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmarOtpColaboradorScreen(
              pendingId: pendingId,
              correo: _correoCtrl.text.trim(),
            ),
          ),
        );
        setState(() => _guardando = false);
        if (creado == true && mounted) Navigator.pop(context, true);
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _guardando = false;
      });
    }
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _dniCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Colaborador' : 'Nuevo Colaborador'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
      ),
      body: _cargandoCargos
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CampoTexto(
                    controller: _nombresCtrl,
                    hint: 'Nombres',
                    icono: Icons.person_outline),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _apPaternoCtrl,
                    hint: 'Apellido paterno',
                    icono: Icons.badge_outlined),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _apMaternoCtrl,
                    hint: 'Apellido materno',
                    icono: Icons.badge_outlined),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _dniCtrl,
                    hint: 'DNI',
                    icono: Icons.credit_card,
                    teclado: TextInputType.number,
                    // El backend no permite editar el DNI desde
                    // PUT /:id (mismo criterio que la web).
                    soloLectura: _esEdicion),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _telefonoCtrl,
                    hint: 'Teléfono',
                    icono: Icons.phone_outlined,
                    teclado: TextInputType.phone),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _correoCtrl,
                    hint: 'Correo',
                    icono: Icons.email_outlined,
                    teclado: TextInputType.emailAddress,
                    // Igual que el DNI: el backend no lo actualiza
                    // en la edición, solo se muestra de referencia.
                    soloLectura: _esEdicion),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _usuarioCtrl,
                    hint: 'Usuario',
                    icono: Icons.alternate_email),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _idCargo,
                  decoration: const InputDecoration(
                    labelText: 'Cargo',
                    border: OutlineInputBorder(),
                  ),
                  items: _cargos
                      .map((c) => DropdownMenuItem(
                          value: c.idCargo, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _idCargo = v),
                ),
                if (!_esEdicion) ...[
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _passwordCtrl,
                      hint: 'Contraseña',
                      icono: Icons.lock_outline,
                      oculto: true),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Mínimo 8 caracteres, con letras y números',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _password2Ctrl,
                      hint: 'Confirmar Contraseña',
                      icono: Icons.lock_outline,
                      oculto: true),
                ],
                if (_esEdicion) ...[
                  const SizedBox(height: 12),
                  // Única forma de dar de baja a un colaborador:
                  // no hay "eliminar", solo activar/desactivar
                  // (igual que Productos).
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                      DropdownMenuItem(
                          value: 'INACTIVO', child: Text('Inactivo')),
                    ],
                    onChanged: (v) => setState(() => _estado = v ?? 'ACTIVO'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                BotonPrincipal(
                  texto: _esEdicion ? 'Guardar cambios' : 'Enviar código de verificación',
                  cargando: _guardando,
                  onPressed: _guardar,
                ),
              ],
            ),
    );
  }
}
