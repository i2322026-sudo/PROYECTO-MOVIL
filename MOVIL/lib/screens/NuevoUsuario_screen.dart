import 'package:flutter/material.dart';
// Asegúrate de que esta ruta sea correcta en tu proyecto
import 'package:flutter_application_1/screens/dashboard_screen.dart';

class NuevoUsuarioScreen extends StatefulWidget {
  const NuevoUsuarioScreen({super.key});

  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 179, 207, 168),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LOGO ---
                const Row(
                  children: [
                    SizedBox(width: 6),
                    Text(
                      'LOGO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'NUEVO USUARIO',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Regístrate para continuar y disfrutar de nuestros servicios.',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // --- BOTONES SOCIALES ---
                Row(
                  children: [
                    // BOTÓN APPLE
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, size: 20, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              "Apple",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // BOTÓN FACEBOOK (Igual que el de Apple, sin links)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Usamos el icono nativo de Facebook que ya viene en Flutter
                            Icon(
                              Icons.facebook,
                              size: 20,
                              color: Color(0xFF1877F2),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Facebook",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- CAMPOS DE TEXTO ---
                _buildInputLabel("Nombre", "Ingrese nombre completo"),
                const SizedBox(height: 16),
                _buildInputLabel("Apellido", "Ingrese su apellido"),
                const SizedBox(height: 16),
                _buildInputLabel(
                  "Correo electrónico",
                  "ejemplo@mail.com",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // --- CONTRASEÑA ---
                const Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    hintText: 'Ingrese su contraseña',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ingrese al menos 8 caracteres, incluyendo una letra mayúscula, un número y un símbolo.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // --- BOTÓN DE REGISTRO ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 96, 151, 91),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para etiquetas y campos (No Password)
  Widget _buildInputLabel(
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
