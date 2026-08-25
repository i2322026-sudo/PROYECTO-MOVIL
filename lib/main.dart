import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movil/screens/login_screen.dart';
import 'package:movil/core/app_navigator.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  main.dart — único punto de entrada de la app.
//  Firebase se inicializa siempre. En Android usa automáticamente
//  google-services.json (ya está en android/app/), así que no
//  hace falta pasarle FirebaseOptions manualmente.
// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Si falla (ej. corriendo en Chrome/web sin configurar), la app
    // sigue funcionando igual; solo no habrá notificaciones push.
    debugPrint('Firebase no se pudo inicializar: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ALIVET',
      // Español en todos los widgets nativos: selector de fecha678.
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.verde,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
