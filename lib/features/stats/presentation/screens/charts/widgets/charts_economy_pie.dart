import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:intl/intl.dart';

import 'charts_shared_widgets.dart';

class ChartsEconomyPie extends StatefulWidget {
  const ChartsEconomyPie({super.key, required this.stats});

  final PlayerStats stats;

  @override
  State<ChartsEconomyPie> createState() => _ChartsEconomyPieState();
}

class _ChartsEconomyPieState extends State<ChartsEconomyPie> {
  int _touchedIndex = -1;

  List<PieEntry> get _entries => [
    PieEntry('Oro/Min', widget.stats.goldPerMin.toDouble(), const Color(0xFFF59E0B)),
    PieEntry('Daño Héroe/Min', widget.stats.heroDamagePerMin.toDouble(), const Color(0xFFDC2626)),
    PieEntry('Daño Torre/P', widget.stats.towerDamagePerGame.toDouble(), const Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = _entries;
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    if (total == 0) {
      return ChartCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'Sin datos de economía',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ),
      );
    }

    return ChartCard(
      child: Row(
        children: [
          Expanded(child: _buildPieChart(entries, total)),
          const SizedBox(width: 16),
          _buildLegend(entries, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<PieEntry> entries, double total) {
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              final idx = response?.touchedSection?.touchedSectionIndex ?? -1;
              if (_touchedIndex != idx) {
                setState(() => _touchedIndex = idx);
              }
            },
          ),
          sectionsSpace: 3,
          centerSpaceRadius: 32,
          sections: entries.asMap().entries.map((e) {
            final isTouched = e.key == _touchedIndex;
            final pct = (e.value.value / total * 100);
            return PieChartSectionData(
              value: e.value.value,
              color: e.value.color,
              radius: isTouched ? 65 : 55,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend(List<PieEntry> entries, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        NumberFormat.compact().format(e.value),
                        style: TextStyle(fontSize: 14, color: e.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
