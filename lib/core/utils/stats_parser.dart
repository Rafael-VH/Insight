import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';

/// Resultado del parseo con información de diagnóstico
class ParseResult {
  final PlayerStats? stats;
  final List<String> extractionLog;
  final Map<String, dynamic> rawMatches;

  const ParseResult({
    required this.stats,
    required this.extractionLog,
    required this.rawMatches,
  });
}

class StatsParser {
  /// Lista para almacenar logs de extracción
  static final List<String> _extractionLog = [];

  /// Mapa para almacenar las coincidencias encontradas
  static final Map<String, dynamic> _rawMatches = {};

  /// Método principal para parsear stats con un modo específico
  static PlayerStats? parseStats(String text, GameMode mode) {
    if (text.isEmpty) return null;

    final stats = parseFromText(text);
    if (stats == null) return null;

    // Retornar las stats con el modo correcto
    return stats.copyWith(mode: mode);
  }

  /// Método principal con resultado detallado
  static ParseResult parseStatsWithDiagnostics(String text, GameMode mode) {
    _extractionLog.clear();
    _rawMatches.clear();

    _log('Iniciando extracción de texto (${text.length} caracteres)');
    _log('Modo de juego especificado: ${mode.displayName}');

    if (text.isEmpty) {
      _log('ERROR: Texto vacío');
      return ParseResult(
        stats: null,
        extractionLog: [..._extractionLog],
        rawMatches: {},
      );
    }

    final stats = _parseFromTextWithLogging(text);

    if (stats == null) {
      _log('ERROR: No se pudo crear el objeto PlayerStats');
      return ParseResult(
        stats: null,
        extractionLog: [..._extractionLog],
        rawMatches: {..._rawMatches},
      );
    }

    final finalStats = stats.copyWith(mode: mode);
    _log('Extracción completada. Modo aplicado: ${mode.displayName}');

    return ParseResult(
      stats: finalStats,
      extractionLog: [..._extractionLog],
      rawMatches: {..._rawMatches},
    );
  }

  static PlayerStats? parseFromText(String text) {
    return _parseFromTextWithLogging(text);
  }

