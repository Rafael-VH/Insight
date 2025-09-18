// lib/core/utils/stats_parser.dart
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';

class StatsParser {
  /// Método principal para parsear stats con un modo específico
  static PlayerStats? parseStats(String text, GameMode mode) {
    if (text.isEmpty) return null;

    final stats = parseFromText(text);
    if (stats == null) return null;

    // Retornar las stats con el modo correcto
    return stats.copyWith(mode: mode);
  }

  static PlayerStats? parseFromText(String text) {
    if (text.isEmpty) return null;

    try {
      final lines = text.split('\n').map((line) => line.trim()).toList();

      // Determinar el modo de juego basado en el texto
      final GameMode mode = _detectGameMode(text);

      // Extraer estadísticas principales (círculos superiores)
      final int totalGames = _extractNumber(text, r'(\d+)\s*Partidas');
      final double winRate = _extractPercentage(
        text,
        r'(\d+\.?\d*)%?\s*Tasa de Victorias',
      );
      final int mvpCount = _extractNumber(text, r'(\d+)\s*MVP');

      // Extraer estadísticas de detalles (lado derecho)
      final double kda = _extractDecimal(text, r'KDA\s*(\d+\.?\d*)');
      final double teamFightParticipation = _extractPercentage(
        text,
        r'Participación en Equipo\s*(\d+\.?\d*)%?',
      );
      final int goldPerMin = _extractNumber(text, r'Oro/Min\s*(\d+)');
      final int heroDamagePerMin = _extractNumber(
        text,
        r'DAÑO a Héroe/Min\s*(\d+)',
      );
      final double deathsPerGame = _extractDecimal(
        text,
        r'Muertes/Partida\s*(\d+\.?\d*)',
      );
      final int towerDamagePerGame = _extractNumber(
        text,
        r'Daño a Torre/Partida\s*(\d+)',
      );

      // Extraer logros y récords (lado izquierdo)
      final int legendary = _extractNumber(text, r'Legendario\s*(\d+)');
      final int savage = _extractNumber(text, r'Savage\s*(\d+)');
      final int maniac = _extractNumber(text, r'Maniac\s*(\d+)');
      final int tripleKill = _extractNumber(text, r'Asesinato Triple\s*(\d+)');
      final int doubleKill = _extractNumber(text, r'Asesinato Doble\s*(\d+)');
      final int mvpLoss = _extractNumber(text, r'MVP Perdedor\s*(\d+)');
      final int maxKills = _extractNumber(text, r'Asesinatos Máx\.\s*(\d+)');
      final int maxAssists = _extractNumber(text, r'Asistencias Máx\.\s*(\d+)');
      final int maxWinningStreak = _extractNumber(
        text,
        r'Racha de Victorias Máx\.\s*(\d+)',
      );
      final int firstBlood = _extractNumber(text, r'Primera Sangre\s*(\d+)');

      // Extraer daños y oro máximos
      final int maxDamageDealt = _extractNumber(
        text,
        r'Daño Causado Máx\./min\s*(\d+)',
      );
      final int maxDamageTaken = _extractNumber(
        text,
        r'Daño tomado Máx\./min\s*(\d+)',
      );
      final int maxGold = _extractNumber(text, r'Oro Máx\./min\s*(\d+)');

      return PlayerStats(
        mode: mode,
        totalGames: totalGames,
        winRate: winRate,
        mvpCount: mvpCount,
        legendary: legendary,
        savage: savage,
        maniac: maniac,
        tripleKill: tripleKill,
        doubleKill: doubleKill,
        mvpLoss: mvpLoss,
        maxKills: maxKills,
        maxAssists: maxAssists,
        maxWinningStreak: maxWinningStreak,
        firstBlood: firstBlood,
        maxDamageDealt: maxDamageDealt,
        maxDamageTaken: maxDamageTaken,
        maxGold: maxGold,
        kda: kda,
        teamFightParticipation: teamFightParticipation,
        goldPerMin: goldPerMin,
        heroDamagePerMin: heroDamagePerMin,
        deathsPerGame: deathsPerGame,
        towerDamagePerGame: towerDamagePerGame,
        oroMaxMin: maxGold,
        danoTomadoMaxMin: maxDamageTaken,
        danoCausadoMaxMin: maxDamageDealt,
      );
    } catch (e) {
      print('Error parsing stats: $e');
      return null;
    }
  }

  static GameMode _detectGameMode(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('clasificatoria')) {
      return GameMode.ranked;
    } else if (lowerText.contains('clásica')) {
      return GameMode.classic;
    } else if (lowerText.contains('coliseo')) {
      return GameMode.brawl;
    } else if (lowerText.contains('todos los juegos')) {
      return GameMode.total;
    }

    return GameMode.total; // Default
  }

  static int _extractNumber(String text, String pattern) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final numberStr = match.group(1)!.replaceAll(',', '');
        return int.parse(numberStr);
      }
    } catch (e) {
      print('Error extracting number with pattern $pattern: $e');
    }
    return 0;
  }

  static double _extractDecimal(String text, String pattern) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        return double.parse(match.group(1)!);
      }
    } catch (e) {
      print('Error extracting decimal with pattern $pattern: $e');
    }
    return 0.0;
  }

  static double _extractPercentage(String text, String pattern) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        return double.parse(match.group(1)!);
      }
    } catch (e) {
      print('Error extracting percentage with pattern $pattern: $e');
    }
    return 0.0;
  }

  /// Genera una lista de campos para verificación visual
  static List<StatField> getFieldsForVerification(PlayerStats stats) {
    return [
      // Estadísticas principales
      StatField('Partidas Totales', stats.totalGames.toString()),
      StatField('Tasa de Victorias', '${stats.winRate}%'),
      StatField('MVP', stats.mvpCount.toString()),

      // Detalles
      StatField('KDA', stats.kda.toString()),
      StatField('Participación en Equipo', '${stats.teamFightParticipation}%'),
      StatField('Oro/Min', stats.goldPerMin.toString()),
      StatField('DAÑO a Héroe/Min', stats.heroDamagePerMin.toString()),
      StatField('Muertes/Partida', stats.deathsPerGame.toString()),
      StatField('Daño a Torre/Partida', stats.towerDamagePerGame.toString()),

      // Logros
      StatField('Legendario', stats.legendary.toString()),
      StatField('Savage', stats.savage.toString()),
      StatField('Maniac', stats.maniac.toString()),
      StatField('Asesinato Triple', stats.tripleKill.toString()),
      StatField('Asesinato Doble', stats.doubleKill.toString()),
      StatField('MVP Perdedor', stats.mvpLoss.toString()),
      StatField('Asesinatos Máx.', stats.maxKills.toString()),
      StatField('Asistencias Máx.', stats.maxAssists.toString()),
      StatField('Racha de Victorias Máx.', stats.maxWinningStreak.toString()),
      StatField('Primera Sangre', stats.firstBlood.toString()),
      StatField('Daño Causado Máx./min', stats.maxDamageDealt.toString()),
      StatField('Daño Tomado Máx./min', stats.maxDamageTaken.toString()),
      StatField('Oro Máx./min', stats.maxGold.toString()),
    ];
  }
}

class StatField {
  final String name;
  final String value;

  const StatField(this.name, this.value);
}
