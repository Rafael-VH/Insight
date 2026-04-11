import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:insight/features/parser/domain/entities/player_stats.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';

import 'charts_shared_widgets.dart';

class ChartsAchievementsRadar extends StatelessWidget {
  const ChartsAchievementsRadar({super.key, required this.stats});

  final PlayerStats stats;

  static double _norm(num value, num maxRef) {
    if (maxRef <= 0) return 0.0;
    return (value / maxRef * 10.0).clamp(0.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = stats.mode.color;
    final colorScheme = Theme.of(context).colorScheme;
    final totalGames = stats.totalGames > 0 ? stats.totalGames : 1;

    final labels = [
      'Legendario',
      'Savage',
      'Maniac',
      'Triple Kill',
      'Doble Kill',
      'Primera Sangre',
    ];

    final rawValues = [
      stats.legendary,
      stats.savage,
      stats.maniac,
      stats.tripleKill,
      stats.doubleKill,
      stats.firstBlood,
    ];

    final normalizedValues = [
      _norm(stats.legendary, 10),
      _norm(stats.savage, 5),
      _norm(stats.maniac, 20),
      _norm(stats.tripleKill, 30),
      _norm(stats.doubleKill, 50),
      _norm(stats.firstBlood, totalGames),
    ];

    final allZero = normalizedValues.every((v) => v == 0.0);

    return ChartCard(
      child: Column(
        children: [
          if (allZero)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'Sin logros registrados',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: [
                    RadarDataSet(
                      dataEntries: normalizedValues.map((v) => RadarEntry(value: v)).toList(),
                      fillColor: color.withValues(alpha: 0.2),
                      borderColor: color,
                      borderWidth: 2,
                      entryRadius: 3,
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  gridBorderData: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                  getTitle: (index, angle) => RadarChartTitle(text: labels[index], angle: 0),
                  titleTextStyle: TextStyle(fontSize: 10, color: colorScheme.onSurface),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(
              labels.length,
              (i) => LegendChip(label: labels[i], value: rawValues[i].toString(), color: color),
            ),
          ),
        ],
      ),
    );
  }
}
