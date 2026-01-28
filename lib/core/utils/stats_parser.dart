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

/// Clase que contiene conjuntos de patrones compilados para mejor rendimiento
class _CompiledPatterns {
  // ==================== WIN RATE PATTERNS (ESTRATEGIA SIMPLE) ====================
  static final List<RegExp> winRate = [
    // Capturar TODOS los porcentajes y validar por rango (40-80%)
    // Los Win Rates típicos están en este rango

    // Patrón 1: Porcentaje con 2 decimales (formato más común)
    RegExp(r'(\d{1,2}\.\d{2})\s*%'),

    // Patrón 2: Porcentaje con 1-2 decimales
    RegExp(r'(\d{1,2}\.\d{1,2})\s*%'),

    // Patrón 3: Porcentaje entero
    RegExp(r'(\d{1,2})\s*%'),
  ];

  // ==================== TOTAL GAMES PATTERNS ====================
  static final List<RegExp> totalGames = [
    // Español
    RegExp(r'(\d+)\s*Partidas?\s*(?:Totales?|Jugadas?)?', caseSensitive: false),
    RegExp(r'(?:Total\s*)?Partidas?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Juegos?\s*Jugados?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(?:Nº|N°|Num)\s*Partidas?\s*[:\s]*(\d+)', caseSensitive: false),

    // Inglés
    RegExp(r'(\d+)\s*(?:Total\s*)?(?:Games?|Matches?)', caseSensitive: false),
    RegExp(r'(?:Games?|Matches?)\s*Played\s*[:\s]*(\d+)', caseSensitive: false),

    // Patrones contextuales
    RegExp(r'(\d+)\s*(?=.*(?:Tasa|Win\s*Rate))', caseSensitive: false),
  ];

