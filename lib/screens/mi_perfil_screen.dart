import 'package:flutter/material.dart';
import 'package:movil/services/usuario_service.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';

// ─────────────────────────────────────────────────────────────
//  MiPerfilScreen — GET /api/auth/perfil, PUT
//  /api/auth/actualizar-perfil y PUT /api/auth/cambiar-password.
//  Las tres rutas existen de verdad en auth.routes.js.
// ─────────────────────────────────────────────────────────────
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  final _service = UsuarioService();

  final _nombresCtrl = TextEditingController();
  final _apPaternoCtrl = TextEditingController();
  final _apMaternoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  bool _cambiandoPassword = false;
  String? _error;
  String? _correo;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _service.getPerfil();
      setState(() {
        _nombresCtrl.text = datos['nombres'] ?? '';
        _apPaternoCtrl.text = datos['apellido_paterno'] ?? '';
        _apMaternoCtrl.text = datos['apellido_materno'] ?? '';
        _telefonoCtrl.text = datos['telefono'] ?? '';
        _correo = datos['correo'];
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _service.actualizarPerfil(
        nombres: _nombresCtrl.text.trim(),
        apellidoPaterno: _apPaternoCtrl.text.trim(),
        apellidoMaterno: _apMaternoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      setState(() => _guardando = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _guardando = false;
      });
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passActualCtrl.text.isEmpty || _passNuevaCtrl.text.isEmpty) return;
    setState(() {
      _cambiandoPassword = true;
      _error = null;
    });
    try {
      final resultado = await _service.cambiarPassword(
        passwordActual: _passActualCtrl.text,
        passwordNueva: _passNuevaCtrl.text,
      );

      if (resultado.requiereOtp) {
        setState(() => _cambiandoPassword = false);
        if (!mounted) return;
        await _pedirOtpYConfirmar(resultado.pendingId!);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada correctamente')));
      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      setState(() => _cambiandoPassword = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cambiandoPassword = false;
      });
    }
  }

  /// Paso 2, EN CADA cambio de contraseña de colaborador: pide el
  /// código de 6 dígitos con un diálogo (no hace falta pantalla
  /// aparte, es un paso corto).
  Future<void> _pedirOtpYConfirmar(String pendingId) async {
    final otpCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificación requerida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingresa el código de 6 dígitos enviado a $_correo',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 5,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 6),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '00000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmado != true) return;
    if (!mounted) return;

    setState(() => _cambiandoPassword = true);
    try {
      await _service.verificarOtpCambioPassword(
        pendingId: pendingId,
        otp: otpCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada correctamente')));
      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      setState(() => _cambiandoPassword = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cambiandoPassword = false;
      });
    }
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _telefonoCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_correo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_correo!,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
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
                    controller: _telefonoCtrl,
                    hint: 'Teléfono',
                    icono: Icons.phone_outlined,
                    teclado: TextInputType.phone),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 18),
                BotonPrincipal(
                  texto: 'Guardar cambios',
                  cargando: _guardando,
                  onPressed: _guardarPerfil,
                ),
                const Divider(height: 40),
                const Text('Cambiar contraseña',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                CampoTexto(
                    controller: _passActualCtrl,
                    hint: 'Contraseña actual',
                    icono: Icons.lock_outline,
                    oculto: true),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _passNuevaCtrl,
                    hint: 'Contraseña nueva',
                    icono: Icons.lock_reset,
                    oculto: true),
                const SizedBox(height: 18),
                BotonPrincipal(
                  texto: 'Cambiar contraseña',
                  cargando: _cambiandoPassword,
                  onPressed: _cambiarPassword,
                ),
              ],
            ),
    );
  }
}
