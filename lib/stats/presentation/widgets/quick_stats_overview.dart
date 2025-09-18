// lib/features/ml_stats/presentation/widgets/quick_stats_overview.dart
import 'package:flutter/material.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';

class QuickStatsOverview extends StatelessWidget {
  const QuickStatsOverview({super.key, required this.collection});

  final StatsCollection collection;

  @override
  Widget build(BuildContext context) {
    final totalStats = collection.totalStats;

    if (totalStats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat(
                'Partidas',
                totalStats.totalGames.toString(),
                Icons.sports_esports,
              ),
              _buildOverviewStat(
                'Win Rate',
                '${totalStats.winRate.toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
              _buildOverviewStat(
                'KDA',
                totalStats.kda.toStringAsFixed(2),
                Icons.speed,
              ),
              _buildOverviewStat(
                'MVP',
                totalStats.mvpCount.toString(),
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }
}
