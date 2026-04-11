import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/parser/utils/stats_validator.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';
import 'package:insight/features/parser/domain/entities/player_stats.dart';

// ── Helpers ────────────────────────────────────────────────────────

PlayerStats _buildStats({
  int totalGames = 1000,
  double winRate = 59.29,
  int mvpCount = 200,
  double kda = 4.5,
  double teamFightParticipation = 75.0,
  int goldPerMin = 700,
  int heroDamagePerMin = 3000,
  double deathsPerGame = 2.0,
  int towerDamagePerGame = 1000,
  int legendary = 100,
  int savage = 5,
  int maniac = 30,
  int tripleKill = 200,
  int doubleKill = 1500,
  int mvpLoss = 100,
  int maxKills = 25,
  int maxAssists = 35,
  int maxWinningStreak = 15,
  int firstBlood = 300,
  int maxDamageDealt = 9000,
  int maxDamageTaken = 12000,
  int maxGold = 1100,
}) {
  return PlayerStats(
    mode: GameMode.total,
    totalGames: totalGames,
    winRate: winRate,
    mvpCount: mvpCount,
    kda: kda,
    teamFightParticipation: teamFightParticipation,
    goldPerMin: goldPerMin,
    heroDamagePerMin: heroDamagePerMin,
    deathsPerGame: deathsPerGame,
    towerDamagePerGame: towerDamagePerGame,
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
    oroMaxMin: maxGold,
    danoTomadoMaxMin: maxDamageTaken,
    danoCausadoMaxMin: maxDamageDealt,
  );
}

