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
              color: _getGameModeColor().withOpacity(0.1),
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
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Extraído',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
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
                // Estadísticas principales
                _buildStatsSection('Estadísticas Principales', [
                  fields[0], // Partidas Totales
                  fields[1], // Tasa de Victorias
                  fields[2], // MVP
                ]),

                const SizedBox(height: 16),

                // Rendimiento
                _buildStatsSection('Rendimiento', [
                  fields[3], // KDA
                  fields[4], // Participación en Equipo
                  fields[5], // Oro/Min
                  fields[6], // DAÑO a Héroe/Min
                  fields[7], // Muertes/Partida
                  fields[8], // Daño a Torre/Partida
                ]),

                const SizedBox(height: 16),

                // Logros
                _buildStatsSection('Logros y Récords', [
                  fields[9], // Legendario
                  fields[10], // Savage
                  fields[11], // Maniac
                  fields[12], // Asesinato Triple
                  fields[13], // Asesinato Doble
                  fields[14], // MVP Perdedor
                  fields[15], // Asesinatos Máx.
                  fields[16], // Asistencias Máx.
                  fields[17], // Racha de Victorias Máx.
                  fields[18], // Primera Sangre
                  fields[19], // Daño Causado Máx./min
                  fields[20], // Daño Tomado Máx./min
                  fields[21], // Oro Máx./min
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(String title, List<StatField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: fields.map((field) => _buildStatRow(field)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(StatField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              field.name,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              field.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
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
