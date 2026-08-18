import 'package:flutter/material.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  BotonPrincipal — botón verde de ancho completo con spinner
//  de carga integrado. Mismo estilo que se repetía en Login,
//  NuevoProducto, NuevoColaborador, etc.
// ─────────────────────────────────────────────────────────────
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback? onPressed;
  final double height;
  final double elevation;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.height = 52,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
