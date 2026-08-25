import 'package:flutter/material.dart';
import 'package:movil/models/categoria_model.dart';
import 'package:movil/services/categoria_service.dart';
import 'package:movil/screens/subcategorias_screen.dart';
import 'package:movil/widgets/exportar_menu_button.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  CategoriasScreen — mismo CRUD que la sección "Categorías"
//  del dashboard web, pero en un formulario a pantalla completa
//  en vez de un modal (mejor para móvil).
// ─────────────────────────────────────────────────────────────
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _service = CategoriaService();
  List<Categoria> _categorias = [];
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
      final lista = await _service.getCategorias();
      setState(() {
        _categorias = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _eliminar(Categoria c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Seguro que deseas eliminar "${c.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.eliminar(c.idCategoria);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _abrirFormulario({Categoria? existente}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioCategoria(categoria: existente),
    );
    if (guardado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: [
          const ExportarMenuButton(
              entidad: 'categorias', nombreArchivo: 'categorias'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Categoría',
            onPressed: () => _abrirFormulario(),
          ),
        ],
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _categorias.isEmpty,
        mensajeVacio: 'No hay categorías registradas',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            itemCount: _categorias.length,
            itemBuilder: (ctx, i) {
              final c = _categorias[i];
              final activo = c.estado == 'ACTIVO';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.verde.withOpacity(0.12),
                  child: const Icon(Icons.category_outlined,
                      color: AppColors.verde),
                ),
                title: Text(c.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.descripcion?.isNotEmpty == true
                        ? c.descripcion!
                        : 'Sin descripción'),
                    const SizedBox(height: 4),
                    // Badge de Estado — igual que la columna "ESTADO"
                    // de la tabla web.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: activo ? AppColors.verde : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activo ? 'ACTIVO' : 'INACTIVO',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón "Subcategorías" — igual que el botón verde
                    // de la tabla web, abre el CRUD de subcategorías
                    // de ESTA categoría puntual.
                    IconButton(
                      icon: const Icon(Icons.account_tree_outlined,
                          color: AppColors.verde),
                      tooltip: 'Subcategorías',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubcategoriasScreen(
                            idCategoria: c.idCategoria,
                            nombreCategoria: c.nombre,
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (op) {
                        if (op == 'editar') _abrirFormulario(existente: c);
                        if (op == 'eliminar') _eliminar(c);
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(
                            value: 'eliminar', child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FormularioCategoria extends StatefulWidget {
  final Categoria? categoria;
  const _FormularioCategoria({this.categoria});

  @override
  State<_FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<_FormularioCategoria> {
  final _service = CategoriaService();
  late final _nombreCtrl =
      TextEditingController(text: widget.categoria?.nombre ?? '');
  late final _descripcionCtrl =
      TextEditingController(text: widget.categoria?.descripcion ?? '');
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final categoria = Categoria(
      idCategoria: widget.categoria?.idCategoria ?? 0,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      estado: 'ACTIVO',
    );

    try {
      if (widget.categoria != null) {
        await _service.actualizar(categoria.idCategoria, categoria);
      } else {
        await _service.crear(categoria);
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
            widget.categoria != null ? 'Editar Categoría' : 'Nueva Categoría',
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
              hint: 'Descripción',
              icono: Icons.notes),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          BotonPrincipal(
            texto: 'Guardar',
            cargando: _guardando,
            onPressed: _guardar,
          ),
        ],
      ),
    );
  }
}
