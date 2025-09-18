import 'package:flutter/material.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/presentation/utils/game_mode_extensions.dart';
import 'package:intl/intl.dart';

class StatsCollectionCard extends StatelessWidget {
  const StatsCollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  final StatsCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
      ),
    );
  }

  Widget _buildHeader(DateFormat dateFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateFormat.format(collection.createdAt),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildStatsPreview() {
    final availableStats = collection.availableStats;

    if (availableStats.isEmpty) {
      return const Text(
        'Sin estadísticas disponibles',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: availableStats.map((stats) {
        return _buildStatChip(stats);
      }).toList(),
    );
  }

  Widget _buildStatChip(PlayerStats stats) {
    return Chip(
      label: Text(stats.mode.shortName, style: const TextStyle(fontSize: 12)),
      backgroundColor: stats.mode.color.withOpacity(0.1),
      side: BorderSide(color: stats.mode.color, width: 1),
    );
  }
}
