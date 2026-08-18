import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:movil/screens/login_screen.dart';
import 'package:movil/core/app_navigator.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  main.dart — único punto de entrada de la app.
//  Firebase desactivado para web/Chrome.
//  Al correr en Android físico, descomentar Firebase.initializeApp()
// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // descomentar solo para Android
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ALEVET',
      // Español en todos los widgets nativos: selector de fecha
      // (showDatePicker), nombres de mes/día, botones "OK"/"Cancel"
      // → "Aceptar"/"Cancelar", etc. Sin esto, esos textos siempre
      // salen en inglés sin importar el idioma del celular.
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
