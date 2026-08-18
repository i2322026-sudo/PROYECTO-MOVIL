import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  AppColors — paleta centralizada de la app.
//
//  Por qué existe este archivo: antes cada pantalla escribía
//  Color(0xFF1B9B5E) directo (68 veces), y cuando hubo que
//  alinear el verde con el de la página web (#06A049), hubo que
//  buscar y cambiar archivo por archivo. Con esta paleta, un
//  cambio de color de marca se hace en UN solo lugar.
// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._(); // no se instancia, solo constantes estáticas

  // Verde de marca — el mismo --agro-green de la página web
  static const Color verde = Color(0xFF06A049);
  static const Color verdeOscuro = Color(0xFF047a37);
  static const Color verdeClaro = Color(0xFF2FBE73);
  static const Color verdeMuySuave = Color(0xFFE8F5E9);

  // Fondos
  static const Color fondoClaro = Color(0xFFF5F6FA);
  static const Color fondoVerdeSuave = Color(0xFFF5FAF6);

  // Acentos
  static const Color dorado = Color(0xFFF5C242);
  static const Color naranja = Color(0xFFEF7B45);

  // Azules (usados en algunos badges/estados)
  static const Color azul = Color(0xFF3B82C4);
  static const Color azulOscuro = Color(0xFF1565C0);
  static const Color azulMuySuave = Color(0xFFE3F2FD);

  // Verde de éxito (distinto tono, usado en confirmaciones)
  static const Color verdeExito = Color(0xFF2E7D32);
}
