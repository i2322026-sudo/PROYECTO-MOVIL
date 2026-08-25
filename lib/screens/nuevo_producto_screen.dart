import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/models/categoria_model.dart';
import 'package:movil/models/subcategoria_model.dart';
import 'package:movil/models/animal_model.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/services/categoria_service.dart';
import 'package:movil/services/animal_service.dart';
import 'package:movil/services/upload_service.dart';
import 'package:movil/services/api_config.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/utils/validators.dart';

// ─────────────────────────────────────────────────────────────
//  _SinNegativosFormatter — bloquea el signo "-" en campos
//  numéricos (precio, stock actual, stock mínimo) directamente
//  mientras se escribe, en vez de solo validar al guardar. Avisa
//  por callback para que la pantalla muestre "No se permiten
//  números negativos" debajo del campo, y lo oculte apenas se
//  corrige (sin negativos, "-999" quedaba pasando como precio o
//  stock válido hasta que Validators lo rechazaba al guardar).
// ─────────────────────────────────────────────────────────────
class _SinNegativosFormatter extends TextInputFormatter {
  final void Function(bool detectado) onCambio;
  _SinNegativosFormatter(this.onCambio);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.contains('-')) {
      onCambio(true);
      return oldValue; // Rechaza el cambio: el "-" nunca llega a escribirse
    }
    onCambio(false);
    return newValue;
  }
}

// ─────────────────────────────────────────────────────────────
//  NuevoProductoScreen — calcado del modal real de tu dashboard
//  web (public/dashboard.html + dashboard.js), verificado línea
//  por línea:
//
//  - Categoría y Tipo de Animal: GET /api/categorias, /api/animales
//  - La sección de "datos extra" CAMBIA según la categoría:
//      Medicamentos → "DATOS DEL MEDICAMENTO"
//      Accesorios   → "ATRIBUTOS DEL ACCESORIO" (con tags de colores/tallas)
//      Alimentos    → "INFORMACIÓN DEL ALIMENTO"
//      Otras (ej. Instrumentos Veterinarios) → sin sección extra
//  - `ficha_tecnica` es UNA sola columna en la BD reusada con
//    distinto widget/label según categoría: URL+Ver en
//    Medicamentos, textarea "Especificaciones" en Accesorios,
//    textarea "Información Nutricional" en Alimentos.
//  - Colores/Tallas se guardan como texto separado por comas
//    ("Rojo,Azul"), igual que hace agregarTag() en tu dashboard.js.
//  - Imagen: dos modos (Subir desde equipo / URL), no los dos
//    campos a la vez — igual que las pestañas de tu web.
// ─────────────────────────────────────────────────────────────
class NuevoProductoScreen extends StatefulWidget {
  final Producto? productoExistente;
  const NuevoProductoScreen({super.key, this.productoExistente});

  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final _service = ProductoService();
  final _uploadService = UploadService();
  final _categoriaService = CategoriaService();
  final _animalService = AnimalService();

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _stockMinimoCtrl = TextEditingController(text: '5');

  // Mensaje "No se permiten números negativos" — se muestra en vivo
  // mientras se escribe, uno independiente por campo.
  String? _errorPrecioNegativo;
  String? _errorStockNegativo;
  String? _errorStockMinimoNegativo;
  final _codigoBarraCtrl = TextEditingController();
  final _imagenUrlCtrl = TextEditingController();

  // Campos compartidos entre categorías (mismas columnas de BD)
  final _marcaCtrl = TextEditingController();
  final _presentacionCtrl = TextEditingController();
  final _composicionCtrl = TextEditingController();
  final _modoUsoCtrl = TextEditingController();
  final _fichaTecnicaCtrl = TextEditingController();
  DateTime? _fechaVencimiento;

  // Solo Accesorios
  final _colorNuevoCtrl = TextEditingController();
  final _tallaNuevaCtrl = TextEditingController();
  final List<String> _colores = [];
  final List<String> _tallas = [];

