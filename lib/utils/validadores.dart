// ─────────────────────────────────────────────────────────────
//  validadores.dart — reglas de validación reutilizables,
//  basadas en el formato real usado en Perú y en las columnas
//  de la base de datos (persona.telefono, colaborador.dni).
//  Cada función devuelve null si es válido, o un mensaje de
//  error si no lo es — listo para mostrar directo en pantalla.
// ─────────────────────────────────────────────────────────────

/// DNI peruano: exactamente 8 dígitos numéricos.
String? validarDni(String valor) {
  final v = valor.trim();
  if (v.isEmpty) return null; // el campo vacío lo maneja cada pantalla aparte
  if (!RegExp(r'^\d{8}$').hasMatch(v)) {
    return 'El DNI debe tener exactamente 8 dígitos';
  }
  return null;
}

/// Celular peruano: exactamente 9 dígitos, empieza con 9.
String? validarCelular(String valor) {
  final v = valor.trim();
  if (v.isEmpty) return null;
  if (!RegExp(r'^9\d{8}$').hasMatch(v)) {
    return 'El celular debe tener 9 dígitos y empezar con 9';
  }
  return null;
}

/// Número que no puede ser negativo (stock, cantidades en general).
/// Permite 0. Devuelve null si el texto ni siquiera es un número —
/// eso ya lo valida cada pantalla por separado con el resto de campos.
String? validarNoNegativo(String valor, {String campo = 'El valor'}) {
  final n = num.tryParse(valor.trim());
  if (n == null) return null;
  if (n < 0) return '$campo no puede ser negativo';
  return null;
}

/// Precio: no puede ser negativo NI cero (un producto sin precio no
/// tiene sentido para la venta).
String? validarPrecio(String valor) {
  final n = num.tryParse(valor.trim());
  if (n == null) return null;
  if (n <= 0) return 'El precio debe ser mayor a 0';
  return null;
}
