import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:flutter_application_1/screens/MiPerfil_Screen.dart';

class GestionPedidoScreen extends StatelessWidget {
  const GestionPedidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // --- APPBAR VERDE ---
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {}, // Aquí podrías abrir un Drawer
        ),
        title: const Text(
          "Agroveterinario ALEVET",
          style: TextStyle(
            color: Colors
                .white, // Cambiado a blanco para mejor contraste sobre verde
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- SUB-HEADER BLANCO ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
            child: const Center(
              child: Text(
                "Lista de pedidos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- CABECERAS DE TABLA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTableHeader("CODIGO PEDIDO"),
                const SizedBox(width: 10),
                _buildTableHeader("Descripción"),
                const Spacer(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- LISTA DE PEDIDOS ---
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildPedidoItem(context);
              },
            ),
          ),
        ],
      ),

      // --- BARRA DE NAVEGACIÓN INFERIOR CORREGIDA ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B9B5E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex:
            0, // En esta pantalla Inicio está seleccionado visualmente
        onTap: (int index) {
          if (index == 0) {
            // Ir al Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            // CORRECCIÓN: Ahora el índice 1 corresponde a "Mi cuenta"
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

  // Widget para las etiquetas verdes superiores
  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1B9B5E)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }

  // Widget para cada fila de la lista
  Widget _buildPedidoItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 80,
            child: Text("36454756", style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Antimicrobiano y mucolítico enrofloxacina",
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              // Lógica para ver detalle
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF90CAF9),
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Ver pedido", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
