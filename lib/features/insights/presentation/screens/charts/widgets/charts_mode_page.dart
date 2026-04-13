import 'package:flutter/material.dart';
import 'package:insight/features/parser/domain/entities/player_performance.dart';

import 'charts_achievements_radar.dart';
import 'charts_economy_pie.dart';
import 'charts_performance_bar.dart';
import 'charts_shared_widgets.dart';
import 'charts_summary_header.dart';
import 'charts_win_rate_gauge.dart';

/// Página completa de gráficos para un modo de juego.
/// Compone todos los widgets de chart en un ListView.
class ChartsModeChartsPage extends StatelessWidget {
  const ChartsModeChartsPage({super.key, required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChartsSummaryHeader(stats: stats),
        const SizedBox(height: 20),
        const ChartSectionTitle(title: 'Tasa de Victoria', icon: Icons.emoji_events),
        const SizedBox(height: 8),
        ChartsWinRateGauge(winRate: stats.winRate),
        const SizedBox(height: 20),
        const ChartSectionTitle(title: 'Rendimiento', icon: Icons.bar_chart),
        const SizedBox(height: 8),
        ChartsPerformanceBar(stats: stats),
        const SizedBox(height: 20),
        const ChartSectionTitle(title: 'Logros', icon: Icons.stars_rounded),
        const SizedBox(height: 8),
        ChartsAchievementsRadar(stats: stats),
        const SizedBox(height: 20),
        const ChartSectionTitle(title: 'Economía & Daño por Min', icon: Icons.attach_money_rounded),
        const SizedBox(height: 8),
        ChartsEconomyPie(stats: stats),
        const SizedBox(height: 32),
      ],
    );
  }
}
