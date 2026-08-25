import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  CampoTexto — campo de formulario reutilizable con el mismo
//  estilo visual que se usaba en el login (fondo gris claro,
//  bordes redondeados, ícono a la izquierda).
//
//  errorText / onFocusLost / inputFormatters son OPCIONALES —
//  si una pantalla no los usa, el campo se ve y comporta
//  exactamente igual que antes.
// ─────────────────────────────────────────────────────────────
class CampoTexto extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icono;
  final TextInputType teclado;
  final bool oculto;
  final Widget? sufijo;
  final bool soloLectura;
  final String? errorText;
  final void Function()? onFocusLost;
  final List<TextInputFormatter>? inputFormatters;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.hint,
    required this.icono,
    this.teclado = TextInputType.text,
    this.oculto = false,
    this.sufijo,
    this.soloLectura = false,
    this.errorText,
    this.onFocusLost,
    this.inputFormatters,
  });

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late final FocusNode _focusNode;

  // Estado propio de "texto visible/oculto" para los campos de
  // contraseña. Arranca igual que widget.oculto (oculto por defecto) y
  // se puede destapar tocando el ojo — así TODO campo con oculto:true
  // tiene el toggle de ver/ocultar sin que cada pantalla lo arme a mano.
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.oculto;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onFocusLost?.call();
    });
  }

  @override
  void didUpdateWidget(covariant CampoTexto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la pantalla cambia el campo de "es contraseña" a "no lo es"
    // (poco común, pero por seguridad), se sincroniza el estado interno.
    if (oldWidget.oculto != widget.oculto) _obscured = widget.oculto;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la pantalla ya trae su propio ícono en `sufijo` (como en Mi
    // Perfil), se respeta tal cual. Si no, y el campo es de contraseña
    // (oculto:true), se agrega automáticamente el ojo de ver/ocultar.
    final Widget? sufijoFinal = widget.sufijo ??
        (widget.oculto
            ? IconButton(
                icon: Icon(_obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null);

    return TextField(
      controller: widget.controller,
      focusNode: widget.onFocusLost != null ? _focusNode : null,
      obscureText: widget.oculto ? _obscured : false,
      keyboardType: widget.teclado,
      readOnly: widget.soloLectura,
      inputFormatters: widget.inputFormatters,
      style: widget.soloLectura ? TextStyle(color: Colors.grey.shade600) : null,
      decoration: InputDecoration(
        errorMaxLines: 3,
        hintText: widget.hint,
        filled: true,
        fillColor:
            widget.soloLectura ? Colors.grey.shade200 : AppColors.fondoClaro,
        prefixIcon: Icon(widget.icono),
        suffixIcon: sufijoFinal,
        errorText: widget.errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
