import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  EstadoLista — maneja los 3 estados típicos al cargar datos
//  desde la API: cargando, error, o lista vacía. Si ninguno
//  aplica, muestra el contenido real (`builder`).
//
//  Uso:
//    EstadoLista(
//      cargando: _cargando,
//      error: _error,
//      vacio: _items.isEmpty,
//      mensajeVacio: 'No hay pedidos pendientes',
//      onReintentar: _cargarDatos,
//      builder: () => ListView(...),
//    )
// ─────────────────────────────────────────────────────────────
class EstadoLista extends StatelessWidget {
  final bool cargando;
  final String? error;
  final bool vacio;
  final String mensajeVacio;
  final VoidCallback? onReintentar;
  final Widget Function() builder;

  const EstadoLista({
    super.key,
    required this.cargando,
    required this.builder,
    this.error,
    this.vacio = false,
    this.mensajeVacio = 'No hay datos por mostrar',
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && error!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              if (onReintentar != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onReintentar,
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (vacio) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 48),
              const SizedBox(height: 12),
              Text(
                mensajeVacio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return builder();
  }
}
