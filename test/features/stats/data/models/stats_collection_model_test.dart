import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/upload/data/model/game_session_model.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';
import 'package:insight/features/parser/domain/entities/player_performance.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

PlayerStats _buildStats(GameMode mode) => PlayerStats(
  mode: mode,
  totalGames: 500,
  winRate: 58.5,
  mvpCount: 100,
  legendary: 50,
  savage: 3,
  maniac: 20,
  tripleKill: 100,
  doubleKill: 800,
  mvpLoss: 60,
  maxKills: 20,
  maxAssists: 30,
  maxWinningStreak: 10,
  firstBlood: 150,
  maxDamageDealt: 8000,
  maxDamageTaken: 10000,
  maxGold: 950,
  kda: 3.8,
  teamFightParticipation: 70.0,
  goldPerMin: 650,
  heroDamagePerMin: 2800,
  deathsPerGame: 2.5,
  towerDamagePerGame: 900,
  oroMaxMin: 950,
  danoTomadoMaxMin: 10000,
  danoCausadoMaxMin: 8000,
);

void main() {
  group('StatsCollectionModel', () {
    final now = DateTime(2025, 6, 1, 12, 0, 0);
    final total = _buildStats(GameMode.total);
    final ranked = _buildStats(GameMode.ranked);

    // ── fromEntity ───────────────────────────────────────────────

    group('fromEntity', () {
      test('crea un modelo desde una entidad sin perder datos', () {
        final entity = StatsCollection(
          createdAt: now,
          totalStats: total,
          rankedStats: ranked,
          name: 'Test',
        );
        final model = StatsCollectionModel.fromEntity(entity);
        expect(model.createdAt, equals(now));
        expect(model.totalStats?.mode, equals(GameMode.total));
        expect(model.rankedStats?.mode, equals(GameMode.ranked));
        expect(model.name, equals('Test'));
      });

      test('preserva statsNulls cuando la entidad no las tiene', () {
        final entity = StatsCollection(createdAt: now);
        final model = StatsCollectionModel.fromEntity(entity);
        expect(model.totalStats, isNull);
        expect(model.rankedStats, isNull);
        expect(model.classicStats, isNull);
        expect(model.brawlStats, isNull);
      });
    });

    // ── toJson ───────────────────────────────────────────────────

    group('toJson', () {
      test('serializa createdAt como ISO 8601', () {
        final model = StatsCollectionModel(createdAt: now);
        final json = model.toJson();
        expect(json['createdAt'], equals(now.toIso8601String()));
      });

      test('serializa totalStats como mapa cuando está presente', () {
        final model = StatsCollectionModel(createdAt: now, totalStats: total);
        final json = model.toJson();
        expect(json['totalStats'], isA<Map<String, dynamic>>());
      });

      test('serializa totalStats como null cuando está ausente', () {
        final model = StatsCollectionModel(createdAt: now);
        final json = model.toJson();
        expect(json['totalStats'], isNull);
      });

      test('serializa el nombre', () {
        final model = StatsCollectionModel(createdAt: now, name: 'mi sesión');
        final json = model.toJson();
        expect(json['name'], equals('mi sesión'));
      });

      test('incluye todas las claves requeridas', () {
        final model = StatsCollectionModel(createdAt: now, totalStats: total);
        final json = model.toJson();
        for (final key in [
          'totalStats',
          'rankedStats',
          'classicStats',
          'brawlStats',
          'createdAt',
          'name',
        ]) {
          expect(json.containsKey(key), isTrue, reason: 'falta clave: $key');
        }
      });
    });

    // ── fromJson ─────────────────────────────────────────────────

    group('fromJson', () {
      test('deserializa un JSON válido con todas las estadísticas', () {
        final original = StatsCollectionModel(
          createdAt: now,
          totalStats: total,
          rankedStats: ranked,
          name: 'completa',
        );
        final json = original.toJson();
        final restored = StatsCollectionModel.fromJson(json);

        expect(restored.createdAt, equals(now));
        expect(restored.totalStats?.mode, equals(GameMode.total));
        expect(restored.rankedStats?.mode, equals(GameMode.ranked));
        expect(restored.name, equals('completa'));
      });

      test('tolera statsNulls en el JSON', () {
        final json = {
          'totalStats': null,
          'rankedStats': null,
          'classicStats': null,
          'brawlStats': null,
          'createdAt': now.toIso8601String(),
          'name': '',
        };
        final model = StatsCollectionModel.fromJson(json);
        expect(model.totalStats, isNull);
        expect(model.hasAnyStats, isFalse);
      });

      test('usa string vacío para name cuando es null en el JSON', () {
        final json = {
          'totalStats': null,
          'rankedStats': null,
          'classicStats': null,
          'brawlStats': null,
          'createdAt': now.toIso8601String(),
        };
        final model = StatsCollectionModel.fromJson(json);
        expect(model.name, equals(''));
      });

      test('ida y vuelta toJson → fromJson preserva los datos', () {
        final original = StatsCollectionModel(
          createdAt: now,
          totalStats: total,
          rankedStats: ranked,
          classicStats: _buildStats(GameMode.classic),
          brawlStats: _buildStats(GameMode.brawl),
          name: 'sesión completa',
        );
        final restored = StatsCollectionModel.fromJson(original.toJson());

        expect(restored.createdAt, equals(original.createdAt));
        expect(restored.totalStats?.totalGames, equals(original.totalStats?.totalGames));
        expect(restored.rankedStats?.winRate, closeTo(original.rankedStats!.winRate, 0.001));
        expect(restored.name, equals(original.name));
        expect(restored.availableStats.length, equals(4));
      });
    });
  });
}