  List<Categoria> _categorias = [];
  List<Subcategoria> _subcategorias = [];
  List<TipoAnimal> _animales = [];
  int? _idCategoria;
  int? _idSubcategoria;
  bool _cargandoSubcategorias = false;
  // 'MAYOR' | 'MENOR' | null — igual que prod-grupo-animal en la web:
  // obligatorio, y filtra qué opciones aparecen en Tipo de Animal.
  String? _grupoAnimal;
  int? _idTipoAnimal;

  // Imágenes secundarias (hasta 2, opcional) — mismo patrón que la
  // imagen principal: preview + subida a R2, guardando la URL final.
  Uint8List? _previewSecundaria1;
  Uint8List? _previewSecundaria2;
  String? _urlSecundaria1;
  String? _urlSecundaria2;
  bool _subiendoSecundaria1 = false;
  bool _subiendoSecundaria2 = false;

  /// Solo los animales del grupo elegido — igual que
  /// filtrarAnimalesPorGrupo() en dashboard.js.
  List<TipoAnimal> get _animalesFiltrados => _grupoAnimal == null
      ? const []
      : _animales.where((a) => a.grupo == _grupoAnimal).toList();

  bool _cargandoCatalogos = true;
  bool _guardando = false;
  bool _subiendoImagen = false;
  bool _subiendoFicha = false;
  bool _fichaModoUrl = false; // false = subir PDF, true = pegar URL
  Uint8List? _previewBytes;
  String? _error;

  bool get _esEdicion => widget.productoExistente != null;

  String get _nombreCategoria {
    if (_idCategoria == null) return '';
    final c = _categorias.where((c) => c.idCategoria == _idCategoria);
    return c.isEmpty ? '' : c.first.nombre.toLowerCase();
  }

  bool get _esMedicamento => _nombreCategoria.contains('medicamento');
  bool get _esAccesorio => _nombreCategoria.contains('accesorio');
  bool get _esAlimento => _nombreCategoria.contains('aliment');

  // Igual que esCategoriaSinAnimal() en la web (public/js/dashboard.js):
  // categorías de uso general (ej. Instrumentos Veterinarios) no se
  // clasifican por animal — se oculta Grupo/Tipo de Animal y deja de
  // ser obligatorio.
  bool get _esCategoriaSinAnimal => _nombreCategoria.contains('instrumento');

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final categorias = await _categoriaService.getCategorias();
      final animales = await _animalService.getAnimales();

      final p = widget.productoExistente;
      // Igual que en dashboard.js: busca a qué grupo pertenece el
      // animal ya guardado, para dejar el filtro en cascada correcto
      // desde el arranque (si no, el Tipo de Animal quedaría vacío
      // hasta que el usuario tocara el Grupo a mano).
      TipoAnimal? animalActual;
      if (p?.idTipoAnimal != null) {
        final coincidencias =
            animales.where((a) => a.idTipoAnimal == p!.idTipoAnimal);
        animalActual = coincidencias.isEmpty ? null : coincidencias.first;
      }
      setState(() {
        _categorias = categorias;
        _animales = animales;
        _idCategoria = p?.idCategoria ??
            (categorias.isNotEmpty ? categorias.first.idCategoria : null);
        _grupoAnimal = animalActual?.grupo;
        _idTipoAnimal = p?.idTipoAnimal;
        _cargandoCatalogos = false;
      });

      // Precarga la subcategoría (si la categoría inicial tiene) —
      // igual que cargarSubcategorias(p.id_categoria, p.id_subcategoria)
      // en dashboard.js.
      if (_idCategoria != null) {
        await _cargarSubcategorias(_idCategoria!,
            valorSeleccionado: p?.idSubcategoria);
      }