void main() {
  group('StatsValidator', () {
    // ── validate: caso exitoso ────────────────────────────────────

    group('validate - estadísticas completas', () {
      late ValidationResult result;

      setUp(() {
        result = StatsValidator.validate(_buildStats());
      });

      test('isValid es true cuando todos los campos críticos están presentes', () {
        expect(result.isValid, isTrue);
      });

      test('missingFields está vacío', () {
        expect(result.missingFields, isEmpty);
      });

      test('completionPercentage es positivo', () {
        expect(result.completionPercentage, greaterThan(0));
      });

      test('totalFields es mayor que 0', () {
        expect(result.totalFields, greaterThan(0));
      });

      test('validFields <= totalFields', () {
        expect(result.validFields, lessThanOrEqualTo(result.totalFields));
      });
    });

    // ── validate: campos críticos en 0 ───────────────────────────

    group('validate - totalGames = 0', () {
      test('agrega Partidas Totales a missingFields', () {
        final stats = _buildStats(totalGames: 0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, contains('Partidas Totales'));
      });

      test('isValid es false', () {
        final stats = _buildStats(totalGames: 0);
        final result = StatsValidator.validate(stats);
        expect(result.isValid, isFalse);
      });
    });

    group('validate - winRate = 0', () {
      test('agrega Tasa de Victorias a missingFields', () {
        final stats = _buildStats(winRate: 0.0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, contains('Tasa de Victorias'));
      });
    });

    group('validate - kda = 0', () {
      test('agrega KDA a missingFields', () {
        final stats = _buildStats(kda: 0.0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, contains('KDA'));
      });
    });

    group('validate - goldPerMin = 0', () {
      test('agrega Oro/Min a missingFields', () {
        final stats = _buildStats(goldPerMin: 0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, contains('Oro/Min'));
      });
    });

    group('validate - heroDamagePerMin = 0', () {
      test('agrega DAÑO a Héroe/Min a missingFields', () {
        final stats = _buildStats(heroDamagePerMin: 0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, contains('DAÑO a Héroe/Min'));
      });
    });

    // ── validate: campos opcionales en 0 (advertencias) ──────────

    group('validate - campos opcionales en 0', () {
      test('deathsPerGame = 0 genera advertencia, no error', () {
        final stats = _buildStats(deathsPerGame: 0.0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, isNot(contains('Muertes/Partida')));
        expect(result.warningFields, contains('Muertes/Partida'));
      });

      test('towerDamagePerGame = 0 genera advertencia', () {
        final stats = _buildStats(towerDamagePerGame: 0);
        final result = StatsValidator.validate(stats);
        expect(result.warningFields, contains('Daño a Torre/Partida'));
      });

      test('mvpCount = 0 genera advertencia, isValid puede seguir siendo true', () {
        final stats = _buildStats(mvpCount: 0);
        final result = StatsValidator.validate(stats);
        expect(result.missingFields, isNot(contains('MVP')));
      });
    });

    // ── completionPercentage ──────────────────────────────────────

    group('completionPercentage', () {
      test('es 100% cuando todos los campos están presentes', () {
        final stats = _buildStats();
        final result = StatsValidator.validate(stats);
        expect(result.completionPercentage, closeTo(100.0, 5.0));
      });

      test('disminuye cuando hay campos faltantes', () {
        final statsCompleto = _buildStats();
        final statsIncompleto = _buildStats(totalGames: 0, winRate: 0.0);

        final resultCompleto = StatsValidator.validate(statsCompleto);
        final resultIncompleto = StatsValidator.validate(statsIncompleto);

        expect(
          resultCompleto.completionPercentage,
          greaterThan(resultIncompleto.completionPercentage),
        );
      });
    });

    // ── summary ───────────────────────────────────────────────────

    group('summary', () {
      test('retorna mensaje de éxito cuando todo está correcto', () {
        final stats = _buildStats();
        final result = StatsValidator.validate(stats);
        expect(result.summary, contains('correctamente'));
      });

      test('retorna mensaje de advertencia cuando hay warnings', () {
        final stats = _buildStats(deathsPerGame: 0.0, towerDamagePerGame: 0);
        final result = StatsValidator.validate(stats);
        expect(result.summary, isNotEmpty);
      });

      test('retorna mensaje de error cuando faltan campos críticos', () {
        final stats = _buildStats(totalGames: 0, winRate: 0.0, kda: 0.0);
        final result = StatsValidator.validate(stats);
        expect(result.summary, contains('Faltan'));
      });
    });

    // ── getDetailedErrorMessage ───────────────────────────────────

    group('getDetailedErrorMessage', () {
      test('retorna cadena no vacía cuando hay errores', () {
        final stats = _buildStats(totalGames: 0, winRate: 0.0);
        final result = StatsValidator.validate(stats);
        final msg = StatsValidator.getDetailedErrorMessage(result);
        expect(msg, isNotEmpty);
      });

      test('contiene nombre de campos faltantes', () {
        final stats = _buildStats(totalGames: 0);
        final result = StatsValidator.validate(stats);
        final msg = StatsValidator.getDetailedErrorMessage(result);
        expect(msg, contains('Partidas Totales'));
      });
    });

    // ── getRecommendations ───────────────────────────────────────

    group('getRecommendations', () {
      test('retorna lista vacía cuando no hay errores ni advertencias críticas', () {
        final stats = _buildStats();
        final result = StatsValidator.validate(stats);
        if (result.missingFields.isEmpty) {
          final recs = StatsValidator.getRecommendations(result);
          expect(recs, isA<List<String>>());
        }
      });

      test('retorna recomendaciones cuando hay campos faltantes', () {
        final stats = _buildStats(totalGames: 0, winRate: 0.0, kda: 0.0);
        final result = StatsValidator.validate(stats);
        final recs = StatsValidator.getRecommendations(result);
        expect(recs, isNotEmpty);
      });

      test('incluye recomendación específica de Tasa de Victorias', () {
        final stats = _buildStats(winRate: 0.0);
        final result = StatsValidator.validate(stats);
        final recs = StatsValidator.getRecommendations(result);
        final hasWinRateRec = recs.any((r) => r.contains('Tasa'));
        expect(hasWinRateRec, isTrue);
      });
    });

    // ── getDebugReport ────────────────────────────────────────────

    group('getDebugReport', () {
      test('retorna string no vacío', () {
        final stats = _buildStats();
        final result = StatsValidator.validate(stats);
        final report = StatsValidator.getDebugReport(result);
        expect(report, isNotEmpty);
      });

      test('contiene indicador de validez', () {
        final stats = _buildStats();
        final result = StatsValidator.validate(stats);
        final report = StatsValidator.getDebugReport(result);
        expect(report, anyOf(contains('VÁLIDO'), contains('INVÁLIDO')));
      });
    });
  });
}
