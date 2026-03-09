import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:flutter_application_1/screens/MiPerfil_Screen.dart';

class DetalleProductoScreen extends StatelessWidget {
  const DetalleProductoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E), // Verde ALEVET
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Agroveterinaria ALEVET",
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Subtítulo de la pantalla
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: const Text(
                "“Detalle de producto”",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 20),

            // Imagen del Producto
            Center(
              child: Image.network(
                'https://example.com/neumoxol.png', // Reemplazar con URL real o Asset
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.medication, size: 150, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),

            // Información Técnica del Producto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildDetailRow(
                    "NOMBRE:",
                    "Antimicrobiano y\nmucolitico\nenrofloxacina",
                  ),
                  _buildDetailRow("CÓDIGO:", "23455L"),
                  _buildDetailRow("LOTE:", "L-001"),
                  _buildDetailRow("FECHA DE\nVENCIMIENTO:", "07/02/2027"),
                  _buildDetailRow("STOCK:", "50"),
                  _buildDetailRow("ESTADO:", "NORMAL"),
                ],
              ),
            ),
          ],
        ),
      ),

      // Barra de navegación inferior consistente con el Dashboard
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B9B5E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MiPerfilScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Menú"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Mi cuenta"),
        ],
      ),
    );
  }

  // Widget auxiliar para las filas de datos
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
