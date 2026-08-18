import 'package:flutter/material.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  CampoTexto — campo de formulario reutilizable con el mismo
//  estilo visual que se usaba en el login (fondo gris claro,
//  bordes redondeados, ícono a la izquierda).
//
//  Antes vivía como un método privado _campo() dentro de
//  LoginScreen; ahora cualquier pantalla puede usarlo.
// ─────────────────────────────────────────────────────────────
class CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icono;
  final TextInputType teclado;
  final bool oculto;
  final Widget? sufijo;
  final bool soloLectura;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.hint,
    required this.icono,
    this.teclado = TextInputType.text,
    this.oculto = false,
    this.sufijo,
    this.soloLectura = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: oculto,
      keyboardType: teclado,
      readOnly: soloLectura,
      style: soloLectura ? TextStyle(color: Colors.grey.shade600) : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor:
            soloLectura ? Colors.grey.shade200 : AppColors.fondoClaro,
        prefixIcon: Icon(icono),
        suffixIcon: sufijo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
