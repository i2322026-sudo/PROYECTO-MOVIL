import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  Navigator key global — dio_client.dart lo usa para redirigir
//  al login automáticamente cuando el token vence (401), sin
//  necesitar el BuildContext de la pantalla donde falló el pedido.
// ─────────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
