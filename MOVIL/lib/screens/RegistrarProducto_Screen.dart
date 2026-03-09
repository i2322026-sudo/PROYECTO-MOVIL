import 'package:flutter/material.dart';
// Asegúrate de que esta importación coincida con el nombre de tu archivo
import 'package:flutter_application_1/screens/NuevoProducto.dart';

class TodosProductos_Screen extends StatefulWidget {
  const TodosProductos_Screen({super.key});

  @override
  State<TodosProductos_Screen> createState() => _TodosProductos_ScreenState();
}

class _TodosProductos_ScreenState extends State<TodosProductos_Screen> {
  // Lista de ejemplo para visualizar el diseño
  final List<Map<String, dynamic>> productos = [
    {
      "nombre": "Antibiótico Bovino",
      "stock": 45,
      "precio": 25.50,
      "categoria": "Fármacos",
    },
    {
      "nombre": "Alimento Premium Canino",
      "stock": 12,
      "precio": 45.00,
      "categoria": "Nutrición",
    },
    {
      "nombre": "Vitaminas A-D-E",
      "stock": 80,
      "precio": 15.00,
      "categoria": "Suplementos",
    },
    {
      "nombre": "Shampoo Antipulgas",
      "stock": 5,
      "precio": 12.50,
      "categoria": "Aseo",
    },
    {
      "nombre": "Vacuna Antirrábica",
      "stock": 30,
      "precio": 8.00,
      "categoria": "Vacunas",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        title: const Text(
          "Inventario de Productos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Lógica de búsqueda
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- CABECERA DE RESUMEN ---
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1B9B5E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem("Total", "${productos.length}"),
                _buildSummaryItem("Bajo Stock", "12"),
                _buildSummaryItem("Valor Total", "\$ 12,450"),
              ],
            ),
          ),

          // --- LISTA DE PRODUCTOS ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final prod = productos[index];
                final bool lowStock = prod['stock'] < 10;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Color(0xFF1B9B5E),
                      ),
                    ),
                    title: Text(
                      prod['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Categoría: ${prod['categoria']}"),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 14,
                              color: lowStock ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Stock: ${prod['stock']}",
                              style: TextStyle(
                                color: lowStock ? Colors.red : Colors.black87,
                                fontWeight: lowStock
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$${prod['precio'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFF1B9B5E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      // Opcional: Navegar al detalle
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // --- BOTÓN FLOTANTE CONFIGURADO ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B9B5E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // NAVEGACIÓN A NUEVO PRODUCTO
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NuevoProducto()),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
