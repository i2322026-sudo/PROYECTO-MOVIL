import 'package:flutter/material.dart';
import 'package:movil/models/subcategoria_model.dart';
import 'package:movil/services/categoria_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  SubcategoriasScreen — mismo CRUD que el modal "Subcategorías"
//  del dashboard web (dashboard.js -> abrirSubcategorias /
//  guardarSubcategoria / toggleSubcategoria / eliminarSubcategoria):
//  listar (incluye inactivas), crear, editar, activar/desactivar
//  y eliminar — todo dentro de una Categoría puntual.
// ─────────────────────────────────────────────────────────────
class SubcategoriasScreen extends StatefulWidget {
  final int idCategoria;
  final String nombreCategoria;
  const SubcategoriasScreen({
    super.key,
    required this.idCategoria,
    required this.nombreCategoria,
  });

  @override
  State<SubcategoriasScreen> createState() => _SubcategoriasScreenState();
}

class _SubcategoriasScreenState extends State<SubcategoriasScreen> {
  final _service = CategoriaService();
  List<Subcategoria> _subcategorias = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _service.getSubcategoriasAdmin(widget.idCategoria);
      setState(() {
        _subcategorias = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _toggleEstado(Subcategoria s) async {
    final nuevoEstado = s.estado == 'ACTIVO' ? 'INACTIVO' : 'ACTIVO';
    try {
      await _service.actualizarSubcategoria(
        id: s.idSubcategoria,
        nombre: s.nombre,
        descripcion: s.descripcion,
        estado: nuevoEstado,
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _eliminar(Subcategoria s) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar subcategoría'),
        content: Text(
            '¿Eliminar la subcategoría "${s.nombre}"? No se podrá deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Sí, eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.eliminarSubcategoria(s.idSubcategoria);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategoría eliminada correctamente')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _abrirFormulario({Subcategoria? existente}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioSubcategoria(
        idCategoria: widget.idCategoria,
        existente: existente,
      ),
    );
    if (guardado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subcategorías — ${widget.nombreCategoria}'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _subcategorias.isEmpty,
        mensajeVacio: 'Sin subcategorías todavía',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            itemCount: _subcategorias.length,
            itemBuilder: (ctx, i) {
              final s = _subcategorias[i];
              final activo = s.estado == 'ACTIVO';
              return ListTile(
                title: Text(s.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.descripcion?.isNotEmpty == true
                    ? s.descripcion!
                    : 'Sin descripción'),
                leading: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: activo ? AppColors.verde : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activo ? 'ACTIVO' : 'INACTIVO',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.blueGrey,
                      onPressed: () => _abrirFormulario(existente: s),
                    ),
                    IconButton(
                      icon: Icon(
                          activo
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      color: activo ? Colors.orange : AppColors.verde,
                      onPressed: () => _toggleEstado(s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      onPressed: () => _eliminar(s),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        onPressed: () => _abrirFormulario(),
      ),
    );
  }
}

class _FormularioSubcategoria extends StatefulWidget {
  final int idCategoria;
  final Subcategoria? existente;
  const _FormularioSubcategoria({required this.idCategoria, this.existente});

  @override
  State<_FormularioSubcategoria> createState() =>
      _FormularioSubcategoriaState();
}

class _FormularioSubcategoriaState extends State<_FormularioSubcategoria> {
  final _service = CategoriaService();
  late final _nombreCtrl =
      TextEditingController(text: widget.existente?.nombre ?? '');
  late final _descripcionCtrl =
      TextEditingController(text: widget.existente?.descripcion ?? '');
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.existente != null;

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un nombre para la subcategoría');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (_esEdicion) {
        await _service.actualizarSubcategoria(
          id: widget.existente!.idSubcategoria,
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          estado: widget.existente!.estado,
        );
      } else {
        await _service.crearSubcategoria(
          idCategoria: widget.idCategoria,
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
        );
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _esEdicion ? 'Guardar cambios' : 'Nueva subcategoría',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CampoTexto(
              controller: _nombreCtrl,
              hint: 'Nombre',
              icono: Icons.label_outline),
          const SizedBox(height: 12),
          CampoTexto(
              controller: _descripcionCtrl,
              hint: 'Descripción (opcional)',
              icono: Icons.description_outlined),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          BotonPrincipal(
            texto: _esEdicion ? 'Guardar cambios' : 'Agregar',
            cargando: _guardando,
            onPressed: _guardar,
          ),
        ],
      ),
    );
  }
}
