import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/MiPerfil_Screen.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';

class ProntoVencer_Screen extends StatelessWidget {
  const ProntoVencer_Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> productosVencer = [
      {
        "nombre": "Capsulas",
        "vencimiento": "2026-02-10",
        "dias": "4",
        "imagen": "",
      },
      {
        "nombre": "Vacetios",
        "vencimiento": "2026-02-11",
        "dias": "5",
        "imagen": "",
      },
      {
        "nombre": "Antimicrobiano amplio espectro",
        "vencimiento": "2026-02-15",
        "dias": "9",
        "imagen": "",
      },
      {
        "nombre": "Pedigros",
        "vencimiento": "2026-02-20",
        "dias": "14",
        "imagen": "",
      },
      {
        "nombre": "Pedigros (Lote B)",
        "vencimiento": "2026-02-21",
        "dias": "15",
        "imagen": "",
      },
      {
        "nombre": "Procti-Richmond pharma",
        "vencimiento": "2026-02-28",
        "dias": "24",
        "imagen": "",
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
            color: Colors.white, // Cambiado a blanco para mejor contraste
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sub-header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Color(0xFF003366), size: 28),
                Expanded(
                  child: Center(
                    child: Text(
                      '"Producto pronto a vencer"',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.cancel_outlined,
                  color: Colors.black54,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.black54,
                  size: 28,
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          const Divider(thickness: 1, height: 1),

          // Cabecera de la tabla
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            color: Colors.white,
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "PRODUCTO",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      "FECHA DE\nVENCIMIENTO",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      "DIAS\nRESTANTES",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1),

          // Lista de productos corregida
          Expanded(
            child: ListView.separated(
              itemCount: productosVencer.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prod = productosVencer[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            // LÓGICA DE IMAGEN CORREGIDA
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: prod['imagen'].toString().isEmpty
                                  ? const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.grey,
                                    )
                                  : Image.network(
                                      prod['imagen'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.broken_image,
                                                color: Colors.red,
                                              ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                prod['nombre'],
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            prod['vencimiento'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            prod['dias'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
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
