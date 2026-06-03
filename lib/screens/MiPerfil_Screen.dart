import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../main.dart';
import '../services/usuario_service.dart';

// ─────────────────────────────────────────────────────────────
//  MiPerfilScreen — muestra nombre y correo reales del usuario
//  Los datos vienen de SharedPreferences (guardados al hacer login)
// ─────────────────────────────────────────────────────────────
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  final UsuarioService _service = UsuarioService();

  String _nombre = '';
  String _correo = '';
  String _rol    = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final nombre = await _service.getNombre();
    final correo = await _service.getCorreo();
    final rol    = await _service.getRol();
    setState(() {
      _nombre = nombre;
      _correo = correo;
      _rol    = rol;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B9B5E)),
            child: const Text('Salir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Agroveterinaria ALEVET',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sub-header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
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
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Mi cuenta',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Avatar + nombre real
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo con nombre real
                Text(
                  'HOLA\n${_nombre.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Avatar circular con inicial
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      const Color(0xFF1B9B5E).withOpacity(0.15),
                  child: Text(
                    _nombre.isNotEmpty
                        ? _nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9B5E)),
                  ),
                ),

                const SizedBox(height: 24),

                // Datos del usuario (nombre real)
                _fila(Icons.person_outline, _nombre.isNotEmpty
                    ? _nombre
                    : 'Cargando...'),
                const SizedBox(height: 10),

                // Correo real
                _fila(Icons.email_outlined,
                    _correo.isNotEmpty ? _correo : '—'),
                const SizedBox(height: 10),

                // Rol
                _fila(
                  Icons.badge_outlined,
                  _rol == 'COLABORADOR' ? 'Administrador' : 'Cliente',
                ),
              ],
            ),
          ),

          const Spacer(),

          // Botón cerrar sesión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration:
                const BoxDecoration(color: Color(0xFFD9F0E5)),
            child: TextButton(
              onPressed: _cerrarSesion,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Color(0xFF1B9B5E)),
                  SizedBox(width: 10),
                  Text(
                    'Cerrar sesión',
                    style: TextStyle(
                        color: Color(0xFF1B9B5E),
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:     const Color(0xFF1B9B5E),
        selectedItemColor:   Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const DashboardScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Mi cuenta'),
        ],
      ),
    );
  }

  Widget _fila(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 22, color: const Color(0xFF1B9B5E)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(texto,
              style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
