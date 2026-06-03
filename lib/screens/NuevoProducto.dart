import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/dio_client.dart';
import '../services/api_config.dart';
import 'dashboard_screen.dart';
import 'MiPerfil_Screen.dart';

class NuevoProducto extends StatefulWidget {
  const NuevoProducto({super.key});
  @override
  State<NuevoProducto> createState() => _NuevoProductoState();
}

class _NuevoProductoState extends State<NuevoProducto> {
  final Dio _dio = DioClient.dio;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _codigoCtrl      = TextEditingController();
  final _precioCtrl      = TextEditingController();
  final _stockCtrl       = TextEditingController();
  final _stockMinCtrl    = TextEditingController();

  // Datos de selects
  List _animales   = [];
  List _categorias = [];
  int? _idAnimal;
  int? _idCategoria;
  DateTime? _fechaVencimiento;

  // Imagen
  File?       _imagenFile;
  Uint8List?  _imagenBytes;
  String?     _imagenNombre;

  bool _guardando  = false;
  bool _cargando   = true;

  @override
  void initState() {
    super.initState();
    _cargarSelects();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _codigoCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarSelects() async {
    try {
      final resAnim = await _dio.get(ApiConfig.animales);
      final resCat  = await _dio.get(ApiConfig.categorias);
      setState(() {
        _animales   = resAnim.data as List;
        _categorias = resCat.data  as List;
        _cargando   = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source:       source,
        imageQuality: 70,
        maxWidth:     800,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imagenBytes  = bytes;
          _imagenNombre = picked.name;
        });
      } else {
        setState(() {
          _imagenFile   = File(picked.path);
          _imagenNombre = picked.name;
        });
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen', Colors.red);
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Seleccionar imagen',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (!kIsWeb)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1B9B5E),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Tomar foto'),
                subtitle: const Text('Usar la cámara del dispositivo'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Subir desde galería'),
              subtitle: const Text('Elegir una foto existente'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            if (_imagenFile != null || _imagenBytes != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagenFile   = null;
                    _imagenBytes  = null;
                    _imagenNombre = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context:     context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B9B5E),
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null) setState(() => _fechaVencimiento = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idAnimal == null) {
      _showSnack('Selecciona el tipo de animal', Colors.orange);
      return;
    }
    if (_idCategoria == null) {
      _showSnack('Selecciona la categoría', Colors.orange);
      return;
    }

    setState(() => _guardando = true);

    try {
      // PASO 1: subir imagen a Cloudinary (si existe)
      String? urlImagen;
      if (_imagenFile != null || _imagenBytes != null) {
        final uploadData = FormData.fromMap({
          'imagen': _imagenFile != null
              ? await MultipartFile.fromFile(
                  _imagenFile!.path,
                  filename: _imagenNombre ?? 'producto.jpg',
                )
              : MultipartFile.fromBytes(
                  _imagenBytes!,
                  filename: _imagenNombre ?? 'producto.jpg',
                ),
        });
        final uploadRes = await _dio.post(
          '/api/upload/imagen-producto',
          data: uploadData,
        );
        urlImagen = uploadRes.data['url'];
      }

      // PASO 2: crear producto con JSON normal
      await _dio.post(ApiConfig.productos, data: {
        'nombre':            _nombreCtrl.text.trim(),
        'descripcion':       _descripcionCtrl.text.trim(),
        'codigo_barra':      _codigoCtrl.text.trim(),
        'precio_venta':      double.tryParse(_precioCtrl.text) ?? 0,
        'stock_actual':      int.tryParse(_stockCtrl.text) ?? 0,
        'stock_minimo':      int.tryParse(
                               _stockMinCtrl.text.isEmpty
                                 ? '5' : _stockMinCtrl.text) ?? 5,
        'id_tipo_animal':    _idAnimal,
        'id_categoria':      _idCategoria,
        'fecha_vencimiento': _fechaVencimiento
            ?.toIso8601String().split('T')[0],
        if (urlImagen != null) 'imagen': urlImagen,
      });

      if (!mounted) return;
      _showSnack('✅ Producto guardado correctamente', Colors.green);
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
                    const Text('Registro de producto',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // ── IMAGEN ──────────────────────────────
                    GestureDetector(
                      onTap: _mostrarOpcionesImagen,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF1B9B5E)
                                  .withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: _buildImagePreview(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── NOMBRE ──────────────────────────────
                    _campo(
                      ctrl:  _nombreCtrl,
                      label: 'Nombre del producto *',
                      hint:  'Ej: Antipulgas Premium',
                      validar: (v) => v!.isEmpty
                          ? 'Campo requerido'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── DESCRIPCIÓN ─────────────────────────
                    _campo(
                      ctrl:     _descripcionCtrl,
                      label:    'Descripción (opcional)',
                      hint:     'Describe el producto...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // ── CÓDIGO BARRA ────────────────────────
                    _campo(
                      ctrl:  _codigoCtrl,
                      label: 'Código de barra (opcional)',
                      hint:  'Ej: ABC123456',
                      icono: Icons.qr_code,
                    ),
                    const SizedBox(height: 12),

                    // ── TIPO ANIMAL (desde BD) ──────────────
                    _labelTexto('Tipo de animal *'),
                    const SizedBox(height: 6),
                    _dropdown(
                      valor:    _idAnimal,
                      hint:     'Seleccionar tipo de animal',
                      items:    _animales,
                      idKey:    'id_tipo_animal',
                      nameKey:  'nombre',
                      onChanged: (v) =>
                          setState(() => _idAnimal = v),
                    ),
                    const SizedBox(height: 12),

                    // ── CATEGORÍA (desde BD) ────────────────
                    _labelTexto('Categoría *'),
                    const SizedBox(height: 6),
                    _dropdown(
                      valor:    _idCategoria,
                      hint:     'Seleccionar categoría',
                      items:    _categorias,
                      idKey:    'id_categoria',
                      nameKey:  'nombre',
                      onChanged: (v) =>
                          setState(() => _idCategoria = v),
                    ),
                    const SizedBox(height: 12),

                    // ── PRECIO Y STOCK ──────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl:  _precioCtrl,
                            label: 'Precio (S/) *',
                            hint:  '0.00',
                            tipo:  TextInputType.number,
                            icono: Icons.attach_money,
                            validar: (v) => v!.isEmpty
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _campo(
                            ctrl:  _stockCtrl,
                            label: 'Stock actual *',
                            hint:  '0',
                            tipo:  TextInputType.number,
                            icono: Icons.inventory,
                            validar: (v) => v!.isEmpty
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── STOCK MÍNIMO ────────────────────────
                    _campo(
                      ctrl:  _stockMinCtrl,
                      label: 'Stock mínimo (alerta)',
                      hint:  'Por defecto: 5',
                      tipo:  TextInputType.number,
                      icono: Icons.warning_amber,
                    ),
                    const SizedBox(height: 12),

                    // ── FECHA VENCIMIENTO ───────────────────
                    _labelTexto('Fecha de vencimiento (opcional)'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: _fechaVencimiento != null
                                    ? const Color(0xFF1B9B5E)
                                    : Colors.grey,
                                size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _fechaVencimiento != null
                                  ? 'Vence: ${_fechaVencimiento!.toIso8601String().split('T')[0]}'
                                  : 'Seleccionar fecha',
                              style: TextStyle(
                                color: _fechaVencimiento != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            if (_fechaVencimiento != null)
                              GestureDetector(
                                onTap: () => setState(
                                    () => _fechaVencimiento = null),
                                child: const Icon(Icons.close,
                                    size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── BOTÓN GUARDAR ───────────────────────
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
                                'Guardar producto',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── BOTÓN CANCELAR ──────────────────────
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
                              color: Colors.red,
                              fontSize: 16),
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

  // ── Preview de imagen ────────────────────────────────────
  Widget _buildImagePreview() {
    if (kIsWeb && _imagenBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_imagenBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: _mostrarOpcionesImagen,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.edit,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    if (!kIsWeb && _imagenFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_imagenFile!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: _mostrarOpcionesImagen,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.edit,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 50,
            color: const Color(0xFF1B9B5E).withOpacity(0.6)),
        const SizedBox(height: 8),
        Text('Toca para agregar imagen',
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Cámara o galería',
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 12)),
      ],
    );
  }

  // ── Dropdown desde BD ───────────────────────────────────
  Widget _dropdown({
    required int?     valor,
    required String   hint,
    required List     items,
    required String   idKey,
    required String   nameKey,
    required void Function(int?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value:       valor,
          isExpanded:  true,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey.shade500)),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item[idKey] as int,
              child: Text(item[nameKey] as String),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF1B9B5E)),
        ),
      ),
    );
  }

  // ── Campo de texto ──────────────────────────────────────
  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    String?  hint,
    TextInputType tipo     = TextInputType.text,
    int      maxLines      = 1,
    IconData? icono,
    String? Function(String?)? validar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelTexto(label),
        const SizedBox(height: 6),
        TextFormField(
          controller:  ctrl,
          keyboardType: tipo,
          maxLines:    maxLines,
          validator:   validar,
          decoration: InputDecoration(
            hintText:    hint,
            filled:      true,
            fillColor:   Colors.white,
            prefixIcon:  icono != null
                ? Icon(icono, color: const Color(0xFF1B9B5E),
                    size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
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
