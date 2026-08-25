import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movil/services/reporte_service.dart';

// ─────────────────────────────────────────────────────────────
//  ExportarMenuButton — botón "Exportar" reutilizable para el
//  encabezado de cualquier pantalla de listado (Categorías,
//  Animales, Clientes, Colaboradores, ...). Usa el mismo endpoint
//  genérico que ya soporta el backend:
//  GET /api/reportes/exportar/:entidad/:formato (excel | pdf).
// ─────────────────────────────────────────────────────────────
class ExportarMenuButton extends StatefulWidget {
  /// Debe coincidir con las entidades que acepta reporte.routes.js:
  /// productos, clientes, pedidos, categorias, animales, colaboradores.
  final String entidad;
  final String nombreArchivo;
  const ExportarMenuButton({
    super.key,
    required this.entidad,
    required this.nombreArchivo,
  });

  @override
  State<ExportarMenuButton> createState() => _ExportarMenuButtonState();
}

class _ExportarMenuButtonState extends State<ExportarMenuButton> {
  final _service = ReporteService();
  bool _exportando = false;

  Future<void> _exportar(String formato) async {
    setState(() => _exportando = true);
    try {
      final bytes = await _service.exportar(widget.entidad, formato);
      final esExcel = formato == 'excel';
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: '${widget.nombreArchivo}.${esExcel ? 'xlsx' : 'pdf'}',
          mimeType: esExcel
              ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
              : 'application/pdf',
        ),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exportando) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download_outlined, color: Colors.white),
      tooltip: 'Exportar',
      onSelected: _exportar,
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 'excel', child: Text('Exportar Excel')),
        PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
      ],
    );
  }
}
