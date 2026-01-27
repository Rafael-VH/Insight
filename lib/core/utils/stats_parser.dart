import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';

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

  // Compilar RegExp una sola vez
  static final _winRatePatterns = [
    RegExp(r'(\d+\.?\d*)\s*%?\s*Tasa\s*de\s*Victorias', caseSensitive: false),
    RegExp(
      r'Tasa\s*de\s*Victorias\s*[:\s]*(\d+\.?\d*)\s*%?',
      caseSensitive: false,
    ),
    RegExp(r'(\d+\.\d+)\s*%.*?[Tt]asa', caseSensitive: false),
    RegExp(r'(\d+\.?\d+)\s*%\s*[Tt]asa', caseSensitive: false),
    RegExp(r'(\d+\.\d+)\s*%.*?[Vv]ictorias?', caseSensitive: false),
    RegExp(r'Win\s*Rate\s*[:\s]*(\d+\.?\d*)\s*%?', caseSensitive: false),
    RegExp(r'([0-5]?\d\.\d{1,2})\s*%', caseSensitive: false),
  ];

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

      // Patrones más flexibles para Tasa de Victorias
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

      // Extraer daños y oro máximos con patrones más flexibles
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

  /// Método especializado para extraer Tasa de Victorias
  static double _extractWinRate(String text) {
    for (int i = 0; i < _winRatePatterns.length; i++) {
      final matches = _winRatePatterns[i].allMatches(text);

      for (var match in matches) {
        if (match.groupCount > 0) {
          final valueStr = match.group(1)!.trim();
          final value = double.tryParse(valueStr);

          if (value != null && value >= 0 && value <= 100) {
            _log('✓ Tasa de Victorias: $value% (patrón ${i + 1})');
            _rawMatches['Tasa de Victorias'] = value;
            return value;
          }
        }
      }
    }

    _log('✗ Tasa de Victorias: No encontrada');
    _rawMatches['Tasa de Victorias'] = 0.0;
    return 0.0;
  }

  /// Método especializado para extraer Daño Causado Máx - CORREGIDO PARA TOTAL
  static int _extractMaxDamageDealt(String text) {
    _log('Intentando extraer Daño Causado Máx./min con múltiples patrones...');

    final patterns = [
      // Patrón para "Daño Causado Máx./min" con números de 4-5 dígitos
      r'Daño\s*Causado\s*Máx[.\s]*/?\s*min\s*[:\s]*(\d+)',

      // Variante sin "min"
      r'Daño\s*Causado\s*Máx[.\s]*[:/\s]*(\d{4,5})',

      // Búsqueda genérica: número de 4-5 dígitos después de "Daño Causado"
      r'Daño\s*Causado[^0-9]*(\d{4,5})',

      // Patrón más específico: buscar "10134" o similar después de "Causado"
      r'Causado[^0-9]*(\d{4,5})',

      // Fallback: buscar cualquier número grande después de "Daño"
      r'Daño\s+[^0-9]*[Mm]áx[^0-9]*(\d{4,5})',

      // En inglés (fallback)
      r'Max\s*Damage\s*Dealt[/\s]*min\s*(\d+)',
      r'DMG\s*Dealt\s*Max[/\s]*min\s*(\d+)',

      // Búsqueda sin etiqueta, solo número entre 1000-99999
      r'(?:Máx|Max)[.\s]*/?\s*min\s*[:\s]*(\d{4,5})',
    ];

    for (int i = 0; i < patterns.length; i++) {
      try {
        final regex = RegExp(patterns[i], caseSensitive: false);
        final match = regex.firstMatch(text);

        if (match != null && match.groupCount > 0) {
          final numberStr = match.group(1)!.replaceAll(',', '');
          final value = int.parse(numberStr);

          // Validar que sea un número razonable (1000-99999)
          if (value >= 1000 && value <= 99999) {
            _log('✓ Daño Causado Máx./min: $value (patrón ${i + 1})');
            _rawMatches['Daño Causado Máx./min'] = value;
            return value;
          } else {
            _log('⚠ Valor fuera de rango descartado: $value (patrón ${i + 1})');
          }
        }
      } catch (e) {
        _log('Patrón ${i + 1} falló: $e');
      }
    }

    _log('✗ Daño Causado Máx./min: No se encontró con ningún patrón');
    _rawMatches['Daño Causado Máx./min'] = 0;
    return 0;
  }

  /// Método especializado para extraer Daño Tomado Máx
  static int _extractMaxDamageTaken(String text) {
    _log('Intentando extraer Daño Tomado Máx./min con múltiples patrones...');

    final patterns = [
      r'Daño\s*[Tt]omado\s*Máx[.\s]*/?\s*min\s*(\d+)',
      r'Daño\s*[Tt]omado\s*Máx[.\s]*(\d+)',
      r'[Tt]omado\s*Máx[.\s]*/?\s*min\s*(\d+)',
      r'Max\s*Damage\s*Taken[/\s]*min\s*(\d+)',
      r'DMG\s*Taken\s*Max[/\s]*min\s*(\d+)',
      r'Daño\s*recibido\s*Máx[.\s]*/?\s*min\s*(\d+)',
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

  /// Método especializado para extraer Oro Máx
  static int _extractMaxGold(String text) {
    _log('Intentando extraer Oro Máx./min con múltiples patrones...');

    final patterns = [
      r'Oro\s*Máx[.\s]*/?\s*min\s*(\d+)',
      r'Oro\s*Máx[.\s]*(\d+)',
      r'Max\s*Gold[/\s]*min\s*(\d+)',
      r'Gold\s*Max[/\s]*min\s*(\d+)',
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
    return GameMode.total;
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

  static void _log(String message) {
    _extractionLog.add(message);
    print('[StatsParser] $message');
  }

  static List<StatField> getFieldsForVerification(PlayerStats stats) {
    return [
      StatField('Partidas Totales', stats.totalGames.toString()),
      StatField('Tasa de Victorias', '${stats.winRate}%'),
      StatField('MVP', stats.mvpCount.toString()),
      StatField('KDA', stats.kda.toString()),
      StatField('Participación en Equipo', '${stats.teamFightParticipation}%'),
      StatField('Oro/Min', stats.goldPerMin.toString()),
      StatField('DAÑO a Héroe/Min', stats.heroDamagePerMin.toString()),
      StatField('Muertes/Partida', stats.deathsPerGame.toString()),
      StatField('Daño a Torre/Partida', stats.towerDamagePerGame.toString()),
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

  static List<String> getExtractionLog() {
    return [..._extractionLog];
  }

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
