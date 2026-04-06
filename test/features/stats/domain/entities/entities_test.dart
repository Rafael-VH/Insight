import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

// ── Helpers ────────────────────────────────────────────────────────

PlayerStats _buildPlayerStats({
  GameMode mode = GameMode.total,
  int totalGames = 1000,
  double winRate = 59.29,
}) {
  return PlayerStats(
    mode: mode,
    totalGames: totalGames,
    winRate: winRate,
    mvpCount: 200,
    legendary: 100,
    savage: 5,
    maniac: 30,
    tripleKill: 200,
    doubleKill: 1500,
    mvpLoss: 100,
    maxKills: 25,
    maxAssists: 35,
    maxWinningStreak: 15,
    firstBlood: 300,
    maxDamageDealt: 9000,
    maxDamageTaken: 12000,
    maxGold: 1100,
    kda: 4.5,
    teamFightParticipation: 75.0,
    goldPerMin: 700,
    heroDamagePerMin: 3000,
    deathsPerGame: 2.0,
    towerDamagePerGame: 1000,
    oroMaxMin: 1100,
    danoTomadoMaxMin: 12000,
    danoCausadoMaxMin: 9000,
  );
}

void main() {
  // ================================================================
  // PlayerStats
  // ================================================================

  group('PlayerStats', () {
    group('constructor', () {
      test('crea una instancia con todos los campos', () {
        final stats = _buildPlayerStats();
        expect(stats.mode, equals(GameMode.total));
        expect(stats.totalGames, equals(1000));
        expect(stats.winRate, closeTo(59.29, 0.001));
      });
    });

    group('copyWith', () {
      test('actualiza solo los campos especificados', () {
        final original = _buildPlayerStats(totalGames: 1000);
        final copy = original.copyWith(totalGames: 2000);
        expect(copy.totalGames, equals(2000));
        expect(copy.winRate, equals(original.winRate));
        expect(copy.mode, equals(original.mode));
      });

      test('retorna un objeto distinto al original', () {
        final original = _buildPlayerStats();
        final copy = original.copyWith(totalGames: 500);
        expect(identical(original, copy), isFalse);
      });

      test('actualiza el modo correctamente', () {
        final original = _buildPlayerStats(mode: GameMode.total);
        final copy = original.copyWith(mode: GameMode.ranked);
        expect(copy.mode, equals(GameMode.ranked));
      });
    });

    group('toJson', () {
      test('serializa todos los campos esperados', () {
        final stats = _buildPlayerStats();
        final json = stats.toJson();
        expect(json['mode'], equals(GameMode.total.name));
        expect(json['totalGames'], equals(1000));
        expect(json['winRate'], closeTo(59.29, 0.001));
        expect(json['kda'], equals(4.5));
        expect(json.containsKey('legendary'), isTrue);
        expect(json.containsKey('savage'), isTrue);
      });

      test('serializa modo como string (nombre del enum)', () {
        final stats = _buildPlayerStats(mode: GameMode.ranked);
        final json = stats.toJson();
        expect(json['mode'], equals('ranked'));
      });
    });

    group('fromJson', () {
      test('deserializa correctamente desde un mapa válido', () {
        final stats = _buildPlayerStats(
          mode: GameMode.classic,
          totalGames: 500,
          winRate: 61.5,
        );
        final json = stats.toJson();
        final restored = PlayerStats.fromJson(json);
        expect(restored.mode, equals(GameMode.classic));
        expect(restored.totalGames, equals(500));
        expect(restored.winRate, closeTo(61.5, 0.001));
      });

      test('usa GameMode.total como fallback para modo desconocido', () {
        final json = _buildPlayerStats().toJson();
        json['mode'] = 'unknown_mode';
        final restored = PlayerStats.fromJson(json);
        expect(restored.mode, equals(GameMode.total));
      });

      test('tolera valores int donde se espera double', () {
        final json = _buildPlayerStats().toJson();
        json['winRate'] = 60; // int en lugar de double
        final restored = PlayerStats.fromJson(json);
        expect(restored.winRate, closeTo(60.0, 0.001));
      });

      test('tolera valores double donde se espera int', () {
        final json = _buildPlayerStats().toJson();
        json['totalGames'] = 500.0; // double en lugar de int
        final restored = PlayerStats.fromJson(json);
        expect(restored.totalGames, equals(500));
      });

      test('tolera valores string numéricos', () {
        final json = _buildPlayerStats().toJson();
        json['totalGames'] = '750';
        json['winRate'] = '58.33';
        final restored = PlayerStats.fromJson(json);
        expect(restored.totalGames, equals(750));
        expect(restored.winRate, closeTo(58.33, 0.01));
      });

      test('usa 0 para campos nulos o inválidos', () {
        final json = _buildPlayerStats().toJson();
        json['totalGames'] = null;
        json['kda'] = null;
        final restored = PlayerStats.fromJson(json);
        expect(restored.totalGames, equals(0));
        expect(restored.kda, equals(0.0));
      });

      test('ida y vuelta toJson → fromJson preserva los datos', () {
        final original = _buildPlayerStats(
          mode: GameMode.brawl,
          totalGames: 300,
          winRate: 62.75,
        );
        final restored = PlayerStats.fromJson(original.toJson());
        expect(restored.mode, equals(original.mode));
        expect(restored.totalGames, equals(original.totalGames));
        expect(restored.winRate, closeTo(original.winRate, 0.001));
        expect(restored.kda, equals(original.kda));
        expect(restored.legendary, equals(original.legendary));
      });
    });
  });

  // ================================================================
  // StatsCollection
  // ================================================================

  group('StatsCollection', () {
    final now = DateTime(2025, 6, 1, 12, 0, 0);
    final totalStats = _buildPlayerStats(mode: GameMode.total);
    final rankedStats = _buildPlayerStats(mode: GameMode.ranked);

    group('constructor', () {
      test('crea instancia con name vacío por defecto', () {
        final col = StatsCollection(createdAt: now);
        expect(col.name, equals(''));
      });

      test('acepta nombre personalizado', () {
        final col = StatsCollection(createdAt: now, name: 'Partida del sábado');
        expect(col.name, equals('Partida del sábado'));
      });
    });

    group('hasAnyStats', () {
      test('false cuando no tiene ninguna estadística', () {
        final col = StatsCollection(createdAt: now);
        expect(col.hasAnyStats, isFalse);
      });

      test('true con totalStats', () {
        final col = StatsCollection(createdAt: now, totalStats: totalStats);
        expect(col.hasAnyStats, isTrue);
      });

      test('true con rankedStats únicamente', () {
        final col = StatsCollection(createdAt: now, rankedStats: rankedStats);
        expect(col.hasAnyStats, isTrue);
      });
    });

    group('availableStats', () {
      test('lista vacía cuando no hay estadísticas', () {
        final col = StatsCollection(createdAt: now);
        expect(col.availableStats, isEmpty);
      });

      test('lista con un elemento cuando solo hay totalStats', () {
        final col = StatsCollection(createdAt: now, totalStats: totalStats);
        expect(col.availableStats.length, equals(1));
        expect(col.availableStats.first.mode, equals(GameMode.total));
      });

      test('lista con dos elementos cuando hay total y ranked', () {
        final col = StatsCollection(
          createdAt: now,
          totalStats: totalStats,
          rankedStats: rankedStats,
        );
        expect(col.availableStats.length, equals(2));
      });

      test('incluye todos los modos cuando están presentes', () {
        final col = StatsCollection(
          createdAt: now,
          totalStats: _buildPlayerStats(mode: GameMode.total),
          rankedStats: _buildPlayerStats(mode: GameMode.ranked),
          classicStats: _buildPlayerStats(mode: GameMode.classic),
          brawlStats: _buildPlayerStats(mode: GameMode.brawl),
        );
        expect(col.availableStats.length, equals(4));
      });
    });

    group('displayName', () {
      test('retorna el nombre personalizado cuando está definido', () {
        final col = StatsCollection(
          createdAt: now,
          name: 'Mi sesión ranked',
          totalStats: totalStats,
        );
        expect(col.displayName, equals('Mi sesión ranked'));
      });

      test('genera nombre automático cuando name está vacío', () {
        final col = StatsCollection(
          createdAt: now,
          totalStats: totalStats,
          rankedStats: rankedStats,
        );
        expect(col.displayName, contains('Total'));
      });

      test('retorna Sin estadísticas cuando no hay modos', () {
        final col = StatsCollection(createdAt: now);
        expect(col.displayName, equals('Sin estadísticas'));
      });
    });

    group('copyWith', () {
      test('actualiza solo el nombre', () {
        final col = StatsCollection(
          createdAt: now,
          name: 'Nombre original',
          totalStats: totalStats,
        );
        final copy = col.copyWith(name: 'Nombre nuevo');
        expect(copy.name, equals('Nombre nuevo'));
        expect(copy.totalStats, equals(totalStats));
        expect(copy.createdAt, equals(now));
      });

      test('actualiza totalStats', () {
        final col = StatsCollection(createdAt: now);
        final copy = col.copyWith(totalStats: totalStats);
        expect(copy.totalStats, equals(totalStats));
      });
    });
  });

  // ================================================================
  // GameMode
  // ================================================================

  group('GameMode', () {
    test('total tiene shortName correcto', () {
      expect(GameMode.total.shortName, equals('Total'));
    });

    test('ranked tiene shortName correcto', () {
      expect(GameMode.ranked.shortName, equals('Clasificatoria'));
    });

    test('classic tiene shortName correcto', () {
      expect(GameMode.classic.shortName, equals('Clásica'));
    });

    test('brawl tiene shortName correcto', () {
      expect(GameMode.brawl.shortName, equals('Coliseo'));
    });

    test('todos los modos tienen displayName no vacío', () {
      for (final mode in GameMode.values) {
        expect(mode.displayName, isNotEmpty);
      }
    });
  });
}