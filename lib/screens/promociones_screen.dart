import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movil/services/promocion_service.dart';
import 'package:movil/services/dashboard_service.dart';
import 'package:movil/services/cliente_service.dart';
import 'package:movil/models/cliente_model.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  PromocionesScreen — calcada de public/promociones.html:
//  Correo destinatario (opcional) / Asunto * / Mensaje / Imagen
//  promocional (opcional) → POST /api/auth/enviar-promocion.
//  Si el correo queda vacío, el backend la manda a TODOS los
//  clientes registrados (igual que la web).
//
//  Agregado: sección "Top clientes" — trae GET
//  /api/dashboard/top-clientes (nuevo endpoint, mismo patrón que
//  "Productos más vendidos") y permite elegir con checkboxes a
//  cuáles de los que más compran mandarles la promoción, en vez
//  de a todos o a uno solo escrito a mano.
// ─────────────────────────────────────────────────────────────
class PromocionesScreen extends StatefulWidget {
  const PromocionesScreen({super.key});

  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  final _service = PromocionService();
  final _dashboardService = DashboardService();
  final _clienteService = ClienteService();

  final _correoCtrl = TextEditingController();
  final _asuntoCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();

  Uint8List? _imagenBytes;
  String? _imagenNombre;
  bool _enviando = false;
  String? _error;
  String? _exito;
  int _progresoEnviados = 0;
  int _progresoTotal = 0;

  List<Map<String, dynamic>> _topClientes = [];
  bool _cargandoTop = true;
  final Set<String> _seleccionados = {};

  List<Cliente> _todosClientes = [];
  bool _cargandoTodos = true;

  @override
  void initState() {
    super.initState();
    _cargarTopClientes();
    _cargarTodosClientes();
  }

  Future<void> _cargarTodosClientes() async {
    try {
      final lista = await _clienteService.getClientes();
      setState(() {
        _todosClientes = lista;
        _cargandoTodos = false;
      });
    } catch (_) {
      // Si falla, no se muestra la sección — el resto del formulario
      // (Top clientes, correo manual, enviar a todos) sigue funcionando.
      setState(() => _cargandoTodos = false);
    }
  }

