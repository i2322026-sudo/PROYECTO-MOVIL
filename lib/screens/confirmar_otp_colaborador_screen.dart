import 'package:flutter/material.dart';
import 'package:movil/services/colaborador_service.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/utils/validators.dart';

// ─────────────────────────────────────────────────────────────
//  ConfirmarOtpColaboradorScreen — paso 2 de "Nuevo Colaborador".
//  Se muestra después de solicitarCreacion(); el colaborador
//  recién se crea de verdad acá, si el código coincide con el
//  que se mandó al correo. Mismo patrón que verify-otp del
//  registro de clientes.
// ─────────────────────────────────────────────────────────────
class ConfirmarOtpColaboradorScreen extends StatefulWidget {
  final String pendingId;
  final String correo;

  const ConfirmarOtpColaboradorScreen({
    super.key,
    required this.pendingId,
    required this.correo,
  });

  @override
  State<ConfirmarOtpColaboradorScreen> createState() =>
      _ConfirmarOtpColaboradorScreenState();
}

class _ConfirmarOtpColaboradorScreenState
    extends State<ConfirmarOtpColaboradorScreen> {
  final _service = ColaboradorService();
  final _otpCtrl = TextEditingController();
  bool _confirmando = false;
  String? _error;

  Future<void> _confirmar() async {
    if (_otpCtrl.text.trim().length != 5) {
      setState(() => _error = 'Ingresa el código de 5 dígitos');
      return;
    }
    final errorOtp = Validators.otp(_otpCtrl.text);
    if (errorOtp != null) {
      setState(() => _error = errorOtp);
      return;
    }
    setState(() {
      _confirmando = true;
      _error = null;
    });
    try {
      await _service.confirmarCreacion(
        pendingId: widget.pendingId,
        otp: _otpCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _confirmando = false;
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
        title: const Text('Verificar correo'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 48, color: AppColors.verde),
            const SizedBox(height: 16),
            Text(
              'Mandamos un código de 5 dígitos a ${widget.correo}. '
              'Pídeselo al nuevo colaborador y escribilo acá para confirmar '
              'que el correo es real y crear su cuenta.',
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
              texto: 'Confirmar y crear colaborador',
              cargando: _confirmando,
              onPressed: _confirmar,
            ),
          ],
        ),
      ),
    );
  }
}
