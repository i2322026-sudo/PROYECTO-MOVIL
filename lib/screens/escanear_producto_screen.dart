import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:movil/models/producto_model.dart';
import 'package:movil/services/producto_service.dart';
import 'package:movil/widgets/campo_texto.dart';
import 'package:movil/widgets/boton_principal.dart';
import 'package:movil/widgets/tarjeta_producto.dart';
import 'package:movil/screens/detalle_producto_screen.dart';

// ─────────────────────────────────────────────────────────────
//  EscanearProductoScreen — usa la cámara real (mobile_scanner)
//  y GET /api/inventario/buscar-codigo/:codigo, que SÍ existe de
//  verdad en el backend. Ya no hace falta traer todo el
//  inventario y buscar en la app.
// ─────────────────────────────────────────────────────────────
class EscanearProductoScreen extends StatefulWidget {
  const EscanearProductoScreen({super.key});

  @override
  State<EscanearProductoScreen> createState() =>
      _EscanearProductoScreenState();
}

class _EscanearProductoScreenState extends State<EscanearProductoScreen> {
  final _service = ProductoService();
  final _codigoCtrl = TextEditingController();
  final MobileScannerController _camara = MobileScannerController();

  bool _camaraActiva = true;
  bool _buscando = false;
  String? _error;
  Producto? _resultado;

  Future<void> _buscarPorCodigo(String codigo) async {
    if (codigo.trim().isEmpty) return;

    setState(() {
      _buscando = true;
      _error = null;
      _resultado = null;
    });

    try {
      final encontrado = await _service.buscarPorCodigo(codigo.trim());
      setState(() {
        _resultado = encontrado;
        _error = encontrado == null
            ? 'No se encontró ningún producto con el código "$codigo"'
            : null;
        _buscando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _buscando = false;
      });
    }
  }

  void _onDeteccion(BarcodeCapture captura) {
    if (!_camaraActiva || _buscando) return;
    final codigo = captura.barcodes.isNotEmpty
        ? captura.barcodes.first.rawValue
        : null;
    if (codigo == null) return;

    setState(() => _camaraActiva = false);
    _codigoCtrl.text = codigo;
    _buscarPorCodigo(codigo);
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _camara.dispose();
    super.dispose();
  }

  /// Muestra un mensaje claro (en vez del ícono "!" genérico de
  /// mobile_scanner) cuando la cámara no pudo iniciarse — el caso
  /// más común es que el permiso de Cámara esté denegado.
  Widget _errorCamara(MobileScannerException error) {
    final esPermiso = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(
              esPermiso
                  ? 'No hay permiso para usar la cámara.\nActívalo en Ajustes del celular > Apps > ALEVET > Permisos > Cámara.'
                  : 'No se pudo abrir la cámara.\n${error.errorDetails?.message ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _camara.start(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Producto'),
        backgroundColor: const Color(0xFF1B9B5E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_camaraActiva ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _camaraActiva = !_camaraActiva),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _camara,
                  onDetect: _onDeteccion,
                  errorBuilder: (context, error, child) {
                    return _errorCamara(error);
                  },
                ),
                if (!_camaraActiva)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text('Cámara en pausa',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('O ingresa el código manualmente',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  CampoTexto(
                      controller: _codigoCtrl,
                      hint: 'Ej: ABC123',
                      icono: Icons.barcode_reader),
                  const SizedBox(height: 10),
                  BotonPrincipal(
                    texto: 'Buscar',
                    cargando: _buscando,
                    onPressed: () => _buscarPorCodigo(_codigoCtrl.text),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_resultado != null) ...[
                    TarjetaProducto(
                      producto: _resultado!,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleProductoScreen(
                              idProducto: _resultado!.idProducto),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleProductoScreen(
                                idProducto: _resultado!.idProducto),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Ver detalle completo'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _resultado = null;
                          _codigoCtrl.clear();
                          _camaraActiva = true;
                        }),
                        icon: const Icon(Icons.barcode_reader),
                        label: const Text('Escanear otro'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
