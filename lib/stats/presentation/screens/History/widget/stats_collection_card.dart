import 'package:flutter/material.dart';
//
import 'package:insight/stats/domain/entities/player_stats.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
//
import 'package:insight/stats/presentation/utils/game_mode_extensions.dart';
import 'package:intl/intl.dart';

class StatsCollectionCard extends StatelessWidget {
  const StatsCollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.badge,
  });

  final StatsCollection collection;
  final VoidCallback onTap;
  final String? badge; // NUEVO: Badge opcional con número

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(dateFormat),
                  const SizedBox(height: 12),
                  _buildStatsPreview(),
                ],
              ),
            ),
            // NUEVO: Badge de número de orden
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateFormat dateFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(collection.createdAt),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRelativeTime(collection.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildStatsPreview() {
    final availableStats = collection.availableStats;

    if (availableStats.isEmpty) {
      return Text(
        'Sin estadísticas disponibles',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modos capturados:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: availableStats.map((stats) {
            return _buildStatChip(stats);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatChip(PlayerStats stats) {
    return Chip(
      label: Text(
        stats.mode.shortName,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: stats.mode.color.withOpacity(0.1),
      side: BorderSide(color: stats.mode.color, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      avatar: Icon(stats.mode.icon, size: 16, color: stats.mode.color),
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return 'Hace más de una semana';
    }
  }
}