  static PlayerStats? _parseFromTextWithLogging(String text) {
    if (text.isEmpty) return null;

    try {
      _log('--- Comenzando análisis de texto ---');

      // Mostrar muestra del texto
      final sample = text.length > 200 ? text.substring(0, 200) : text;
      _log('Muestra del texto: ${sample.replaceAll('\n', ' | ')}...');

      final lines = text.split('\n').map((line) => line.trim()).toList();
      _log('Total de líneas: ${lines.length}');

      // Determinar el modo de juego basado en el texto
      final GameMode mode = _detectGameMode(text);
      _log('Modo detectado: ${mode.displayName}');

      // Extraer estadísticas principales
      _log('\n--- Extrayendo estadísticas principales ---');
      final int totalGames = _extractNumberWithLog(
        text,
        r'(\d+)\s*Partidas',
        'Partidas Totales',
      );

      // MEJORADO: Patrones más flexibles para Tasa de Victorias
      final double winRate = _extractWinRate(text);

      final int mvpCount = _extractNumberWithLog(text, r'(\d+)\s*MVP', 'MVP');

      // Extraer estadísticas de rendimiento
      _log('\n--- Extrayendo estadísticas de rendimiento ---');
      final double kda = _extractDecimalWithLog(
        text,
        r'KDA\s*(\d+\.?\d*)',
        'KDA',
      );
      final double teamFightParticipation = _extractPercentageWithLog(
        text,
        r'Participación en Equipo\s*(\d+\.?\d*)%?',
        'Participación en Equipo',
      );
      final int goldPerMin = _extractNumberWithLog(
        text,
        r'Oro[/\s]*Min\s*(\d+)',
        'Oro/Min',
      );
      final int heroDamagePerMin = _extractNumberWithLog(
        text,
        r'DAÑO a Héroe[/\s]*Min\s*(\d+)',
        'DAÑO a Héroe/Min',
      );
      final double deathsPerGame = _extractDecimalWithLog(
        text,
        r'Muertes[/\s]*Partida\s*(\d+\.?\d*)',
        'Muertes/Partida',
      );
      final int towerDamagePerGame = _extractNumberWithLog(
        text,
        r'Daño a Torre[/\s]*Partida\s*(\d+)',
        'Daño a Torre/Partida',
      );

      // Extraer logros y récords
      _log('\n--- Extrayendo logros y récords ---');
      final int legendary = _extractNumberWithLog(
        text,
        r'Legendario\s*(\d+)',
        'Legendario',
      );
      final int savage = _extractNumberWithLog(
        text,
        r'Savage\s*(\d+)',
        'Savage',
      );
      final int maniac = _extractNumberWithLog(
        text,
        r'Maniac\s*(\d+)',
        'Maniac',
      );
      final int tripleKill = _extractNumberWithLog(
        text,
        r'Asesinato Triple\s*(\d+)',
        'Asesinato Triple',
      );
      final int doubleKill = _extractNumberWithLog(
        text,
        r'Asesinato Doble\s*(\d+)',
        'Asesinato Doble',
      );
      final int mvpLoss = _extractNumberWithLog(
        text,
        r'MVP Perdedor\s*(\d+)',
        'MVP Perdedor',
      );
      final int maxKills = _extractNumberWithLog(
        text,
        r'Asesinatos Máx[.\s]*(\d+)',
        'Asesinatos Máx.',
      );
      final int maxAssists = _extractNumberWithLog(
        text,
        r'Asistencias Máx[.\s]*(\d+)',
        'Asistencias Máx.',
      );
      final int maxWinningStreak = _extractNumberWithLog(
        text,
        r'Racha de Victorias Máx[.\s]*(\d+)',
        'Racha de Victorias Máx.',
      );
      final int firstBlood = _extractNumberWithLog(
        text,
        r'Primera Sangre\s*(\d+)',
        'Primera Sangre',
      );

      // MEJORADO: Extraer daños y oro máximos con patrones más flexibles
      _log('\n--- Extrayendo valores máximos ---');
      final int maxDamageDealt = _extractMaxDamageDealt(text);
      final int maxDamageTaken = _extractMaxDamageTaken(text);
      final int maxGold = _extractMaxGold(text);

      _log('\n--- Creando objeto PlayerStats ---');

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
      _log('ERROR FATAL: $e');
      print('Error parsing stats: $e');
      return null;
    }
  }

  /// NUEVO: Método especializado para extraer Tasa de Victorias
  static double _extractWinRate(String text) {
    _log('Intentando extraer Tasa de Victorias con múltiples patrones...');

    // Lista de patrones posibles para Tasa de Victorias
    final patterns = [
      r'(\d+\.?\d*)\s*%?\s*Tasa\s*de\s*Victorias', // 55.3% Tasa de Victorias
      r'Tasa\s*de\s*Victorias\s*(\d+\.?\d*)\s*%?', // Tasa de Victorias 55.3%
      r'(\d+\.?\d*)\s*%\s*Tasa', // 55.3 % Tasa
      r'Victorias?\s*(\d+\.?\d*)\s*%', // Victorias 55.3%
      r'Win\s*Rate\s*(\d+\.?\d*)\s*%?', // Win Rate 55.3 (por si está en inglés)
    ];

    for (int i = 0; i < patterns.length; i++) {
      try {
        final regex = RegExp(patterns[i], caseSensitive: false);
        final match = regex.firstMatch(text);

        if (match != null && match.groupCount > 0) {
          final value = double.parse(match.group(1)!);
          _log('✓ Tasa de Victorias: $value% (patrón ${i + 1})');
          _rawMatches['Tasa de Victorias'] = value;
          return value;
        }
      } catch (e) {
        _log('Patrón ${i + 1} falló: $e');
      }
    }

    _log('✗ Tasa de Victorias: No se encontró con ningún patrón');
    _rawMatches['Tasa de Victorias'] = 0.0;
    return 0.0;
  }

