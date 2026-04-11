import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';

import 'charts_shared_widgets.dart';

class ChartsPerformanceBar extends StatelessWidget {
  const ChartsPerformanceBar({super.key, required this.stats});

  final PlayerStats stats;

  List<BarEntry> _buildEntries(Color color) {
    final totalGames = stats.totalGames > 0 ? stats.totalGames.toDouble() : 1.0;

    return [
      BarEntry('KDA', stats.kda, 10.0, color),
      BarEntry('Part.%', stats.teamFightParticipation, 100.0, color),
      BarEntry('Muertes/P', stats.deathsPerGame, 10.0, const Color(0xFFDC2626)),
      BarEntry('MVP%', stats.mvpCount / totalGames * 100, 100.0, color),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = stats.mode.color;
    final colorScheme = Theme.of(context).colorScheme;
    final entries = _buildEntries(color);

    return ChartCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black.withValues(alpha: 0.75),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final e = entries[groupIndex];
                      return BarTooltipItem(
                        '${e.label}\n${e.rawValue.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entries[idx].label,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colorScheme.outline.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final normalized = ((e.value.rawValue / e.value.maxValue) * 100).clamp(
                    0.0,
                    100.0,
                  );
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: normalized,
                        color: e.value.color,
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: e.value.color.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: entries
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${e.label}: ${e.rawValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
