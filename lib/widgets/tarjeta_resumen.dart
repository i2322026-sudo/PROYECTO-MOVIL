import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  TarjetaResumen — tarjeta pequeña para mostrar una métrica
//  con ícono, número y etiqueta. Pensada para el Dashboard
//  (ej: "Pedidos pendientes: 5", "Stock bajo: 3").
// ─────────────────────────────────────────────────────────────
class TarjetaResumen extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;

  const TarjetaResumen({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color = const Color(0xFF1B9B5E),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
