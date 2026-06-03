import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/BajoStock_Screen.dart';
import 'package:flutter_application_1/screens/EscanearCodigo_Screen.dart';
import 'package:flutter_application_1/screens/NuevoProducto.dart';
import 'package:flutter_application_1/screens/ProntoVencer_Screeen.dart';
import 'package:flutter_application_1/screens/MiPerfil_Screen.dart';
import 'package:flutter_application_1/screens/GestionPedido_Screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ALEVET - Panel",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                "Alertas de Inventario",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- BLOQUE DE ALERTAS CORREGIDO ---
            Row(
              children: [
                _buildAlertCard(
                  context,
                  "Bajo Stock",
                  "12 ítems", // Faltaba este argumento
                  const Color(0xFFF7A2A2),
                  const BajoStockScreen(),
                ),
                const SizedBox(width: 12),
                _buildAlertCard(
                  context,
                  "Pronto a Vencer",
                  "8 ítems", // Faltaba este argumento
                  const Color(0xFFC5E5D4),
                  const ProntoVencer_Screen(),
                ),
              ],
            ),

            const SizedBox(height: 40),

            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 10),
            const Text(
              "Operaciones Rápidas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildActionTile(
              context,
              Icons.add_box, // Icono reconocido para registrar nuevos ítems
              "Agregar Producto",
              "Registrar nuevo ítem",
              const NuevoProducto(),
            ),

            _buildActionTile(
              context,
              Icons.inventory_2,
              "Gestión de Pedidos",
              "Revisar stock entrante",
              const GestionPedidoScreen(),
            ),

            _buildActionTile(
              context,
              Icons.qr_code_scanner,
              "Escanear Producto",
              "Ingreso rápido por cámara",
              const EscanearCodigoScreen(),
              isPrimary: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B9B5E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (int index) {
          if (index == 1) {
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

  // --- MÉTODOS DE SOPORTE ---

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    Widget destination, {
    bool isPrimary = false,
  }) {
    return Card(
      elevation: isPrimary ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPrimary
              ? const Color(0xFF1B9B5E)
              : const Color(0xFF1B9B5E).withOpacity(0.1),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : const Color(0xFF1B9B5E),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            Icons.chevron_right,
            color: isPrimary ? const Color(0xFF1B9B5E) : Colors.black87,
            size: 28,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String subtitle,
    Color col,
    Widget screen,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: col,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
