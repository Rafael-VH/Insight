import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';

import 'charts_shared_widgets.dart';

class ChartsSummaryHeader extends StatelessWidget {
  const ChartsSummaryHeader({super.key, required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final color = stats.mode.color;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.04)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeLabel(context, color),
            const SizedBox(height: 16),
            _buildStatsRow(color),
          ],
        ),
      ),
    );
  }

  Widget _buildModeLabel(BuildContext context, Color color) {
    return Row(
      children: [
        Icon(stats.mode.icon, color: color, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            stats.mode.fullDisplayName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StatPill('Partidas', stats.totalGames.toString(), color),
        StatPill('Win%', '${stats.winRate.toStringAsFixed(1)}%', color),
        StatPill('KDA', stats.kda.toStringAsFixed(2), color),
        StatPill('MVP', stats.mvpCount.toString(), color),
      ],
    );
  }
}