  // ==================== MVP PATTERNS ====================
  static final List<RegExp> mvp = [
    RegExp(r'(\d+)\s*MVP', caseSensitive: false),
    RegExp(r'MVP\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Most\s*Valuable\s*Player\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'M\.?V\.?P\.?\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  // ==================== KDA PATTERNS ====================
  static final List<RegExp> kda = [
    RegExp(r'KDA\s*[:\s]*(\d+\.?\d*)', caseSensitive: false),
    RegExp(r'K\.?D\.?A\.?\s*[:\s]*(\d+\.?\d*)', caseSensitive: false),
    RegExp(r'(\d+\.?\d*)\s*KDA', caseSensitive: false),
    RegExp(
      r'Kill[s]?\s*Death\s*Assist\s*[:\s]*(\d+\.?\d*)',
      caseSensitive: false,
    ),
    RegExp(r'KDA\s*Ratio\s*[:\s]*(\d+\.?\d*)', caseSensitive: false),
  ];

  // ==================== TEAM FIGHT PARTICIPATION PATTERNS ====================
  static final List<RegExp> teamFight = [
    RegExp(
      r'Participación\s*(?:en\s*)?(?:Equipo|Team)\s*[:\s]*(\d+\.?\d*)\s*%?',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:Team\s*)?Fight\s*Participation\s*[:\s]*(\d+\.?\d*)\s*%?',
      caseSensitive: false,
    ),
    RegExp(
      r'Particip(?:ación|ation)?\s*[:\s]*(\d+\.?\d*)\s*%',
      caseSensitive: false,
    ),
    RegExp(r'(?:Team|Equipo)\s*[:\s]*(\d+\.?\d*)\s*%', caseSensitive: false),
    RegExp(r'TF\s*Participation\s*[:\s]*(\d+\.?\d*)', caseSensitive: false),
  ];

  // ==================== GOLD PER MIN PATTERNS ====================
  static final List<RegExp> goldPerMin = [
    // Español
    RegExp(
      r'Oro\s*(?:por\s*)?(?:/|por)?\s*Min(?:uto)?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'(\d+)\s*Oro\s*(?:/|por)\s*Min', caseSensitive: false),
    RegExp(
      r'Gold\s*(?:per\s*)?(?:/|per)?\s*Min(?:ute)?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'GPM\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*GPM', caseSensitive: false),

    // Variaciones con espacios
    RegExp(r'Oro\s*Min\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Gold\s*Min\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  // ==================== HERO DAMAGE PER MIN PATTERNS ====================
  static final List<RegExp> heroDamagePerMin = [
    // Español
    RegExp(
      r'(?:DAÑO|Daño)\s*a\s*(?:Héroe|Heroe|Hero)s?\s*(?:/|por)\s*Min(?:uto)?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'(\d+)\s*(?:DAÑO|Daño)\s*(?:Héroe|Hero)', caseSensitive: false),

    // Inglés
    RegExp(
      r'Hero\s*Damage\s*(?:per\s*)?(?:/|per)?\s*Min(?:ute)?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:Hero\s*)?DMG\s*(?:/|per)\s*Min\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'HDPM\s*[:\s]*(\d+)', caseSensitive: false),

    // Variaciones
    RegExp(r'Daño\s*Héroe\s*Min\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Hero\s*DMG\s*Min\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  // ==================== DEATHS PER GAME PATTERNS ====================
  static final List<RegExp> deathsPerGame = [
    RegExp(
      r'Muertes?\s*(?:/|por)\s*Partida\s*[:\s]*(\d+\.?\d*)',
      caseSensitive: false,
    ),
    RegExp(
      r'Deaths?\s*(?:per\s*)?(?:/|per)?\s*(?:Game|Match)\s*[:\s]*(\d+\.?\d*)',
      caseSensitive: false,
    ),
    RegExp(
      r'(\d+\.?\d*)\s*Muertes?\s*(?:/|por)\s*(?:Partida|Juego)',
      caseSensitive: false,
    ),
    RegExp(r'DPG\s*[:\s]*(\d+\.?\d*)', caseSensitive: false),
  ];

  // ==================== TOWER DAMAGE PER GAME PATTERNS ====================
  static final List<RegExp> towerDamage = [
    RegExp(
      r'Daño\s*a\s*Torre(?:s)?\s*(?:/|por)\s*Partida\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(
      r'Tower\s*Damage\s*(?:per\s*)?(?:/|per)?\s*(?:Game|Match)\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'(\d+)\s*Daño\s*Torre', caseSensitive: false),
    RegExp(r'TDPG\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Turret\s*Damage\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  // ==================== ACHIEVEMENTS PATTERNS ====================
  static final List<RegExp> legendary = [
    RegExp(r'Legendario\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Legendarios?', caseSensitive: false),
    RegExp(r'Legendary\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  static final List<RegExp> savage = [
    RegExp(r'Savage\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Savages?', caseSensitive: false),
    RegExp(r'Salvaje\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  static final List<RegExp> maniac = [
    RegExp(r'Maniac(?:o|a)?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Maniac', caseSensitive: false),
  ];

  static final List<RegExp> tripleKill = [
    RegExp(
      r'(?:Asesinato\s*)?Triple\s*(?:Kill)?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'Triple\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Triple(?:s)?', caseSensitive: false),
  ];

  static final List<RegExp> doubleKill = [
    RegExp(
      r'(?:Asesinato\s*)?Doble\s*(?:Kill)?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'Double\s*Kill\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Dobles?', caseSensitive: false),
  ];

  static final List<RegExp> mvpLoss = [
    RegExp(r'MVP\s*Perdedor\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'MVP\s*Loss\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Losing\s*MVP\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*MVP\s*(?:Perdedor|Loss)', caseSensitive: false),
  ];

  // ==================== MAX STATS PATTERNS ====================
  static final List<RegExp> maxKills = [
    RegExp(r'Asesinatos?\s*Máx\.?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Max\.?\s*Kills?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Kills?\s*Máx\.?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*(?:Asesinatos?|Kills?)\s*Máx', caseSensitive: false),
  ];

  static final List<RegExp> maxAssists = [
    RegExp(r'Asistencias?\s*Máx\.?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'Max\.?\s*Assists?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Asistencias?\s*Máx', caseSensitive: false),
  ];

  static final List<RegExp> maxWinStreak = [
    RegExp(
      r'Racha\s*de\s*Victorias?\s*Máx\.?\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(
      r'Max\.?\s*(?:Win(?:ning)?\s*)?Streak\s*[:\s]*(\d+)',
      caseSensitive: false,
    ),
    RegExp(r'(?:Win\s*)?Streak\s*Máx\.?\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Racha\s*Máx', caseSensitive: false),
  ];

  static final List<RegExp> firstBlood = [
    RegExp(r'Primera\s*Sangre\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'First\s*Blood\s*[:\s]*(\d+)', caseSensitive: false),
    RegExp(r'(\d+)\s*Primera\s*Sangre', caseSensitive: false),
    RegExp(r'FB\s*[:\s]*(\d+)', caseSensitive: false),
  ];

  // ==================== MAX DAMAGE DEALT PATTERNS ====================
  static final List<RegExp> maxDamageDealt = [
    // Español - Formatos completos
    RegExp(
      r'Daño\s*Causado\s*Máx\.?\s*(?:/|por)?\s*min\.?\s*[:\s]*(\d{4,6})',
      caseSensitive: false,
    ),
    RegExp(r'Daño\s*Causado\s*Máx\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),
    RegExp(r'DAÑO\s*Causado\s*Máx\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),

    // Inglés
    RegExp(
      r'Max\.?\s*Damage\s*Dealt\s*(?:/|per)?\s*min\.?\s*[:\s]*(\d{4,6})',
      caseSensitive: false,
    ),
    RegExp(r'Damage\s*Dealt\s*Max\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),
    RegExp(r'Max\.?\s*DMG\s*Dealt\s*[:\s]*(\d{4,6})', caseSensitive: false),

    // Variaciones sin "Máx"
    RegExp(r'Daño\s*Causado\s*[:\s]*(\d{4,6})', caseSensitive: false),
    RegExp(r'Causado[^0-9]{0,10}(\d{4,6})', caseSensitive: false),

    // Patrones más generales (4-6 dígitos después de "Daño")
    RegExp(r'Daño[^0-9]{0,20}(\d{4,6})', caseSensitive: false),

    // Búsqueda de números grandes aislados (como último recurso)
    RegExp(
      r'(?:Máx|Max)\.?[^0-9]{0,15}(\d{4,6})(?:\s*(?:/|por)\s*min)?',
      caseSensitive: false,
    ),
  ];

  // ==================== MAX DAMAGE TAKEN PATTERNS ====================
  static final List<RegExp> maxDamageTaken = [
    // Español
    RegExp(
      r'Daño\s*Tomado\s*Máx\.?\s*(?:/|por)?\s*min\.?\s*[:\s]*(\d{4,6})',
      caseSensitive: false,
    ),
    RegExp(r'Daño\s*Tomado\s*Máx\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),
    RegExp(r'DAÑO\s*Tomado\s*Máx\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),
    RegExp(r'Daño\s*Recibido\s*Máx\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),

    // Inglés
    RegExp(
      r'Max\.?\s*Damage\s*Taken\s*(?:/|per)?\s*min\.?\s*[:\s]*(\d{4,6})',
      caseSensitive: false,
    ),
    RegExp(r'Damage\s*Taken\s*Max\.?\s*[:\s]*(\d{4,6})', caseSensitive: false),
    RegExp(r'Max\.?\s*DMG\s*Taken\s*[:\s]*(\d{4,6})', caseSensitive: false),

    // Variaciones
    RegExp(r'Tomado[^0-9]{0,10}(\d{4,6})', caseSensitive: false),
    RegExp(r'Recibido[^0-9]{0,10}(\d{4,6})', caseSensitive: false),
  ];

  // ==================== MAX GOLD PATTERNS ====================
  static final List<RegExp> maxGold = [
    // Español
    RegExp(
      r'Oro\s*Máx\.?\s*(?:/|por)?\s*min\.?\s*[:\s]*(\d{3,5})',
      caseSensitive: false,
    ),
    RegExp(r'Oro\s*Máx\.?\s*[:\s]*(\d{3,5})', caseSensitive: false),

    // Inglés
    RegExp(
      r'Max\.?\s*Gold\s*(?:/|per)?\s*min\.?\s*[:\s]*(\d{3,5})',
      caseSensitive: false,
    ),
    RegExp(r'Gold\s*Max\.?\s*[:\s]*(\d{3,5})', caseSensitive: false),
    RegExp(r'Max\.?\s*GPM\s*[:\s]*(\d{3,5})', caseSensitive: false),
  ];
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

      final sample = text.length > 200 ? text.substring(0, 200) : text;
      _log('Muestra del texto: ${sample.replaceAll('\n', ' | ')}...');

      final lines = text.split('\n').map((line) => line.trim()).toList();
      _log('Total de líneas: ${lines.length}');

      final GameMode mode = _detectGameMode(text);
      _log('Modo detectado: ${mode.displayName}');

      // ==================== EXTRACCIÓN DE ESTADÍSTICAS PRINCIPALES ====================
      _log('\n--- Extrayendo estadísticas principales ---');

      final int totalGames = _extractWithPatterns(
        text,
        _CompiledPatterns.totalGames,
        'Partidas Totales',
        isInteger: true,
      ).toInt();

      // Extraer Win Rate con validación por rango
      final double winRate = _extractWinRateWithValidation(text);

      final int mvpCount = _extractWithPatterns(
        text,
        _CompiledPatterns.mvp,
        'MVP',
        isInteger: true,
      ).toInt();

      // ==================== EXTRACCIÓN DE RENDIMIENTO ====================
      _log('\n--- Extrayendo estadísticas de rendimiento ---');

      final double kda = _extractWithPatterns(
        text,
        _CompiledPatterns.kda,
        'KDA',
      );

      final double teamFightParticipation = _extractWithPatterns(
        text,
        _CompiledPatterns.teamFight,
        'Participación en Equipo',
        validator: (value) => value >= 0 && value <= 100,
      );

      final int goldPerMin = _extractWithPatterns(
        text,
        _CompiledPatterns.goldPerMin,
        'Oro/Min',
        isInteger: true,
      ).toInt();

      final int heroDamagePerMin = _extractWithPatterns(
        text,
        _CompiledPatterns.heroDamagePerMin,
        'DAÑO a Héroe/Min',
        isInteger: true,
      ).toInt();

      final double deathsPerGame = _extractWithPatterns(
        text,
        _CompiledPatterns.deathsPerGame,
        'Muertes/Partida',
      );

      final int towerDamagePerGame = _extractWithPatterns(
        text,
        _CompiledPatterns.towerDamage,
        'Daño a Torre/Partida',
        isInteger: true,
      ).toInt();

      // ==================== EXTRACCIÓN DE LOGROS ====================
      _log('\n--- Extrayendo logros y récords ---');

      final int legendary = _extractWithPatterns(
        text,
        _CompiledPatterns.legendary,
        'Legendario',
        isInteger: true,
      ).toInt();

      final int savage = _extractWithPatterns(
        text,
        _CompiledPatterns.savage,
        'Savage',
        isInteger: true,
      ).toInt();

      final int maniac = _extractWithPatterns(
        text,
        _CompiledPatterns.maniac,
        'Maniac',
        isInteger: true,
      ).toInt();

      final int tripleKill = _extractWithPatterns(
        text,
        _CompiledPatterns.tripleKill,
        'Asesinato Triple',
        isInteger: true,
      ).toInt();

      final int doubleKill = _extractWithPatterns(
        text,
        _CompiledPatterns.doubleKill,
        'Asesinato Doble',
        isInteger: true,
      ).toInt();

      final int mvpLoss = _extractWithPatterns(
        text,
        _CompiledPatterns.mvpLoss,
        'MVP Perdedor',
        isInteger: true,
      ).toInt();

      final int maxKills = _extractWithPatterns(
        text,
        _CompiledPatterns.maxKills,
        'Asesinatos Máx.',
        isInteger: true,
      ).toInt();

      final int maxAssists = _extractWithPatterns(
        text,
        _CompiledPatterns.maxAssists,
        'Asistencias Máx.',
        isInteger: true,
      ).toInt();

      final int maxWinningStreak = _extractWithPatterns(
        text,
        _CompiledPatterns.maxWinStreak,
        'Racha de Victorias Máx.',
        isInteger: true,
      ).toInt();

      final int firstBlood = _extractWithPatterns(
        text,
        _CompiledPatterns.firstBlood,
        'Primera Sangre',
        isInteger: true,
      ).toInt();

      // ==================== EXTRACCIÓN DE VALORES MÁXIMOS ====================
      _log('\n--- Extrayendo valores máximos ---');

      final int maxDamageDealt = _extractWithPatterns(
        text,
        _CompiledPatterns.maxDamageDealt,
        'Daño Causado Máx./min',
        isInteger: true,
        validator: (value) => value >= 1000 && value <= 999999,
      ).toInt();

      final int maxDamageTaken = _extractWithPatterns(
        text,
        _CompiledPatterns.maxDamageTaken,
        'Daño Tomado Máx./min',
        isInteger: true,
        validator: (value) => value >= 1000 && value <= 999999,
      ).toInt();

      final int maxGold = _extractWithPatterns(
        text,
        _CompiledPatterns.maxGold,
        'Oro Máx./min',
        isInteger: true,
        validator: (value) => value >= 100 && value <= 99999,
      ).toInt();

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

  /// Extraer Win Rate con validación por rango
  static double _extractWinRateWithValidation(String text) {
    _log('\n🔍 [WIN RATE] Estrategia: Buscar TODOS los % y validar por rango');

    // Buscar TODOS los porcentajes en el texto
    final allPercentages = <double>[];

    for (final pattern in _CompiledPatterns.winRate) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final valueStr = match.group(1)!.trim().replaceAll(',', '');
          final value = double.tryParse(valueStr);
          if (value != null && !allPercentages.contains(value)) {
            allPercentages.add(value);
            _log('   → Porcentaje encontrado: $value%');
          }
        }
      }
    }

    if (allPercentages.isEmpty) {
      _log('   ✗ No se encontró ningún porcentaje');
      _rawMatches['Tasa de Victorias'] = 0.0;
      return 0.0;
    }

    _log('   📊 Total de porcentajes encontrados: ${allPercentages.length}');
    _log('   📋 Lista: ${allPercentages.join(', ')}');

    // Filtrar por rango típico de Win Rate (40% - 80%)
    final validWinRates = allPercentages
        .where((p) => p >= 40.0 && p <= 80.0)
        .toList();

    if (validWinRates.isEmpty) {
      _log('   ⚠️ Ningún porcentaje en rango válido (40-80%)');
      _log('   💡 Usando el primer porcentaje encontrado como fallback');
      final fallback = allPercentages.first;
      _rawMatches['Tasa de Victorias'] = fallback;
      return fallback;
    }

    _log(
      '   ✓ Porcentajes en rango válido (40-80%): ${validWinRates.join(', ')}',
    );

    // Si hay múltiples, usar el primero
    final winRate = validWinRates.first;
    _log('   ✅ Tasa de Victorias: $winRate%');
    _rawMatches['Tasa de Victorias'] = winRate;

    return winRate;
  }

  /// Método unificado para extraer valores usando múltiples patrones
  static double _extractWithPatterns(
    String text,
    List<RegExp> patterns,
    String fieldName, {
    bool isInteger = false,
    bool Function(double)? validator,
  }) {
    for (int i = 0; i < patterns.length; i++) {
      try {
        final matches = patterns[i].allMatches(text);

        for (var match in matches) {
          if (match.groupCount > 0) {
            final valueStr = match.group(1)!.trim().replaceAll(',', '');
            final value = double.tryParse(valueStr);

            if (value != null) {
              // Validar si se proporciona validador
              if (validator != null && !validator(value)) {
                _log(
                  '⚠ $fieldName: Valor $value descartado por validación (patrón ${i + 1})',
                );
                continue;
              }

              _log('✓ $fieldName: $value (patrón ${i + 1}/${patterns.length})');
              _rawMatches[fieldName] = value;
              return value;
            }
          }
        }
      } catch (e) {
        _log('⚠ Error en patrón ${i + 1} para $fieldName: $e');
      }
    }

    _log(
      '✗ $fieldName: No encontrado con ninguno de los ${patterns.length} patrones',
    );
    _rawMatches[fieldName] = isInteger ? 0 : 0.0;
    return 0.0;
  }

  static GameMode _detectGameMode(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('clasificatoria') || lowerText.contains('ranked')) {
      _log('Modo detectado por palabra clave: Clasificatoria');
      return GameMode.ranked;
    } else if (lowerText.contains('clásica') || lowerText.contains('classic')) {
      _log('Modo detectado por palabra clave: Clásica');
      return GameMode.classic;
    } else if (lowerText.contains('coliseo') || lowerText.contains('brawl')) {
      _log('Modo detectado por palabra clave: Coliseo');
      return GameMode.brawl;
    } else if (lowerText.contains('todos los juegos') ||
        lowerText.contains('all games')) {
      _log('Modo detectado por palabra clave: Todos los Juegos');
      return GameMode.total;
    }

    _log('No se detectó modo específico, usando Total por defecto');
    return GameMode.total;
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
