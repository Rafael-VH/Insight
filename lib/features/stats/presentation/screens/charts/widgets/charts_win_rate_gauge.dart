import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'charts_shared_widgets.dart';

class ChartsWinRateGauge extends StatelessWidget {
  const ChartsWinRateGauge({super.key, required this.winRate});

  final double winRate;

  Color _gaugeColor(double pct) {
    if (pct >= 60) return const Color(0xFF059669);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final pct = winRate.clamp(0.0, 100.0);
    final color = _gaugeColor(pct);
    final colorScheme = Theme.of(context).colorScheme;

    return ChartCard(
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                startDegreeOffset: 180,
                sectionsSpace: 2,
                centerSpaceRadius: 55,
                sections: [
                  PieChartSectionData(value: pct, color: color, title: '', radius: 28),
                  PieChartSectionData(
                    value: 100.0 - pct,
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    title: '',
                    radius: 28,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  'Win Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
