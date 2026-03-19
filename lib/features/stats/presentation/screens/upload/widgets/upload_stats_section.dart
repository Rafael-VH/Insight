import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/presentation/widgets/stats_verification_widget.dart';

class UploadStatsSection extends StatelessWidget {
  const UploadStatsSection({
    super.key,
    required this.parsedStats,
    required this.hasInvalidStats,
  });

  final Map<GameMode, PlayerStats?> parsedStats;
  final bool hasInvalidStats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, colorScheme, isDark),
        const SizedBox(height: 8),
        ..._buildVerificationWidgets(),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Estadísticas extraídas:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (hasInvalidStats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange[900]!.withValues(alpha: 0.4)
                  : Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: isDark ? Colors.orange[300] : Colors.orange[900],
                ),
                const SizedBox(width: 4),
                Text(
                  'Datos incompletos',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.orange[300] : Colors.orange[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildVerificationWidgets() {
    return parsedStats.entries
        .where((entry) => entry.value != null)
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StatsVerificationWidget(
              gameMode: entry.key,
              stats: entry.value!,
            ),
          ),
        )
        .toList();
  }
}
