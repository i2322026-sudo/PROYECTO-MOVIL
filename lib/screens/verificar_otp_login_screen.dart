import 'package:flutter/material.dart';
import 'package:movil/services/usuario_service.dart';
import 'package:movil/screens/dashboard_screen.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  VerificarOtpLoginScreen — paso 2 del login, EN CADA INGRESO
//  (no solo al crear la cuenta). Se muestra después de que
//  usuario_service.login() responde requiereOtp:true. El token
//  real recién se entrega acá si el código coincide.
// ─────────────────────────────────────────────────────────────
class VerificarOtpLoginScreen extends StatefulWidget {
  final String pendingLoginId;
  final String correo;

  const VerificarOtpLoginScreen({
    super.key,
    required this.pendingLoginId,
    required this.correo,
  });

  @override
  State<VerificarOtpLoginScreen> createState() =>
      _VerificarOtpLoginScreenState();
}

class _VerificarOtpLoginScreenState extends State<VerificarOtpLoginScreen> {
  final _service = UsuarioService();
  final _otpCtrl = TextEditingController();
  bool _verificando = false;
  String? _error;

  Future<void> _verificar() async {
    if (_otpCtrl.text.trim().length != 5) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }
    setState(() {
      _verificando = true;
      _error = null;
    });
    try {
      await _service.verificarOtpLogin(
        pendingLoginId: widget.pendingLoginId,
        otp: _otpCtrl.text.trim(),
        correo: widget.correo,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _verificando = false;
      });
    }
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de ingreso'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 48, color: AppColors.verde),
            const SizedBox(height: 16),
            Text(
              'Por seguridad, mandamos un código de 6 dígitos a ${widget.correo}. '
              'Escribilo para completar el ingreso.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 5,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '00000',
                filled: true,
                fillColor: AppColors.fondoClaro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            BotonPrincipal(
              texto: 'Verificar e ingresar',
              cargando: _verificando,
              onPressed: _verificar,
            ),
          ],
        ),
      ),
    );
  }
}
