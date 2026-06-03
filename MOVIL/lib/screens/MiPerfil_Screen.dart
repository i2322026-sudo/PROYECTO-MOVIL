import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:flutter_application_1/main.dart';

class MiPerfilScreen extends StatelessWidget {
  const MiPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E), // Verde ALEVET
        elevation: 0,
        automaticallyImplyLeading:
            false, // Evita que salga la flecha de back automática
        title: const Text(
          "Agroveterinaria ALEVET",
          style: TextStyle(
            color: Colors.white, // Cambiado a blanco para mejor contraste
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- BARRA SUB-HEADER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                  ), // Icono más fino
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  '"Mi cuenta"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- SECCIÓN DE PERFIL ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "HOLA\nADMIN",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text("👦", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Icon(Icons.person, size: 24),
                    SizedBox(width: 15),
                    Text(
                      "Mi perfil",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // --- BOTÓN CERRAR SESIÓN ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(color: Color(0xFFD9F0E5)),
            child: TextButton(
              onPressed: () {
                // Navega a NuevoUsuario y borra el historial
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Color(0xFF1B9B5E)),
                  SizedBox(width: 10),
                  Text(
                    "Cerrar sesión",
                    style: TextStyle(
                      color: Color(0xFF1B9B5E),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- BARRA DE NAVEGACIÓN CORREGIDA ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B9B5E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1, // 1 porque estamos en "Mi cuenta"
        onTap: (int index) {
          if (index == 0) {
            // Ir al Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            // Ya estamos en Mi cuenta, no hace falta recargar o puedes hacer un print
            print("Ya estás en Mi cuenta");
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Inicio",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Mi cuenta"),
        ],
      ),
    );
  }
}
