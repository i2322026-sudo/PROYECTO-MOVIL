import 'package:flutter/material.dart';
import 'package:movil/services/usuario_service.dart';
// import 'package:movil/services/notificacion_service.dart'; // desactivado para web/Chrome
import 'package:movil/screens/dashboard_screen.dart';
import 'package:movil/screens/verificar_otp_login_screen.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _service = UsuarioService();

  bool _cargando = false;
  bool _verPassword = false;
  String _error = '';

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final correo = _correoCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final resultado = await _service.login(correo, password);
      if (!mounted) return;

      if (resultado.requiereOtp) {
        // Colaborador: falta el paso 2 (código al correo) — no
        // entra al dashboard todavía.
        setState(() => _cargando = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificarOtpLoginScreen(
              pendingLoginId: resultado.pendingLoginId!,
              correo: correo,
            ),
          ),
        );
        return;
      }

      // NotificacionService().inicializar(); // desactivado para web/Chrome
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoVerdeSuave,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ALEVET',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.verde,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 179, 207, 168),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INICIO DE SESIÓN',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ingresa con tu correo registrado',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                CampoTexto(
                  controller: _correoCtrl,
                  hint: 'Correo electrónico',
                  icono: Icons.email_outlined,
                  teclado: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  controller: _passCtrl,
                  hint: 'Contraseña',
                  icono: Icons.lock_outline,
                  oculto: !_verPassword,
                  sufijo: IconButton(
                    icon: Icon(
                      _verPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _verPassword = !_verPassword),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                BotonPrincipal(
                  texto: 'Ingresar',
                  cargando: _cargando,
                  onPressed: _login,
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