      if (p != null) {
        _nombreCtrl.text = p.nombre;
        _descripcionCtrl.text = p.descripcion ?? '';
        _precioCtrl.text = p.precioVenta.toString();
        _stockCtrl.text = p.stockActual.toString();
        _stockMinimoCtrl.text = p.stockMinimo.toString();
        _codigoBarraCtrl.text = p.codigoBarra ?? '';
        _imagenUrlCtrl.text = p.imagen ?? '';
        _marcaCtrl.text = p.marca ?? '';
        _presentacionCtrl.text = p.pesoPresentacion ?? '';
        _composicionCtrl.text = p.composicion ?? '';
        _modoUsoCtrl.text = p.modoUso ?? '';
        _fichaTecnicaCtrl.text = p.fichaTecnica ?? '';
        if (p.colores != null && p.colores!.isNotEmpty) {
          _colores.addAll(p.colores!.split(',').map((e) => e.trim()));
        }
        if (p.tallas != null && p.tallas!.isNotEmpty) {
          _tallas.addAll(p.tallas!.split(',').map((e) => e.trim()));
        }
        if (p.fechaVencimiento != null) {
          _fechaVencimiento =
              DateTime.tryParse(p.fechaVencimiento!.split('T').first);
        }
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargandoCatalogos = false;
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _codigoBarraCtrl.dispose();
    _imagenUrlCtrl.dispose();
    _marcaCtrl.dispose();
    _presentacionCtrl.dispose();
    _composicionCtrl.dispose();
    _modoUsoCtrl.dispose();
    _fichaTecnicaCtrl.dispose();
    _colorNuevoCtrl.dispose();
    _tallaNuevaCtrl.dispose();
    super.dispose();
  }

  /// GET /api/categorias/:id/subcategorias — en cascada según la
  /// categoría elegida, igual que cargarSubcategorias() en
  /// dashboard.js. Lista vacía es un caso normal (esa categoría no
  /// tiene subcategorías registradas), no un error.
  Future<void> _cargarSubcategorias(int idCategoria,
      {int? valorSeleccionado}) async {
    setState(() => _cargandoSubcategorias = true);
    try {
      final lista = await _categoriaService.getSubcategorias(idCategoria);
      setState(() {
        _subcategorias = lista;
        _idSubcategoria = (valorSeleccionado != null &&
                lista.any((s) => s.idSubcategoria == valorSeleccionado))
            ? valorSeleccionado
            : null;
        _cargandoSubcategorias = false;
      });
    } catch (_) {
      // Igual que la web: si falla, se deja sin subcategorías en vez
      // de bloquear el resto del formulario (es un campo opcional).
      setState(() {
        _subcategorias = [];
        _idSubcategoria = null;
        _cargandoSubcategorias = false;
      });
    }
  }

  Future<void> _elegirImagenDesdeEquipo() async {
    await _elegirImagen(ImageSource.gallery);
  }

  Future<void> _tomarFotoConCamara() async {
    await _elegirImagen(ImageSource.camera);
  }

  Future<void> _elegirImagen(ImageSource origen) async {
    final XFile? archivo =
        await ImagePicker().pickImage(source: origen, imageQuality: 85);
    if (archivo == null) return;

    final bytes = await archivo.readAsBytes();
    setState(() {
      _previewBytes = bytes;
      _subiendoImagen = true;
      _error = null;
    });

    try {
      final url = await _uploadService.subirImagenProducto(
        bytes: bytes,
        nombreArchivo: archivo.name,
      );
      setState(() {
        _imagenUrlCtrl.text = url;
        _subiendoImagen = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _subiendoImagen = false;
        _previewBytes = null;
      });
    }
  }