  /// NUEVO: Método especializado para extraer Daño Causado Máx
  static int _extractMaxDamageDealt(String text) {
    _log('Intentando extraer Daño Causado Máx./min con múltiples patrones...');

    final patterns = [
      r'Daño\s*Causado\s*Máx[.\s]*/?\s*min\s*(\d+)', // Daño Causado Máx./min 1500
      r'Daño\s*Causado\s*Máx[.\s]*(\d+)', // Daño Causado Máx. 1500
      r'Causado\s*Máx[.\s]*/?\s*min\s*(\d+)', // Causado Máx./min 1500
      r'Max\s*Damage\s*Dealt[/\s]*min\s*(\d+)', // Max Damage Dealt/min 1500
      r'DMG\s*Dealt\s*Max[/\s]*min\s*(\d+)', // DMG Dealt Max/min 1500
    ];

    for (int i = 0; i < patterns.length; i++) {
      try {
        final regex = RegExp(patterns[i], caseSensitive: false);
        final match = regex.firstMatch(text);

        if (match != null && match.groupCount > 0) {
          final numberStr = match.group(1)!.replaceAll(',', '');
          final value = int.parse(numberStr);
          _log('✓ Daño Causado Máx./min: $value (patrón ${i + 1})');
          _rawMatches['Daño Causado Máx./min'] = value;
          return value;
        }
      } catch (e) {
        _log('Patrón ${i + 1} falló: $e');
      }
    }

    _log('✗ Daño Causado Máx./min: No se encontró con ningún patrón');
    _rawMatches['Daño Causado Máx./min'] = 0;
    return 0;
  }

  /// NUEVO: Método especializado para extraer Daño Tomado Máx
  static int _extractMaxDamageTaken(String text) {
    _log('Intentando extraer Daño Tomado Máx./min con múltiples patrones...');

    final patterns = [
      r'Daño\s*[Tt]omado\s*Máx[.\s]*/?\s*min\s*(\d+)', // Daño tomado Máx./min 800
      r'Daño\s*[Tt]omado\s*Máx[.\s]*(\d+)', // Daño tomado Máx. 800
      r'[Tt]omado\s*Máx[.\s]*/?\s*min\s*(\d+)', // tomado Máx./min 800
      r'Max\s*Damage\s*Taken[/\s]*min\s*(\d+)', // Max Damage Taken/min 800
      r'DMG\s*Taken\s*Max[/\s]*min\s*(\d+)', // DMG Taken Max/min 800
      r'Daño\s*recibido\s*Máx[.\s]*/?\s*min\s*(\d+)', // Daño recibido Máx./min 800
    ];

    for (int i = 0; i < patterns.length; i++) {
      try {
        final regex = RegExp(patterns[i], caseSensitive: false);
        final match = regex.firstMatch(text);

        if (match != null && match.groupCount > 0) {
          final numberStr = match.group(1)!.replaceAll(',', '');
          final value = int.parse(numberStr);
          _log('✓ Daño Tomado Máx./min: $value (patrón ${i + 1})');
          _rawMatches['Daño Tomado Máx./min'] = value;
          return value;
        }
      } catch (e) {
        _log('Patrón ${i + 1} falló: $e');
      }
    }

    _log('✗ Daño Tomado Máx./min: No se encontró con ningún patrón');
    _rawMatches['Daño Tomado Máx./min'] = 0;
    return 0;
  }

