import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movil/services/pedido_service.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  EvidenciaCancelacionScreen — acceso rápido para el repartidor:
//  1) Busca el pedido por su N° de boleta/factura
//     (GET /api/pedidos/buscar-codigo/:codigo).
//  2) Toma/elige una foto de evidencia (cliente ausente, rechazó
//     el producto, etc.).
//  3) Al confirmar, PUT /api/pedidos/:id/evidencia-cancelacion sube
//     la foto a R2 y marca el pedido como CANCELADO en un solo paso.
// ─────────────────────────────────────────────────────────────
class EvidenciaCancelacionScreen extends StatefulWidget {
  const EvidenciaCancelacionScreen({super.key});

  @override
  State<EvidenciaCancelacionScreen> createState() =>
      _EvidenciaCancelacionScreenState();
}

class _EvidenciaCancelacionScreenState
    extends State<EvidenciaCancelacionScreen> {
  final _service = PedidoService();
  final _codigoCtrl = TextEditingController();

  bool _buscando = false;
  bool _enviando = false;
  String? _error;
  Map<String, dynamic>? _pedido;

  Uint8List? _fotoBytes;
  String? _fotoNombre;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarPedido() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      setState(() => _error = 'Ingresa el N° de boleta o factura');
      return;
    }
    setState(() {
      _buscando = true;
      _error = null;
      _pedido = null;
      _fotoBytes = null;
      _fotoNombre = null;
    });
    try {
      final pedido = await _service.buscarPorCodigo(codigo);
      setState(() {
        _pedido = pedido;
        _buscando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _buscando = false;
      });
    }
  }

  Future<void> _tomarFoto({required bool camara}) async {
    final XFile? archivo = await ImagePicker().pickImage(
      source: camara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (archivo == null) return;
    final bytes = await archivo.readAsBytes();
    setState(() {
      _fotoBytes = bytes;
      _fotoNombre = archivo.name;
    });
  }

  Future<void> _confirmarCancelacion() async {
    if (_pedido == null || _fotoBytes == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
          '¿Confirmas cancelar el pedido ${_pedido!['comprobante'] ?? '#${_pedido!['id_pedido']}'} '
          'con esta foto como evidencia?\n\nEsta acción cambia su estado a CANCELADO.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await _service.subirEvidenciaCancelacion(
        idPedido: _pedido!['id_pedido'] as int,
        bytes: _fotoBytes!,
        nombreArchivo: _fotoNombre ?? 'evidencia.jpg',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pedido cancelado con evidencia guardada'),
      ));
      setState(() {
        _pedido = null;
        _fotoBytes = null;
        _fotoNombre = null;
        _codigoCtrl.clear();
        _enviando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              'Busca el pedido por su N° de boleta/factura, sube una '
              'foto de evidencia (cliente ausente, rechazó el producto, '
              'etc.) y el pedido quedará marcado como CANCELADO.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Ej. F001-000065',
                      prefixIcon: const Icon(Icons.receipt_long_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _buscarPedido(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _buscando ? null : _buscarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                  ),
                  child: _buscando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_pedido != null) ...[
              const SizedBox(height: 20),
              _tarjetaPedido(),
              const SizedBox(height: 20),
              _seccionFoto(),
            ],
          ],
        ),
    );
  }

  Widget _tarjetaPedido() {
    final p = _pedido!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedido #${p['id_pedido']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text((p['comprobante'] ?? '-').toString()),
          const SizedBox(height: 6),
          Text('Cliente: ${p['cliente'] ?? '-'}'),
          Text('Entrega: ${p['tipo_entrega'] ?? '-'}'),
          Row(
            children: [
              const Text('Estado actual: '),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.verde.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text((p['estado'] ?? '-').toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.verde)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccionFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto de evidencia',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_fotoBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_fotoBytes!,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tomarFoto(camara: true),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tomarFoto(camara: false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                (_fotoBytes == null || _enviando) ? null : _confirmarCancelacion,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cancel_outlined),
            label: Text(_enviando ? 'Guardando...' : 'Cancelar pedido'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
