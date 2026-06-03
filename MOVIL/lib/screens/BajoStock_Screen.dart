import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/MiPerfil_Screen.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';

class BajoStockScreen extends StatelessWidget {
  const BajoStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos simulados basados en tu imagen
    final List<Map<String, dynamic>> productosBajoStock = [
      {
        "nombre": "Capsulas",
        "cantidad": "10",
        "color": Colors.red,
        "imagen": "https://via.placeholder.com/50", // Reemplazar con tus assets
      },
      {
        "nombre": "Antimicrobiano y mucolítico enrofloxacina",
        "cantidad": "20",
        "color": Colors.yellow.shade700,
        "imagen": "https://via.placeholder.com/50",
      },
      {
        "nombre": "Antimicrobiano de amplio espectro",
        "cantidad": "5",
        "color": Colors.red,
        "imagen": "https://via.placeholder.com/50",
      },
      {
        "nombre": "Pedigree",
        "cantidad": "11",
        "color": Colors.yellow.shade700,
        "imagen": "https://via.placeholder.com/50",
      },
      {
        "nombre": "Productos Framalogicos",
        "cantidad": "3",
        "color": Colors.red,
        "imagen": "https://via.placeholder.com/50",
      },
      {
        "nombre": "Profit-Richmond vet pharma",
        "cantidad": "1",
        "color": Colors.red,
        "imagen": "https://via.placeholder.com/50",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Agroveterinario ALEVET",
          style: TextStyle(
            color: Color(0xFF003366),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sub-header con icono de menú y título de sección
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Color(0xFF003366), size: 30),
                Expanded(
                  child: Center(
                    child: Text(
                      '"Producto de bajo stock"',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barra de búsqueda (Search Bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.black),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          const Divider(thickness: 2),

          // Lista de productos
          Expanded(
            child: ListView.separated(
              itemCount: productosBajoStock.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final producto = productosBajoStock[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  child: Row(
                    children: [
                      // Imagen del producto
                      Image.network(
                        producto['imagen'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.medication,
                              size: 50,
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(width: 15),
                      // Nombre del producto
                      Expanded(
                        child: Text(
                          producto['nombre'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Cantidad en stock con color dinámico
                      Text(
                        producto['cantidad'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: producto['color'],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Barra de navegación inferior igual a la anterior
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B9B5E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0, // Cambia a 1 cuando estés en la pantalla de Mi Perfil
        onTap: (index) {
          if (index == 0) {
            // Navegar al Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            // Navegar a Mi Perfil
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
