import 'package:flutter/material.dart';
import 'package:movil/models/animal_model.dart';
import 'package:movil/services/animal_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';
import 'package:movil/widgets/exportar_menu_button.dart';

// ─────────────────────────────────────────────────────────────
//  AnimalesScreen — mismo CRUD que la sección "Animales" del
//  dashboard web, en formulario a pantalla completa.
// ─────────────────────────────────────────────────────────────
class AnimalesScreen extends StatefulWidget {
  const AnimalesScreen({super.key});

  @override
  State<AnimalesScreen> createState() => _AnimalesScreenState();
}

class _AnimalesScreenState extends State<AnimalesScreen> {
  final _service = AnimalService();
  List<TipoAnimal> _animales = [];
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
      final lista = await _service.getAnimales();
      setState(() {
        _animales = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _eliminar(TipoAnimal a) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tipo de animal'),
        content: Text('¿Seguro que deseas eliminar "${a.nombre}"?'),
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
      await _service.eliminar(a.idTipoAnimal);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Animal eliminado')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _abrirFormulario({TipoAnimal? existente}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioAnimal(animal: existente),
    );
    if (guardado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de Animal'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: [
          const ExportarMenuButton(
              entidad: 'animales', nombreArchivo: 'tipos_de_animal'),
          // "+ Nuevo Animal" en el encabezado, igual que el botón de
          // la web (antes era un FloatingActionButton flotando abajo).
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo Animal',
            onPressed: () => _abrirFormulario(),
          ),
        ],
      ),
      body: EstadoLista(
        cargando: _cargando,
        error: _error,
        vacio: _animales.isEmpty,
        mensajeVacio: 'No hay tipos de animal registrados',
        onReintentar: _cargar,
        builder: () => RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            itemCount: _animales.length,
            itemBuilder: (ctx, i) {
              final a = _animales[i];
              final esMayor = a.grupo == 'MAYOR';
              final activo = a.estado == 'ACTIVO';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.verde.withOpacity(0.12),
                  child: const Icon(Icons.pets, color: AppColors.verde),
                ),
                title: Text(a.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      // Badge de Grupo — mismo color que la tabla web:
                      // celeste "Animal Menor", ámbar "Animal Mayor".
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: esMayor
                              ? Colors.amber.shade700
                              : Colors.lightBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          esMayor ? 'Animal Mayor' : 'Animal Menor',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (op) {
                    if (op == 'editar') _abrirFormulario(existente: a);
                    if (op == 'eliminar') _eliminar(a);
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
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

class _FormularioAnimal extends StatefulWidget {
  final TipoAnimal? animal;
  const _FormularioAnimal({this.animal});

  @override
  State<_FormularioAnimal> createState() => _FormularioAnimalState();
}

class _FormularioAnimalState extends State<_FormularioAnimal> {
  final _service = AnimalService();
  late final _nombreCtrl =
      TextEditingController(text: widget.animal?.nombre ?? '');
  // Por defecto 'MENOR' al crear, igual que mostrarModalAnimal() en
  // dashboard.js (ani-grupo.value = 'MENOR').
  late String _grupo = widget.animal?.grupo ?? 'MENOR';
  late String _estado = widget.animal?.estado ?? 'ACTIVO';
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.animal != null;

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final animal = TipoAnimal(
      idTipoAnimal: widget.animal?.idTipoAnimal ?? 0,
      nombre: _nombreCtrl.text.trim(),
      grupo: _grupo,
      // El estado solo se puede cambiar al editar — al crear siempre
      // arranca ACTIVO, igual que guardarAnimal() en dashboard.js.
      estado: _esEdicion ? _estado : 'ACTIVO',
    );

    try {
      if (widget.animal != null) {
        await _service.actualizar(animal.idTipoAnimal, animal);
      } else {
        await _service.crear(animal);
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
            widget.animal != null ? 'Editar Tipo de Animal' : 'Nuevo Tipo de Animal',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CampoTexto(
              controller: _nombreCtrl,
              hint: 'Nombre (ej: Perro, Gato, Ave)',
              icono: Icons.pets),
          const SizedBox(height: 16),
          const Text('Grupo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _grupo,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'MENOR', child: Text('Animal Menor')),
              DropdownMenuItem(value: 'MAYOR', child: Text('Animal Mayor')),
            ],
            onChanged: (v) => setState(() => _grupo = v ?? 'MENOR'),
          ),
          const SizedBox(height: 6),
          Text(
            'Define en qué desplegable aparece en el catálogo y en el '
            'formulario de productos.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          // El Estado solo se puede cambiar al EDITAR — al crear un
          // tipo de animal nuevo siempre arranca ACTIVO, igual que
          // el modal web (campo-ani-estado oculto en creación).
          if (_esEdicion) ...[
            const SizedBox(height: 16),
            const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _estado,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
              ],
              onChanged: (v) => setState(() => _estado = v ?? 'ACTIVO'),
            ),
          ],
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
