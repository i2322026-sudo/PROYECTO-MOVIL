import 'package:flutter/material.dart';
import 'package:movil/screens/evidencia_cancelacion_screen.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  GestionEvidenciasScreen — antes tenía 2 pestañas (Registrar/
//  Historial). Se quitó "Historial" porque tiraba
//  "TypeError: _JsonMap is not a subtype of List<dynamic>"
//  (el endpoint /api/pedidos/con-evidencia no devolvía la forma
//  esperada) — en vez de dejar el error visible, se removió el
//  historial por completo y esta pantalla vuelve a ser solo el
//  formulario de "Registrar" (buscar por código + foto + cancelar),
//  con su propio Scaffold/AppBar.
// ─────────────────────────────────────────────────────────────
class GestionEvidenciasScreen extends StatelessWidget {
  const GestionEvidenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidencia de Cancelación'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: const EvidenciaCancelacionScreen(),
    );
  }
}
