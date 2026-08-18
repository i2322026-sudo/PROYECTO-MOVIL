import 'package:flutter/material.dart';
import 'package:movil/models/animal_model.dart';
import 'package:movil/services/animal_service.dart';
import 'package:movil/widgets/estado_lista.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';

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
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1B9B5E).withOpacity(0.12),
                  child: const Icon(Icons.pets, color: Color(0xFF1B9B5E)),
                ),
                title: Text(a.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B9B5E),
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
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

    final animal = TipoAnimal(
      idTipoAnimal: widget.animal?.idTipoAnimal ?? 0,
      nombre: _nombreCtrl.text.trim(),
      estado: 'ACTIVO',
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
