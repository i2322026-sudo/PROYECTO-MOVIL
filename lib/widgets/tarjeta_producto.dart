import 'package:flutter/material.dart';
import '../models/producto_model.dart';
import '../services/api_config.dart';
import 'package:movil/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  TarjetaProducto — calcada de la fila "Inventario de Productos"
//  del panel web real: iconos SIEMPRE visibles (no escondidos en
//  un menú), con el mismo orden: [ficha técnica opcional] editar,
//  activar/desactivar (cambia de color según el estado actual),
//  eliminar.
// ─────────────────────────────────────────────────────────────
class TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final VoidCallback? onToggleEstado;
  final VoidCallback? onVerFicha;

  const TarjetaProducto({
    super.key,
    required this.producto,
    this.onTap,
    this.onEditar,
    this.onEliminar,
    this.onToggleEstado,
    this.onVerFicha,
  });

  /// true si el producto trae información de ficha técnica
  /// (marca, composición, modo de uso, etc.) — típico en
  /// medicamentos — igual que el ícono extra que muestra la web.
  bool get _tieneFichaTecnica =>
      (producto.fichaTecnica?.isNotEmpty ?? false) ||
      (producto.composicion?.isNotEmpty ?? false) ||
      (producto.modoUso?.isNotEmpty ?? false);

  /// Miniatura circular con la imagen real del producto (misma
  /// resolución de URL que dashboard.js: completa tal cual, o
  /// /img/productos/<archivo> del backend). Si no hay imagen, o la
  /// URL falla al cargar (archivo borrado, sin internet, etc.), cae
  /// al mismo ícono verde de reemplazo que ya se usaba antes —
  /// nunca deja un hueco en blanco.
  Widget _miniaturaProducto() {
    final url = ApiConfig.urlImagen(producto.imagen);
    final fondo = AppColors.verde.withOpacity(0.12);

    if (url == null) {
      return CircleAvatar(
        backgroundColor: fondo,
        child: const Icon(Icons.inventory_2_outlined, color: AppColors.verde),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progreso) {
          if (progreso == null) return child;
          return Container(
            width: 40,
            height: 40,
            color: fondo,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.verde),
            ),
          );
        },
        errorBuilder: (ctx, error, stack) => Container(
          width: 40,
          height: 40,
          color: fondo,
          child: const Icon(Icons.inventory_2_outlined,
              color: AppColors.verde, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activo = producto.estado == 'ACTIVO';
    final archivado = producto.estado == 'ARCHIVADO';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  _miniaturaProducto(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                producto.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (archivado)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Archivado',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white)),
                              )
                            else if (!activo)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Inactivo',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700)),
                              ),
                          ],
                        ),
                        Text(producto.categoria ?? 'Sin categoría'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'S/. ${producto.precioVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.verde,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Text('Stock: ${producto.stockActual}'),
                            const SizedBox(width: 8),
                            if (producto.stockBajo)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Text('Stock bajo',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red.shade700)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: archivado
                  ? [
                      // Un producto archivado solo se puede "Restaurar"
                      // (vuelve a ACTIVO) — no tiene sentido ofrecer
                      // Editar/Desactivar/Eliminar sobre algo que ya
                      // está fuera de circulación (igual que dashboard.js).
                      if (onToggleEstado != null)
                        IconButton(
                          icon: const Icon(Icons.restore, size: 20),
                          color: AppColors.verde,
                          tooltip: 'Restaurar producto',
                          onPressed: onToggleEstado,
                        ),
                    ]
                  : [
                      if (_tieneFichaTecnica)
                        IconButton(
                          icon: const Icon(Icons.description_outlined,
                              size: 20),
                          color: Colors.blue,
                          tooltip: 'Ver instrucciones',
                          onPressed: onVerFicha,
                        ),
                      if (onEditar != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.blueGrey,
                          tooltip: 'Editar',
                          onPressed: onEditar,
                        ),
                      if (onToggleEstado != null)
                        IconButton(
                          icon: Icon(
                            activo
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          color: activo ? Colors.orange : Colors.blueGrey,
                          tooltip: activo ? 'Desactivar' : 'Activar',
                          onPressed: onToggleEstado,
                        ),
                      if (onEliminar != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          tooltip: 'Eliminar',
                          onPressed: onEliminar,
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
