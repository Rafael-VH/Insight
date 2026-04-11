import 'package:flutter/material.dart';

// ==================== DATA MODELS ====================

/// Entrada de datos para el gráfico de barras de rendimiento
class BarEntry {
  const BarEntry(this.label, this.rawValue, this.maxValue, this.color);

  final String label;
  final double rawValue;
  final double maxValue;
  final Color color;
}

/// Entrada de datos para el gráfico de torta de economía
class PieEntry {
  const PieEntry(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

// ==================== SHARED WIDGETS ====================

/// Título de sección con icono
class ChartSectionTitle extends StatelessWidget {
  const ChartSectionTitle({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Tarjeta contenedora para cada gráfico
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
    );
  }
}

/// Píldora de estadística individual para el header de resumen
class StatPill extends StatelessWidget {
  const StatPill(this.label, this.value, this.color, {super.key});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

/// Chip de leyenda para el radar de logros
class LegendChip extends StatelessWidget {
  const LegendChip({super.key, required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