  /// NUEVO: Método especializado para extraer Oro Máx
  static int _extractMaxGold(String text) {
    _log('Intentando extraer Oro Máx./min con múltiples patrones...');

    final patterns = [
      r'Oro\s*Máx[.\s]*/?\s*min\s*(\d+)', // Oro Máx./min 650
      r'Oro\s*Máx[.\s]*(\d+)', // Oro Máx. 650
      r'Max\s*Gold[/\s]*min\s*(\d+)', // Max Gold/min 650
      r'Gold\s*Max[/\s]*min\s*(\d+)', // Gold Max/min 650
    ];

    for (int i = 0; i < patterns.length; i++) {
      try {
        final regex = RegExp(patterns[i], caseSensitive: false);
        final match = regex.firstMatch(text);

        if (match != null && match.groupCount > 0) {
          final numberStr = match.group(1)!.replaceAll(',', '');
          final value = int.parse(numberStr);
          _log('✓ Oro Máx./min: $value (patrón ${i + 1})');
          _rawMatches['Oro Máx./min'] = value;
          return value;
        }
      } catch (e) {
        _log('Patrón ${i + 1} falló: $e');
      }
    }

    _log('✗ Oro Máx./min: No se encontró con ningún patrón');
    _rawMatches['Oro Máx./min'] = 0;
    return 0;
  }

  static GameMode _detectGameMode(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('clasificatoria')) {
      _log('Modo detectado por palabra clave: Clasificatoria');
      return GameMode.ranked;
    } else if (lowerText.contains('clásica')) {
      _log('Modo detectado por palabra clave: Clásica');
      return GameMode.classic;
    } else if (lowerText.contains('coliseo')) {
      _log('Modo detectado por palabra clave: Coliseo');
      return GameMode.brawl;
    } else if (lowerText.contains('todos los juegos')) {
      _log('Modo detectado por palabra clave: Todos los Juegos');
      return GameMode.total;
    }

    _log('No se detectó modo específico, usando Total por defecto');
    return GameMode.total; // Default
  }

  static int _extractNumberWithLog(
    String text,
    String pattern,
    String fieldName,
  ) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);

      if (match != null && match.groupCount > 0) {
        final numberStr = match.group(1)!.replaceAll(',', '');
        final value = int.parse(numberStr);
        _log('✓ $fieldName: $value');
        _rawMatches[fieldName] = value;
        return value;
      } else {
        _log('✗ $fieldName: No se encontró coincidencia con patrón: $pattern');
        _rawMatches[fieldName] = 0;
        return 0;
      }
    } catch (e) {
      _log('✗ $fieldName: ERROR al extraer - $e');
      _rawMatches[fieldName] = 0;
      return 0;
    }
  }

  static double _extractDecimalWithLog(
    String text,
    String pattern,
    String fieldName,
  ) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);

      if (match != null && match.groupCount > 0) {
        final value = double.parse(match.group(1)!);
        _log('✓ $fieldName: $value');
        _rawMatches[fieldName] = value;
        return value;
      } else {
        _log('✗ $fieldName: No se encontró coincidencia con patrón: $pattern');
        _rawMatches[fieldName] = 0.0;
        return 0.0;
      }
    } catch (e) {
      _log('✗ $fieldName: ERROR al extraer - $e');
      _rawMatches[fieldName] = 0.0;
      return 0.0;
    }
  }

  static double _extractPercentageWithLog(
    String text,
    String pattern,
    String fieldName,
  ) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);

      if (match != null && match.groupCount > 0) {
        final value = double.parse(match.group(1)!);
        _log('✓ $fieldName: $value%');
        _rawMatches[fieldName] = value;
        return value;
      } else {
        _log('✗ $fieldName: No se encontró coincidencia con patrón: $pattern');
        _rawMatches[fieldName] = 0.0;
        return 0.0;
      }
    } catch (e) {
      _log('✗ $fieldName: ERROR al extraer - $e');
      _rawMatches[fieldName] = 0.0;
      return 0.0;
    }
  }

  // Métodos legacy para compatibilidad
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

  static void _log(String message) {
    _extractionLog.add(message);
    print('[StatsParser] $message');
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

  /// Obtiene el log de extracción
  static List<String> getExtractionLog() {
    return [..._extractionLog];
  }

  /// Limpia el log de extracción
  static void clearLog() {
    _extractionLog.clear();
    _rawMatches.clear();
  }
}

class StatField {
  final String name;
  final String value;

  const StatField(this.name, this.value);
}
