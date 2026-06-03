import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';
import '../services/api_config.dart';
import 'dashboard_screen.dart';
import 'MiPerfil_Screen.dart';

class NuevoColaboradorScreen extends StatefulWidget {
  const NuevoColaboradorScreen({super.key});
  @override
  State<NuevoColaboradorScreen> createState() =>
      _NuevoColaboradorScreenState();
}

class _NuevoColaboradorScreenState
    extends State<NuevoColaboradorScreen> {
  final Dio _dio = DioClient.dio;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombresCtrl    = TextEditingController();
  final _correoCtrl     = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _dniCtrl        = TextEditingController();
  final _telefonoCtrl   = TextEditingController();
  final _usuarioCtrl    = TextEditingController();

  List  _cargos        = [];
  int?  _idCargo;
  bool  _verPassword   = false;
  bool  _guardando     = false;
  bool  _cargando      = true;

  @override
  void initState() {
    super.initState();
    _cargarCargos();
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _dniCtrl.dispose();
    _telefonoCtrl.dispose();
    _usuarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCargos() async {
    try {
      final res = await _dio.get(ApiConfig.cargos);
      setState(() {
        _cargos   = res.data as List;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCargo == null) {
      _showSnack('Selecciona un cargo', Colors.orange);
      return;
    }

    setState(() => _guardando = true);

    try {
      await _dio.post(
        ApiConfig.colaboradores,
        data: {
          'nombres':   _nombresCtrl.text.trim(),
          'correo':    _correoCtrl.text.trim(),
          'password':  _passwordCtrl.text,
          'dni':       _dniCtrl.text.trim(),
          'telefono':  _telefonoCtrl.text.trim(),
          'usuario':   _usuarioCtrl.text.trim(),
          'id_cargo':  _idCargo,
        },
      );

      if (!mounted) return;
      _showSnack('✅ Colaborador registrado correctamente',
          Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnack(
        e.toString().replaceAll('Exception: ', ''),
        Colors.red,
      );
    }

    setState(() => _guardando = false);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agroveterinario ALEVET',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1B9B5E)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Text('Nuevo colaborador',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Completa los datos del nuevo colaborador',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),

                    // Avatar placeholder
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF1B9B5E)
                            .withOpacity(0.15),
                        child: const Icon(
                          Icons.person_add,
                          size: 40,
                          color: Color(0xFF1B9B5E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── NOMBRES ─────────────────────────────
                    _campo(
                      ctrl:  _nombresCtrl,
                      label: 'Nombres completos *',
                      hint:  'Ej: Juan Pérez García',
                      icono: Icons.person_outline,
                      validar: (v) =>
                          v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    // ── DNI ──────────────────────────────────
                    _campo(
                      ctrl:  _dniCtrl,
                      label: 'DNI *',
                      hint:  'Ej: 12345678',
                      icono: Icons.badge_outlined,
                      tipo:  TextInputType.number,
                      validar: (v) {
                        if (v!.isEmpty) return 'Campo requerido';
                        if (v.length != 8) return 'DNI debe tener 8 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── TELÉFONO ─────────────────────────────
                    _campo(
                      ctrl:  _telefonoCtrl,
                      label: 'Teléfono (opcional)',
                      hint:  'Ej: 987654321',
                      icono: Icons.phone_outlined,
                      tipo:  TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // ── CORREO ───────────────────────────────
                    _campo(
                      ctrl:  _correoCtrl,
                      label: 'Correo electrónico *',
                      hint:  'correo@ejemplo.com',
                      icono: Icons.email_outlined,
                      tipo:  TextInputType.emailAddress,
                      validar: (v) {
                        if (v!.isEmpty) return 'Campo requerido';
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── USUARIO ──────────────────────────────
                    _campo(
                      ctrl:  _usuarioCtrl,
                      label: 'Nombre de usuario *',
                      hint:  'Ej: jperez',
                      icono: Icons.alternate_email,
                      validar: (v) =>
                          v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    // ── PASSWORD ─────────────────────────────
                    _labelTexto('Contraseña *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller:  _passwordCtrl,
                      obscureText: !_verPassword,
                      validator: (v) {
                        if (v!.isEmpty) return 'Campo requerido';
                        if (v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText:   'Mínimo 6 caracteres',
                        filled:     true,
                        fillColor:  Colors.white,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF1B9B5E),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _verPassword = !_verPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1B9B5E),
                              width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── CARGO (desde BD) ─────────────────────
                    _labelTexto('Cargo *'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value:      _idCargo,
                          isExpanded: true,
                          hint: Text(
                            'Seleccionar cargo',
                            style: TextStyle(
                                color: Colors.grey.shade500),
                          ),
                          items: _cargos.map((c) {
                            return DropdownMenuItem<int>(
                              value: c['id_cargo'] as int,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.work_outline,
                                    size: 16,
                                    color: Color(0xFF1B9B5E),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(c['nombre'] as String),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _idCargo = v),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF1B9B5E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── BOTÓN GUARDAR ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1B9B5E),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                            : const Text(
                                'Registrar colaborador',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── BOTÓN CANCELAR ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                              color: Colors.red, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:     const Color(0xFF1B9B5E),
        selectedItemColor:   Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(
                    builder: (_) => const DashboardScreen()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(
                    builder: (_) => const MiPerfilScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Mi cuenta'),
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    String?  hint,
    TextInputType tipo = TextInputType.text,
    IconData? icono,
    String? Function(String?)? validar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelTexto(label),
        const SizedBox(height: 6),
        TextFormField(
          controller:   ctrl,
          keyboardType: tipo,
          validator:    validar,
          decoration: InputDecoration(
            hintText:   hint,
            filled:     true,
            fillColor:  Colors.white,
            prefixIcon: icono != null
                ? Icon(icono,
                    color: const Color(0xFF1B9B5E), size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF1B9B5E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labelTexto(String texto) {
    return Text(texto,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500));
  }
}