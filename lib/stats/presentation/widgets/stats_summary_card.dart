// lib/features/ml_stats/presentation/widgets/stats_summary_card.dart
import 'package:flutter/material.dart';
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';

class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({super.key, required this.stats, this.onTap});

  final PlayerStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getGameModeColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getGameModeIcon(),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getDisplayName(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getGameModeColor(),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Main stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Partidas',
                    stats.totalGames.toString(),
                    Icons.sports_esports,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Victorias',
                    '${stats.winRate.toStringAsFixed(1)}%',
                    Icons.emoji_events,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'MVP',
                    stats.mvpCount.toString(),
                    Icons.star,
                    Colors.purple,
                  ),
                  _buildStatItem(
                    'KDA',
                    stats.kda.toStringAsFixed(2),
                    Icons.speed,
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getGameModeColor() {
    switch (stats.mode) {
      case GameMode.total:
        return const Color(0xFF059669);
      case GameMode.ranked:
        return const Color(0xFFDC2626);
      case GameMode.classic:
        return const Color(0xFF2563EB);
      case GameMode.brawl:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _getGameModeIcon() {
    switch (stats.mode) {
      case GameMode.total:
        return Icons.dashboard;
      case GameMode.ranked:
        return Icons.military_tech;
      case GameMode.classic:
        return Icons.games;
      case GameMode.brawl:
        return Icons.sports_mma;
    }
  }

  String _getDisplayName() {
    switch (stats.mode) {
      case GameMode.total:
        return 'Estadísticas Totales';
      case GameMode.ranked:
        return 'Clasificatoria';
      case GameMode.classic:
        return 'Clásica';
      case GameMode.brawl:
        return 'Coliseo';
    }
  }
}
