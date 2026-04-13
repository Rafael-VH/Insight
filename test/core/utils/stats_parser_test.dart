import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/parser/utils/mlbb_parser.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';

void main() {
  group('StatsParser', () {
    // ── parseStats ──────────────────────────────────────────────

    group('parseStats', () {
      test('retorna null si el texto está vacío', () {
        final result = StatsParser.parseStats('', GameMode.total);
        expect(result, isNull);
      });

      test('retorna PlayerStats con el modo correcto', () {
        const text = '''
Todas las Temporadas Todos los Juegos
Partidas Totales 1500
59.29 %
MVP 320
KDA 4.5
Participación en Equipo 78.5%
Oro/Min 750
DAÑO a Héroe/Min 3200
Muertes/Partida 2.1
Daño a Torre/Partida 1200
''';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result, isNotNull);
        expect(result!.mode, equals(GameMode.total));
      });

      test('detecta modo Clasificatoria correctamente', () {
        const text = 'clasificatoria 500 partidas 55.00 %';
        final result = StatsParser.parseStats(text, GameMode.ranked);
        expect(result, isNotNull);
        expect(result!.mode, equals(GameMode.ranked));
      });

      test('detecta modo Clásica correctamente', () {
        const text = 'clásica 200 partidas 60.00 %';
        final result = StatsParser.parseStats(text, GameMode.classic);
        expect(result, isNotNull);
        expect(result!.mode, equals(GameMode.classic));
      });

      test('detecta modo Coliseo correctamente', () {
        const text = 'coliseo 100 partidas 62.00 %';
        final result = StatsParser.parseStats(text, GameMode.brawl);
        expect(result, isNotNull);
        expect(result!.mode, equals(GameMode.brawl));
      });
    });

    // ── parseStatsWithDiagnostics ────────────────────────────────

    group('parseStatsWithDiagnostics', () {
      test('retorna ParseResult con stats null si texto vacío', () {
        final result = StatsParser.parseStatsWithDiagnostics('', GameMode.total);
        expect(result.stats, isNull);
        expect(result.extractionLog, isNotEmpty);
      });

      test('retorna log de extracción no vacío', () {
        const text = '1200 partidas 57.00 % KDA 3.5';
        final result = StatsParser.parseStatsWithDiagnostics(text, GameMode.total);
        expect(result.extractionLog, isNotEmpty);
      });

      test('rawMatches tiene claves para campos encontrados', () {
        const text = '59.29 % KDA 4.5';
        final result = StatsParser.parseStatsWithDiagnostics(text, GameMode.total);
        expect(result.rawMatches, isA<Map<String, dynamic>>());
      });
    });

    // ── Extracción de campos específicos ─────────────────────────

    group('Extracción de Win Rate', () {
      test('extrae porcentaje con dos decimales', () {
        const text = '59.29 %';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.winRate, closeTo(59.29, 0.01));
      });

      test('extrae porcentaje sin decimales', () {
        const text = '55 %';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.winRate, closeTo(55.0, 0.01));
      });

      test('prefiere porcentaje en rango 40-80', () {
        const text = '15 % participación 59.29 % victoria';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.winRate, closeTo(59.29, 0.01));
      });

      test('retorna 0.0 si no hay porcentaje', () {
        const text = 'KDA 4.5 Legendario 10';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.winRate, equals(0.0));
      });
    });

    group('Extracción de Partidas Totales', () {
      test('extrae número de partidas con palabra clave', () {
        const text = '1500 Partidas Totales';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.totalGames, equals(1500));
      });

      test('extrae partidas jugadas', () {
        const text = 'Partidas Jugadas: 800';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.totalGames, equals(800));
      });

      test('retorna 0 si no se encuentran partidas', () {
        const text = 'KDA 3.5 MVP 50';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.totalGames, equals(0));
      });
    });

    group('Extracción de KDA', () {
      test('extrae KDA con prefijo', () {
        const text = 'KDA 4.53';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.kda, closeTo(4.53, 0.01));
      });

      test('extrae KDA con formato separado', () {
        const text = 'KDA: 3.2';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.kda, closeTo(3.2, 0.01));
      });
    });

    group('Extracción de logros', () {
      test('extrae Legendario', () {
        const text = 'Legendario 290';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.legendary, equals(290));
      });

      test('extrae Savage', () {
        const text = 'Savage 9';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.savage, equals(9));
      });

      test('extrae Maniac', () {
        const text = 'Maniac 42';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.maniac, equals(42));
      });

      test('extrae Asesinato Triple', () {
        const text = 'Asesinato Triple 281';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.tripleKill, equals(281));
      });

      test('extrae Asesinato Doble', () {
        const text = 'Asesinato Doble 1929';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.doubleKill, equals(1929));
      });

      test('extrae MVP Perdedor', () {
        const text = 'MVP Perdedor 165';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.mvpLoss, equals(165));
      });

      test('extrae Primera Sangre', () {
        const text = 'Primera Sangre 418';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.firstBlood, equals(418));
      });

      test('extrae Racha de Victorias Máx.', () {
        const text = 'Racha de Victorias Máx. 20';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.maxWinningStreak, equals(20));
      });
    });

    group('Extracción de valores máximos por minuto', () {
      test('extrae Daño Causado Máx./min', () {
        const text = 'Daño Causado Máx./min 10134';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.maxDamageDealt, equals(10134));
      });

      test('extrae Daño tomado Máx./min', () {
        const text = 'Daño tomado Máx./min 15555';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.maxDamageTaken, equals(15555));
      });

      test('extrae Oro Máx./min', () {
        const text = 'Oro Máx./min 1246';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.maxGold, equals(1246));
      });

      test('rechaza valores fuera de rango para maxDamageDealt', () {
        const text = 'Daño Causado Máx./min 50';
        final result = StatsParser.parseStats(text, GameMode.total);
        expect(result!.maxDamageDealt, equals(0));
      });
    });

    // ── getFieldsForVerification ─────────────────────────────────

    group('getFieldsForVerification', () {
      test('retorna lista de 22 campos', () {
        const text = '1200 partidas 59.29 % MVP 50 KDA 3.5';
        final stats = StatsParser.parseStats(text, GameMode.total)!;
        final fields = StatsParser.getFieldsForVerification(stats);
        expect(fields.length, equals(22));
      });

      test('primer campo es Partidas Totales', () {
        const text = '1200 partidas 59.29 %';
        final stats = StatsParser.parseStats(text, GameMode.total)!;
        final fields = StatsParser.getFieldsForVerification(stats);
        expect(fields.first.name, equals('Partidas Totales'));
      });

      test('cada campo tiene name y value no nulos', () {
        const text = '1200 partidas 59.29 % KDA 4.5';
        final stats = StatsParser.parseStats(text, GameMode.total)!;
        final fields = StatsParser.getFieldsForVerification(stats);
        for (final field in fields) {
          expect(field.name, isNotEmpty);
          expect(field.value, isNotNull);
        }
      });
    });

    // ── clearLog ─────────────────────────────────────────────────

    group('clearLog', () {
      test('limpia el log de extracción', () {
        StatsParser.parseStats('1200 partidas 59.29 %', GameMode.total);
        StatsParser.clearLog();
        final log = StatsParser.getExtractionLog();
        expect(log, isEmpty);
      });
    });

    // ── Texto realista completo ──────────────────────────────────

    group('Texto realista de pantalla de MLBB', () {
      const fullText = '''
Todas las Temporadas Todos los Juegos
1500 Partidas Totales
59.29 %
MVP 320
KDA 4.53
Participación en Equipo 78.5%
Oro/Min 750
DAÑO a Héroe/Min 3200
Muertes/Partida 2.1
Daño a Torre/Partida 1200
Legendario 290
Savage 9
Maniac 42
Asesinato Triple 281
Asesinato Doble 1929
MVP Perdedor 165
Asesinatos Máx. 34
Asistencias Máx. 42
Racha de Victorias Máx. 20
Primera Sangre 418
Daño Causado Máx./min 10134
Daño tomado Máx./min 15555
Oro Máx./min 1246
''';

      test('extrae todos los campos principales', () {
        final result = StatsParser.parseStats(fullText, GameMode.total);
        expect(result, isNotNull);
        expect(result!.totalGames, equals(1500));
        expect(result.winRate, closeTo(59.29, 0.01));
        expect(result.mvpCount, equals(320));
        expect(result.kda, closeTo(4.53, 0.01));
        expect(result.legendary, equals(290));
        expect(result.savage, equals(9));
        expect(result.maniac, equals(42));
        expect(result.tripleKill, equals(281));
        expect(result.firstBlood, equals(418));
      });

      test('extrae valores máximos por minuto', () {
        final result = StatsParser.parseStats(fullText, GameMode.total);
        expect(result!.maxDamageDealt, equals(10134));
        expect(result.maxDamageTaken, equals(15555));
        expect(result.maxGold, equals(1246));
      });
    });
  });
}
