import 'package:flutter/material.dart';
//
import 'package:insight/core/utils/stats_parser.dart';
//
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';

class StatsVerificationWidget extends StatelessWidget {
  const StatsVerificationWidget({
    super.key,
    required this.gameMode,
    required this.stats,
  });

  final GameMode gameMode;
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final fields = StatsParser.getFieldsForVerification(stats);
    // CORRECCIÓN: Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getGameModeColor().withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(_getGameModeIcon(), color: _getGameModeColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDisplayName(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getGameModeColor(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[isDark ? 900 : 100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green[isDark ? 300 : 700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Extraído',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[isDark ? 300 : 700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatsSection(context, 'Estadísticas Principales', [
                  fields[0],
                  fields[1],
                  fields[2],
                ]),
                const SizedBox(height: 16),
                _buildStatsSection(context, 'Rendimiento', [
                  fields[3],
                  fields[4],
                  fields[5],
                  fields[6],
                  fields[7],
                  fields[8],
                ]),
                const SizedBox(height: 16),
                _buildStatsSection(context, 'Logros y Récords', [
                  fields[9],
                  fields[10],
                  fields[11],
                  fields[12],
                  fields[13],
                  fields[14],
                  fields[15],
                  fields[16],
                  fields[17],
                  fields[18],
                  fields[19],
                  fields[20],
                  fields[21],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    String title,
    List<StatField> fields,
  ) {
    // CORRECCIÓN: Colores adaptados
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface, // Adaptado
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // CORRECCIÓN: Fondo adaptado
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withOpacity(0.3)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: fields
                .map((field) => _buildStatRow(context, field))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, StatField field) {
    // CORRECCIÓN: Colores de texto adaptados
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              field.name,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface, // Adaptado
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              field.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary, // Adaptado
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGameModeColor() {
    switch (gameMode) {
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
    switch (gameMode) {
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
    switch (gameMode) {
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