  Future<void> _cargarTopClientes() async {
    try {
      final lista = await _dashboardService.getTopClientes(limite: 10);
      setState(() {
        _topClientes = lista;
        _cargandoTop = false;
      });
    } catch (e) {
      // Antes esto se tragaba el error en silencio (catch (_)) — ahora
      // se muestra, porque un error silencioso es indistinguible de
      // "trajo pocos resultados a propósito".
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar top clientes: $e')),
        );
      }
      setState(() => _cargandoTop = false);
    }
  }

  Future<void> _elegirImagen() async {
    final XFile? archivo = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (archivo == null) return;
    final bytes = await archivo.readAsBytes();
    setState(() {
      _imagenBytes = bytes;
      _imagenNombre = archivo.name;
    });
  }

  Future<void> _enviar() async {
    if (_asuntoCtrl.text.trim().isEmpty || _mensajeCtrl.text.trim().isEmpty) {
      setState(() {
        _error = 'Completa el asunto y el mensaje';
        _exito = null;
      });
      return;
    }

    // Si hay clientes del Top 10 marcados, tienen prioridad sobre
    // el campo de correo manual — se manda uno por uno a esos.
    if (_seleccionados.isNotEmpty) {
      await _enviarASeleccionados();
      return;
    }

    final destinatario = _correoCtrl.text.trim();
    if (destinatario.isEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enviar a todos los clientes'),
          content: const Text(
              'Dejaste el correo vacío: esta promoción se va a enviar a TODOS los clientes registrados. ¿Confirmas?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enviar a todos')),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() {
      _enviando = true;
      _error = null;
      _exito = null;
    });

    try {
      await _service.enviar(
        correo: destinatario.isEmpty ? null : destinatario,
        asunto: _asuntoCtrl.text.trim(),
        mensaje: _mensajeCtrl.text.trim(),
        imagenBytes: _imagenBytes,
        imagenNombre: _imagenNombre,
      );
      if (!mounted) return;
      setState(() {
        _exito = '¡Promoción enviada correctamente!';
        _enviando = false;
      });
      _limpiarFormulario();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
      });
    }
  }

  Future<void> _enviarASeleccionados() async {
    final correos = _seleccionados.toList();
    setState(() {
      _enviando = true;
      _error = null;
      _exito = null;
      _progresoEnviados = 0;
      _progresoTotal = correos.length;
    });

    final fallidos = await _service.enviarAVarios(
      correos: correos,
      asunto: _asuntoCtrl.text.trim(),
      mensaje: _mensajeCtrl.text.trim(),
      imagenBytes: _imagenBytes,
      imagenNombre: _imagenNombre,
      onProgreso: (enviados, total) {
        if (!mounted) return;
        setState(() => _progresoEnviados = enviados);
      },
    );

    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (fallidos.isEmpty) {
        _exito =
            '¡Promoción enviada a ${correos.length} cliente${correos.length == 1 ? '' : 's'}!';
      } else {
        _error =
            'Se enviaron ${correos.length - fallidos.length} de ${correos.length}. Fallaron: ${fallidos.join(', ')}';
      }
      _seleccionados.clear();
    });
    if (fallidos.isEmpty) _limpiarFormulario();
  }

  void _limpiarFormulario() {
    _correoCtrl.clear();
    _asuntoCtrl.clear();
    _mensajeCtrl.clear();
    setState(() {
      _imagenBytes = null;
      _imagenNombre = null;
    });
  }

  double _totalGastado(Map<String, dynamic> c) =>
      double.tryParse(c['total_gastado'].toString()) ?? 0.0;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _asuntoCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_cargandoTop && _topClientes.isNotEmpty) ...[
            const Text('Top clientes (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              'Marca a quién de tus mejores clientes le querés mandar esta promo. Si marcás alguno, tiene prioridad sobre "Correo destinatario".',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _topClientes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final correo = (c['correo'] ?? '').toString();
                  final marcado = _seleccionados.contains(correo);
                  return CheckboxListTile(
                    value: marcado,
                    dense: true,
                    activeColor: AppColors.verde,
                    onChanged: correo.isEmpty
                        ? null
                        : (v) => setState(() {
                              if (v == true) {
                                _seleccionados.add(correo);
                              } else {
                                _seleccionados.remove(correo);
                              }
                            }),
                    title: Text('#${i + 1} ${c['nombres'] ?? correo}',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${correo.isEmpty ? 'Sin correo' : correo} · ${c['total_pedidos']} pedido(s) · S/. ${_totalGastado(c).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!_cargandoTodos && _todosClientes.isNotEmpty) ...[
            const Text('Todos los clientes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              'Lista completa de clientes registrados (${_todosClientes.length}). Marcar aquí también tiene prioridad sobre "Correo destinatario".',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  children: _todosClientes.map((c) {
                    final correo = c.correo ?? '';
                    final marcado = _seleccionados.contains(correo);
                    return CheckboxListTile(
                      value: marcado,
                      dense: true,
                      activeColor: AppColors.verde,
                      onChanged: correo.isEmpty
                          ? null
                          : (v) => setState(() {
                                if (v == true) {
                                  _seleccionados.add(correo);
                                } else {
                                  _seleccionados.remove(correo);
                                }
                              }),
                      title: Text(c.nombres,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        correo.isEmpty ? 'Sin correo registrado' : correo,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Correo destinatario (opcional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          CampoTexto(
            controller: _correoCtrl,
            hint: 'Vacío = enviar a todos los clientes',
            icono: Icons.email_outlined,
            teclado: TextInputType.emailAddress,
            soloLectura: _seleccionados.isNotEmpty,
          ),
          const SizedBox(height: 16),
          const Text('Asunto del correo *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          CampoTexto(
            controller: _asuntoCtrl,
            hint: 'Ej: ¡20% de descuento este fin de semana!',
            icono: Icons.subject,
          ),
          const SizedBox(height: 16),
          const Text('Mensaje de la promoción',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _mensajeCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Escribe el contenido de la promoción...',
              filled: true,
              fillColor: AppColors.fondoClaro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Imagen promocional (opcional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          if (_imagenBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imagenBytes!,
                  height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _elegirImagen,
            icon: const Icon(Icons.image_outlined),
            label: Text(
                _imagenBytes == null ? 'Seleccionar imagen' : 'Cambiar imagen'),
          ),
          if (_enviando && _progresoTotal > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progresoEnviados / _progresoTotal,
              color: AppColors.verde,
            ),
            const SizedBox(height: 4),
            Text('Enviando $_progresoEnviados de $_progresoTotal...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ],
          if (_exito != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_exito!,
                  style: const TextStyle(color: AppColors.verde)),
            ),
          ],
          const SizedBox(height: 20),
          BotonPrincipal(
            texto: _seleccionados.isEmpty
                ? 'Enviar promoción'
                : 'Enviar a ${_seleccionados.length} cliente${_seleccionados.length == 1 ? '' : 's'}',
            cargando: _enviando,
            onPressed: _enviar,
          ),
        ],
      ),
    );
  }
}