  /// Imágenes secundarias (hasta 2, opcional) — mismo endpoint y
  /// mismo límite de 5MB que la imagen principal, solo que se
  /// guardan en campos separados en vez de reemplazar la principal.
  /// Antes solo abría la galería. Ahora, igual que la imagen principal
  /// (que ya tiene "Subir desde equipo" / "Cámara" como botones
  /// separados), primero pregunta el origen — aquí como un diálogo
  /// chico en vez de 2 botones, porque cada slot ya es angosto (van 2
  /// uno al lado del otro).
  Future<void> _elegirImagenSecundaria(int indice) async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.verde),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.verde),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final XFile? archivo =
        await ImagePicker().pickImage(source: origen, imageQuality: 85);
    if (archivo == null) return;

    final bytes = await archivo.readAsBytes();
    setState(() {
      if (indice == 1) {
        _previewSecundaria1 = bytes;
        _subiendoSecundaria1 = true;
      } else {
        _previewSecundaria2 = bytes;
        _subiendoSecundaria2 = true;
      }
      _error = null;
    });

    try {
      final url = await _uploadService.subirImagenProducto(
        bytes: bytes,
        nombreArchivo: archivo.name,
      );
      setState(() {
        if (indice == 1) {
          _urlSecundaria1 = url;
          _subiendoSecundaria1 = false;
        } else {
          _urlSecundaria2 = url;
          _subiendoSecundaria2 = false;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        if (indice == 1) {
          _subiendoSecundaria1 = false;
          _previewSecundaria1 = null;
        } else {
          _subiendoSecundaria2 = false;
          _previewSecundaria2 = null;
        }
      });
    }
  }

  void _quitarImagenSecundaria(int indice) {
    setState(() {
      if (indice == 1) {
        _previewSecundaria1 = null;
        _urlSecundaria1 = null;
      } else {
        _previewSecundaria2 = null;
        _urlSecundaria2 = null;
      }
    });
  }

  /// Abre el selector de archivos y sube el PDF a
  /// POST /api/upload/ficha-tecnica. Guarda la URL en el mismo
  /// campo que antes se llenaba a mano.
  Future<void> _elegirFichaTecnicaPdf() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (resultado == null || resultado.files.single.bytes == null) return;

    final archivo = resultado.files.single;
    setState(() {
      _subiendoFicha = true;
      _error = null;
    });

    try {
      final url = await _uploadService.subirFichaTecnica(
        bytes: archivo.bytes!,
        nombreArchivo: archivo.name,
      );
      setState(() {
        _fichaTecnicaCtrl.text = url;
        _subiendoFicha = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _subiendoFicha = false;
      });
    }
  }

  Future<void> _elegirFechaVencimiento() async {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final fecha = await showDatePicker(
      context: context,
      initialDate: (_fechaVencimiento != null && !_fechaVencimiento!.isBefore(soloHoy))
          ? _fechaVencimiento!
          : soloHoy,
      // No se puede retroceder a una fecha anterior a hoy: un producto
      // no puede registrarse con un vencimiento ya pasado. Antes
      // permitía hasta 365 días atrás, dejando elegir fechas viejas
      // por error.
      firstDate: soloHoy,
      lastDate: hoy.add(const Duration(days: 365 * 5)),
    );
    if (fecha != null) setState(() => _fechaVencimiento = fecha);
  }

  void _agregarColor() {
    final v = _colorNuevoCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _colores.add(v);
      _colorNuevoCtrl.clear();
    });
  }

  void _agregarTalla() {
    final v = _tallaNuevaCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _tallas.add(v);
      _tallaNuevaCtrl.clear();
    });
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _precioCtrl.text.trim().isEmpty ||
        _idCategoria == null) {
      setState(() => _error = 'Completa nombre, precio y categoría');
      return;
    }
    // Igual que guardarProducto() en la web: Grupo/Tipo de Animal solo
    // son obligatorios si la categoría SÍ se clasifica por animal.
    if (!_esCategoriaSinAnimal) {
      if (_grupoAnimal == null) {
        setState(() => _error = 'Selecciona el Grupo de Animal (Mayor / Menor)');
        return;
      }
      if (_idTipoAnimal == null) {
        setState(() => _error = 'Selecciona el Tipo de Animal');
        return;
      }
    }

    final errorPrecio = Validators.precio(_precioCtrl.text);
    if (errorPrecio != null) {
      setState(() => _error = errorPrecio);
      return;
    }
    final errorStock = Validators.stock(_stockCtrl.text);
    if (errorStock != null) {
      setState(() => _error = errorStock);
      return;
    }
    // Código de barra vuelve a ser opcional — se usa para el escaneo
    // desde la app móvil (Buscar por código), pero no bloquea guardar
    // el producto si todavía no se tiene el código a mano.
    final errorCodigoBarra =
        Validators.codigoBarra(_codigoBarraCtrl.text, obligatorio: false);
    if (errorCodigoBarra != null) {
      setState(() => _error = errorCodigoBarra);
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    String? vacioANull(String texto) =>
        texto.trim().isEmpty ? null : texto.trim();

    final producto = Producto(
      idProducto: widget.productoExistente?.idProducto ?? 0,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      imagen: vacioANull(_imagenUrlCtrl.text),
      precioVenta: double.tryParse(_precioCtrl.text.trim()) ?? 0,
      codigoBarra: vacioANull(_codigoBarraCtrl.text),
      idCategoria: _idCategoria,
      idSubcategoria: _idSubcategoria,
      idTipoAnimal: _esCategoriaSinAnimal ? null : _idTipoAnimal,
      stockActual: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      stockMinimo: int.tryParse(_stockMinimoCtrl.text.trim()) ?? 5,
      estado: 'ACTIVO',
      // Solo se mandan los campos que la categoría elegida
      // realmente usa, igual que hace guardarProducto() en tu web.
      marca: (_esMedicamento || _esAccesorio || _esAlimento)
          ? vacioANull(_marcaCtrl.text)
          : null,
      pesoPresentacion:
          (_esMedicamento || _esAlimento) ? vacioANull(_presentacionCtrl.text) : null,
      composicion:
          (_esMedicamento || _esAlimento) ? vacioANull(_composicionCtrl.text) : null,
      modoUso: _esMedicamento ? vacioANull(_modoUsoCtrl.text) : null,
      fechaVencimiento: (_esMedicamento || _esAlimento) && _fechaVencimiento != null
          ? '${_fechaVencimiento!.year.toString().padLeft(4, '0')}-'
              '${_fechaVencimiento!.month.toString().padLeft(2, '0')}-'
              '${_fechaVencimiento!.day.toString().padLeft(2, '0')}'
          : null,
      fichaTecnica: _esMedicamento
          ? vacioANull(_fichaTecnicaCtrl.text)
          : (_esAccesorio || _esAlimento)
              ? vacioANull(_fichaTecnicaCtrl.text)
              : null,
      colores: _esAccesorio && _colores.isNotEmpty ? _colores.join(',') : null,
      tallas: _esAccesorio && _tallas.isNotEmpty ? _tallas.join(',') : null,
      imagenSecundaria1: _urlSecundaria1,
      imagenSecundaria2: _urlSecundaria2,
    );

    try {
      if (_esEdicion) {
        await _service.actualizarProducto(producto.idProducto, producto);
      } else {
        await _service.crearProducto(producto);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _guardando = false;
      });
    }
  }

  Widget _chip(String valor, VoidCallback onEliminar, {required bool esColor}) {
    return Chip(
      label: Text(valor, style: const TextStyle(fontSize: 12)),
      backgroundColor: esColor ? AppColors.verdeMuySuave : AppColors.azulMuySuave,
      labelStyle: TextStyle(
          color: esColor ? AppColors.verdeExito : AppColors.azulOscuro),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onEliminar,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: _cargandoCatalogos
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── CATEGORÍA, GRUPO DE ANIMAL y TIPO DE ANIMAL — van
                //    primero, igual que en tu dashboard web. El Tipo
                //    de Animal queda deshabilitado hasta elegir un
                //    Grupo (igual que filtrarAnimalesPorGrupo() en
                //    dashboard.js), y solo muestra los animales de
                //    ese grupo.
                DropdownButtonFormField<int>(
                  initialValue: _idCategoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: _categorias
                      .map((c) => DropdownMenuItem(
                          value: c.idCategoria, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _idCategoria = v);
                    if (v != null) _cargarSubcategorias(v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _idSubcategoria,
                  decoration: InputDecoration(
                    labelText: 'Subcategoría',
                    border: const OutlineInputBorder(),
                    filled: _subcategorias.isEmpty,
                    fillColor: Colors.grey.shade200,
                  ),
                  hint: Text(_cargandoSubcategorias
                      ? 'Cargando...'
                      : _subcategorias.isEmpty
                          ? '-- Sin subcategorías --'
                          : '-- Seleccionar --'),
                  items: _subcategorias
                      .map((s) => DropdownMenuItem(
                          value: s.idSubcategoria, child: Text(s.nombre)))
                      .toList(),
                  onChanged: _subcategorias.isEmpty
                      ? null
                      : (v) => setState(() => _idSubcategoria = v),
                ),
                const SizedBox(height: 12),

                // Igual que toggleCamposAnimal() en la web: si la
                // categoría es de uso general (ej. Instrumentos
                // Veterinarios), se oculta Grupo/Tipo de Animal y se
                // muestra el mismo aviso gris que en el dashboard.
                if (_esCategoriaSinAnimal)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta categoría no se clasifica por animal.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _grupoAnimal,
                    decoration: const InputDecoration(
                      labelText: 'Grupo de Animal',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('-- Seleccionar --'),
                    items: const [
                      DropdownMenuItem(value: 'MAYOR', child: Text('Animales Mayores')),
                      DropdownMenuItem(value: 'MENOR', child: Text('Animales Menores')),
                    ],
                    onChanged: (v) => setState(() {
                      _grupoAnimal = v;
                      // Cambiar de grupo invalida la selección anterior de
                      // animal si ya no pertenece al nuevo grupo — igual
                      // que la web, que resetea el <select> al filtrar.
                      if (_idTipoAnimal != null &&
                          !_animalesFiltrados
                              .any((a) => a.idTipoAnimal == _idTipoAnimal)) {
                        _idTipoAnimal = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _idTipoAnimal,
                    decoration: InputDecoration(
                      labelText: 'Tipo de animal',
                      border: const OutlineInputBorder(),
                      filled: _grupoAnimal == null,
                      fillColor: Colors.grey.shade200,
                    ),
                    hint: Text(_grupoAnimal == null
                        ? '-- Elige primero un grupo --'
                        : '-- Seleccionar --'),
                    items: _animalesFiltrados
                        .map((a) => DropdownMenuItem(
                            value: a.idTipoAnimal, child: Text(a.nombre)))
                        .toList(),
                    onChanged: _grupoAnimal == null
                        ? null
                        : (v) => setState(() => _idTipoAnimal = v),
                  ),
                ],
                const SizedBox(height: 16),

                CampoTexto(
                    controller: _nombreCtrl,
                    hint: 'Nombre del producto',
                    icono: Icons.label_outline),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CampoTexto(
                        controller: _precioCtrl,
                        hint: 'Precio (S/.)',
                        icono: Icons.attach_money,
                        teclado:
                            const TextInputType.numberWithOptions(decimal: true),
                        errorText: _errorPrecioNegativo,
                        inputFormatters: [
                          _SinNegativosFormatter((detectado) => setState(
                              () => _errorPrecioNegativo = detectado
                                  ? 'No se permiten números negativos'
                                  : null)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CampoTexto(
                        controller: _stockCtrl,
                        hint: 'Stock actual',
                        icono: Icons.numbers,
                        teclado: TextInputType.number,
                        errorText: _errorStockNegativo,
                        inputFormatters: [
                          _SinNegativosFormatter((detectado) => setState(
                              () => _errorStockNegativo = detectado
                                  ? 'No se permiten números negativos'
                                  : null)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CampoTexto(
                    controller: _descripcionCtrl,
                    hint: 'Descripción',
                    icono: Icons.notes),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CampoTexto(
                        controller: _stockMinimoCtrl,
                        hint: 'Stock mínimo',
                        icono: Icons.warning_amber_outlined,
                        teclado: TextInputType.number,
                        errorText: _errorStockMinimoNegativo,
                        inputFormatters: [
                          _SinNegativosFormatter((detectado) => setState(
                              () => _errorStockMinimoNegativo = detectado
                                  ? 'No se permiten números negativos'
                                  : null)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CampoTexto(
                        controller: _codigoBarraCtrl,
                        hint: 'Código de barra',
                        icono: Icons.qr_code_2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── IMAGEN — 2 modos: subir desde equipo o tomar foto ──
                const Text('Imagen del producto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _subiendoImagen ? null : _elegirImagenDesdeEquipo,
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Subir desde equipo'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _subiendoImagen ? null : _tomarFotoConCamara,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Cámara'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.verde),
                          foregroundColor: AppColors.verde,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_previewBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_previewBytes!,
                            width: 60, height: 60, fit: BoxFit.cover),
                      )
                    else if (_imagenUrlCtrl.text.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // El valor guardado puede ser solo el nombre del
                        // archivo (ej. "croquetas.webp", así vino de la
                        // BD para los productos antiguos) en vez de una
                        // URL completa — sin resolverlo contra el backend
                        // (ApiConfig.urlImagen) Image.network fallaba
                        // directo al errorBuilder y nunca se veía nada.
                        child: Image.network(
                            ApiConfig.urlImagen(_imagenUrlCtrl.text) ??
                                _imagenUrlCtrl.text,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported))),
                      ),
                    if (_previewBytes != null || _imagenUrlCtrl.text.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _subiendoImagen ? null : _elegirImagenDesdeEquipo,
                          icon: _subiendoImagen
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          label: Text(_subiendoImagen ? 'Subiendo...' : 'Cambiar'),
                        ),
                      ),
                    ] else if (_subiendoImagen)
                      const Expanded(
                        child: LinearProgressIndicator(minHeight: 4),
                      ),
                  ],
                ),

                // ── IMÁGENES SECUNDARIAS (hasta 2, opcional) — igual
                //    que el bloque de dashboard.html ──────────────
                const SizedBox(height: 20),
                const Text('Imágenes secundarias (opcional, máx. 2)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _slotImagenSecundaria(
                      indice: 1,
                      preview: _previewSecundaria1,
                      url: _urlSecundaria1,
                      subiendo: _subiendoSecundaria1,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _slotImagenSecundaria(
                      indice: 2,
                      preview: _previewSecundaria2,
                      url: _urlSecundaria2,
                      subiendo: _subiendoSecundaria2,
                    )),
                  ],
                ),

                // ═══ SECCIÓN QUE CAMBIA SEGÚN LA CATEGORÍA ═══

                if (_esMedicamento) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const Row(children: [
                    Icon(Icons.medication_outlined, color: AppColors.verde),
                    SizedBox(width: 8),
                    Text('Datos del Medicamento',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.verde)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: CampoTexto(
                            controller: _marcaCtrl,
                            hint: 'Marca (ej: Bayer, PetCare...)',
                            icono: Icons.branding_watermark_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: CampoTexto(
                            controller: _presentacionCtrl,
                            hint: 'Presentación (ej: Caja x 10, 30ml)',
                            icono: Icons.scale_outlined)),
                  ]),
                  const SizedBox(height: 12),
                  _campoFecha(),
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _composicionCtrl,
                      hint: 'Composición (ej: Ivermectina 1%...)',
                      icono: Icons.science_outlined),
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _modoUsoCtrl,
                      hint: 'Modo de uso (ej: 1 tableta cada 8 horas)',
                      icono: Icons.menu_book_outlined),
                  const SizedBox(height: 12),
                  const Text('Ficha Técnica (PDF)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _fichaModoUrl = false);
                            _elegirFichaTecnicaPdf();
                          },
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('Subir PDF'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_fichaModoUrl
                                ? AppColors.verde.withOpacity(0.1)
                                : null,
                            side: BorderSide(
                                color: !_fichaModoUrl
                                    ? AppColors.verde
                                    : Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _fichaModoUrl = true),
                          icon: const Icon(Icons.link, size: 18),
                          label: const Text('URL'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _fichaModoUrl
                                ? AppColors.verde.withOpacity(0.1)
                                : null,
                            side: BorderSide(
                                color: _fichaModoUrl
                                    ? AppColors.verde
                                    : Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_fichaModoUrl)
                    (_fichaTecnicaCtrl.text.isNotEmpty || _subiendoFicha)
                        ? OutlinedButton.icon(
                            onPressed:
                                _subiendoFicha ? null : _elegirFichaTecnicaPdf,
                            icon: _subiendoFicha
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh),
                            label: Text(_subiendoFicha
                                ? 'Subiendo PDF...'
                                : 'PDF cargado ✓ (toca para cambiar)'),
                          )
                        : const SizedBox.shrink()
                  else
                    CampoTexto(
                      controller: _fichaTecnicaCtrl,
                      hint: 'Pega aquí el enlace de Drive del PDF...',
                      icono: Icons.link,
                    ),
                ],


                if (_esAccesorio) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const Row(children: [
                    Icon(Icons.sell_outlined, color: AppColors.verde),
                    SizedBox(width: 8),
                    Text('Atributos del Accesorio',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.verde)),
                  ]),
                  const SizedBox(height: 14),
                  CampoTexto(
                      controller: _marcaCtrl,
                      hint: 'Marca (ej: Kong, Trixie...)',
                      icono: Icons.branding_watermark_outlined),
                  const SizedBox(height: 12),
                  const Text('Colores disponibles',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (_colores.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _colores
                          .map((c) => _chip(c, () => setState(() => _colores.remove(c)),
                              esColor: true))
                          .toList(),
                    ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: CampoTexto(
                          controller: _colorNuevoCtrl,
                          hint: 'Ej: Rojo',
                          icono: Icons.palette_outlined),
                    ),
                    IconButton(
                        onPressed: _agregarColor,
                        icon: const Icon(Icons.add_circle, color: AppColors.verde)),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Tallas disponibles',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (_tallas.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _tallas
                          .map((t) => _chip(t, () => setState(() => _tallas.remove(t)),
                              esColor: false))
                          .toList(),
                    ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: CampoTexto(
                          controller: _tallaNuevaCtrl,
                          hint: 'Ej: S, M, L, XL',
                          icono: Icons.straighten),
                    ),
                    IconButton(
                        onPressed: _agregarTalla,
                        icon: const Icon(Icons.add_circle, color: AppColors.verde)),
                  ]),
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _fichaTecnicaCtrl,
                      hint: 'Especificaciones (ej: Material, dimensiones...)',
                      icono: Icons.description_outlined),
                ],

                if (_esAlimento) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const Row(children: [
                    Icon(Icons.egg_outlined, color: AppColors.verde),
                    SizedBox(width: 8),
                    Text('Información del Alimento',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.verde)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: CampoTexto(
                            controller: _marcaCtrl,
                            hint: 'Marca (ej: Purina, Royal Canin...)',
                            icono: Icons.branding_watermark_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: CampoTexto(
                            controller: _presentacionCtrl,
                            hint: 'Peso / Presentación (ej: 1kg, 5kg)',
                            icono: Icons.scale_outlined)),
                  ]),
                  const SizedBox(height: 12),
                  _campoFecha(),
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _composicionCtrl,
                      hint: 'Composición (ej: Pollo, arroz, vitaminas...)',
                      icono: Icons.science_outlined),
                  const SizedBox(height: 12),
                  CampoTexto(
                      controller: _fichaTecnicaCtrl,
                      hint: 'Información Nutricional (ej: Proteína 28%, Grasa 15%...)',
                      icono: Icons.description_outlined),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _guardando
                              ? null
                              : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BotonPrincipal(
                        texto: _esEdicion ? 'Guardar cambios' : 'Crear producto',
                        cargando: _guardando,
                        onPressed: _guardar,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// Un slot de imagen secundaria: si ya hay preview/URL muestra la
  /// miniatura con botón de quitar; si no, el botón para elegirla.
  Widget _slotImagenSecundaria({
    required int indice,
    required Uint8List? preview,
    required String? url,
    required bool subiendo,
  }) {
    if (subiendo) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (preview != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(preview,
                height: 90, width: double.infinity, fit: BoxFit.cover),
          ),
          IconButton(
            onPressed: () => _quitarImagenSecundaria(indice),
            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
            style: IconButton.styleFrom(
                backgroundColor: Colors.white, padding: EdgeInsets.zero),
          ),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _elegirImagenSecundaria(indice),
      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
      label: Text('Secundaria $indice'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _campoFecha() {
    return InkWell(
      onTap: _elegirFechaVencimiento,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de vencimiento',
          prefixIcon: Icon(Icons.event_outlined),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _fechaVencimiento != null
              ? '${_fechaVencimiento!.day.toString().padLeft(2, '0')}/'
                  '${_fechaVencimiento!.month.toString().padLeft(2, '0')}/'
                  '${_fechaVencimiento!.year}'
              : 'dd/mm/aaaa',
          style: TextStyle(
              color: _fechaVencimiento != null ? Colors.black87 : Colors.grey.shade600),
        ),
      ),
    );
  }
}
