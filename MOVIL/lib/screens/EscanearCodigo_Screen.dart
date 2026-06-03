import 'package:flutter/material.dart';
// Asegúrate de que estas rutas sean las correctas en tu proyecto
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:flutter_application_1/screens/MiPerfil_Screen.dart';

class EscanearCodigoScreen extends StatefulWidget {
  const EscanearCodigoScreen({super.key});

  @override
  State<EscanearCodigoScreen> createState() => _EscanearCodigoScreenState();
}

class _EscanearCodigoScreenState extends State<EscanearCodigoScreen> {
  int _currentIndex = 0; // Índice para manejar la selección visual

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E), // Verde ALEVET
        elevation: 0,
        title: const Text(
          "Escáner ALEVET",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () {
              // Lógica de flash a implementar luego
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. FONDO (Espacio para la cámara)
          Container(color: Colors.black),

          // 2. MÁSCARA OSCURA
          Positioned.fill(child: CustomPaint(painter: ScannerOverlayPainter())),

          // 3. MARCO VERDE DE ENFOQUE
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1B9B5E), width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 4. TEXTO GUÍA
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Alinee el código de barras",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "El escaneo es automático",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // --- BARRA DE NAVEGACIÓN SIMPLIFICADA (Solo Inicio y Mi Cuenta) ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B9B5E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            // Ir al Dashboard (Inicio)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            // Ir a Mi Perfil (Cuenta)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MiPerfilScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Mi cuenta"),
        ],
      ),
    );
  }
}

// --- PINTOR DE LA MÁSCARA PROFESIONAL ---
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: 260,
              height: 260,
            ),
            const Radius.circular(20),
          ),
        ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
