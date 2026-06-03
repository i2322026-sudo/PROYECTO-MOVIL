import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanearProductoScreen extends StatefulWidget {
  const ScanearProductoScreen({super.key});

  @override
  State<ScanearProductoScreen> createState() => _ScanearProductoScreenState();
}

class _ScanearProductoScreenState extends State<ScanearProductoScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _escaneado = false;

  void _onDetect(BarcodeCapture capture) {
    if (_escaneado) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _escaneado = true);
    _controller.stop();

    final codigo = barcode!.rawValue!;
    Navigator.pop(context, codigo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B9B5E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Escanear código',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(),
          ),
          Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF1B9B5E),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 32),
                const SizedBox(height: 10),
                Text(
                  _escaneado
                      ? 'Código detectado ✓'
                      : 'Apunta al código de barras del producto',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const rectWidth  = 260.0;
    const rectHeight = 180.0;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width:  rectWidth,
      height: rectHeight,
    );

    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, rect.top), paint);
    canvas.drawRect(Rect.fromLTRB(0, rect.bottom, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTRB(0, rect.top, rect.left, rect.bottom), paint);
    canvas.drawRect(Rect.fromLTRB(rect.right, rect.top, size.width, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}