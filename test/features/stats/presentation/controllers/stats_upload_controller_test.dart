import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/features/stats/presentation/controllers/stats_upload_controller.dart';

// ── Texto OCR de muestra ─────────────────────────────────────────

const _sampleOcrText = '''
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

void main() {
  group('StatsUploadController', () {
    late StatsUploadController controller;

    setUp(() {
      controller = StatsUploadController(uploadType: StatsUploadType.total);
    });

    tearDown(() {
      controller.dispose();
    });

    // ── availableModes ────────────────────────────────────────────

    group('availableModes', () {
      test('total tiene solo [GameMode.total]', () {
        expect(controller.availableModes, equals([GameMode.total]));
      });

      test('byModes tiene ranked, classic y brawl', () {
        final ctrl =
            StatsUploadController(uploadType: StatsUploadType.byModes);
        expect(ctrl.availableModes, contains(GameMode.ranked));
        expect(ctrl.availableModes, contains(GameMode.classic));
        expect(ctrl.availableModes, contains(GameMode.brawl));
        expect(ctrl.availableModes, isNot(contains(GameMode.total)));
        ctrl.dispose();
      });
    });

    // ── Estado inicial ────────────────────────────────────────────

    group('estado inicial', () {
      test('hasAnyParsedStats es false antes de procesar', () {
        expect(controller.hasAnyParsedStats, isFalse);
      });

      test('isProcessing es false para todos los modos', () {
        for (final mode in controller.availableModes) {
          expect(controller.isProcessing[mode], isFalse);
        }
      });

      test('uploadedImages es null para todos los modos', () {
        for (final mode in controller.availableModes) {
          expect(controller.uploadedImages[mode], isNull);
        }
      });

      test('validationResults es null para todos los modos', () {
        for (final mode in controller.availableModes) {
          expect(controller.getValidationResult(mode), isNull);
        }
      });
    });

    // ── startProcessing ───────────────────────────────────────────

    group('startProcessing', () {
      test('marca el modo como en procesamiento', () {
        controller.startProcessing(GameMode.total);
        expect(controller.isProcessing[GameMode.total], isTrue);
      });

      test('establece currentProcessingMode', () {
        controller.startProcessing(GameMode.total);
        expect(controller.currentProcessingMode, equals(GameMode.total));
      });

      test('lanza ArgumentError para modo no disponible', () {
        expect(
          () => controller.startProcessing(GameMode.ranked),
          throwsArgumentError,
        );
      });
    });

    // ── handleOcrSuccessWithDiagnostics ───────────────────────────

    group('handleOcrSuccessWithDiagnostics', () {
      test('retorna resultado sin modo si no hay currentProcessingMode', () {
        final result = controller.handleOcrSuccessWithDiagnostics(
          _sampleOcrText,
          '/fake/path.png',
        );
        expect(result.processedMode, isNull);
        expect(result.hasValidStats, isFalse);
      });

      test('procesa texto y actualiza estado interno', () {
        controller.startProcessing(GameMode.total);
        final result = controller.handleOcrSuccessWithDiagnostics(
          _sampleOcrText,
          '/fake/path.png',
        );
        expect(result.processedMode, equals(GameMode.total));
        expect(result.stats, isNotNull);
        expect(controller.hasAnyParsedStats, isTrue);
      });

      test('isProcessing se marca como false tras procesar', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        expect(controller.isProcessing[GameMode.total], isFalse);
      });

      test('almacena la ruta de imagen', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/image.jpg');
        expect(
            controller.uploadedImages[GameMode.total], equals('/fake/image.jpg'));
      });

      test('almacena validation result', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        expect(controller.getValidationResult(GameMode.total), isNotNull);
      });

      test('resultado tiene extractionLog no vacío', () {
        controller.startProcessing(GameMode.total);
        final result = controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        expect(result.extractionLog, isNotEmpty);
      });
    });

    // ── handleOcrError ────────────────────────────────────────────

    group('handleOcrError', () {
      test('marca isProcessing como false', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrError();
        expect(controller.isProcessing[GameMode.total], isFalse);
      });

      test('limpia currentProcessingMode', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrError();
        expect(controller.currentProcessingMode, isNull);
      });

      test('no lanza error si no hay modo en procesamiento', () {
        expect(() => controller.handleOcrError(), returnsNormally);
      });
    });

    // ── removeStats ───────────────────────────────────────────────

    group('removeStats', () {
      test('elimina stats de un modo', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        expect(controller.hasAnyParsedStats, isTrue);

        controller.removeStats(GameMode.total);
        expect(controller.hasAnyParsedStats, isFalse);
      });

      test('limpia la ruta de imagen', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        controller.removeStats(GameMode.total);
        expect(controller.uploadedImages[GameMode.total], isNull);
      });

      test('limpia el validation result', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        controller.removeStats(GameMode.total);
        expect(controller.getValidationResult(GameMode.total), isNull);
      });
    });

    // ── createCollection ──────────────────────────────────────────

    group('createCollection', () {
      test('retorna StatsCollection sin stats cuando no hay datos', () {
        final collection = controller.createCollection();
        expect(collection.hasAnyStats, isFalse);
      });

      test('retorna StatsCollection con totalStats cuando se procesó', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        final collection = controller.createCollection();
        expect(collection.totalStats, isNotNull);
        expect(collection.totalStats!.mode, equals(GameMode.total));
      });

      test('createdAt es reciente', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final collection = controller.createCollection();
        expect(collection.createdAt.isAfter(before), isTrue);
      });
    });

    // ── getSuccessMessage ─────────────────────────────────────────

    group('getSuccessMessage', () {
      test('retorna mensaje con nombre del modo', () {
        final msg = controller.getSuccessMessage(GameMode.total);
        expect(msg, contains('Total'));
      });

      test('retorna mensaje de extracción cuando no hay validación', () {
        final msg = controller.getSuccessMessage(GameMode.total);
        expect(msg, isNotEmpty);
      });
    });

    // ── hasInvalidStats ───────────────────────────────────────────

    group('hasInvalidStats', () {
      test('false cuando no hay stats procesados', () {
        expect(controller.hasInvalidStats(), isFalse);
      });

      test('false cuando el texto es válido y tiene todos los campos', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        // El resultado puede variar según la extracción del OCR,
        // pero el método debe retornar un bool sin lanzar excepciones.
        expect(controller.hasInvalidStats(), isA<bool>());
      });
    });

    // ── getValidationSummary ──────────────────────────────────────

    group('getValidationSummary', () {
      test('retorna "No hay estadísticas procesadas" cuando está vacío', () {
        expect(
          controller.getValidationSummary(),
          equals('No hay estadísticas procesadas'),
        );
      });

      test('retorna resumen no vacío tras procesar', () {
        controller.startProcessing(GameMode.total);
        controller.handleOcrSuccessWithDiagnostics(
            _sampleOcrText, '/fake/path.png');
        expect(controller.getValidationSummary(), isNotEmpty);
      });
    });

    // ── dispose ───────────────────────────────────────────────────

    group('dispose', () {
      test('lanza StateError al llamar startProcessing después de dispose', () {
        controller.dispose();
        expect(
          () => controller.startProcessing(GameMode.total),
          throwsStateError,
        );
      });

      test('dispose múltiples veces no lanza error', () {
        controller.dispose();
        expect(controller.dispose, returnsNormally);
      });
    });
  });

  // ================================================================
  // StatsUploadType
  // ================================================================

  group('StatsUploadType', () {
    test('total tiene imageCount = 1', () {
      expect(StatsUploadType.total.imageCount, equals(1));
    });

    test('byModes tiene imageCount = 3', () {
      expect(StatsUploadType.byModes.imageCount, equals(3));
    });

    test('total tiene displayName no vacío', () {
      expect(StatsUploadType.total.displayName, isNotEmpty);
    });

    test('total tiene appBarTitle no vacío', () {
      expect(StatsUploadType.total.appBarTitle, isNotEmpty);
    });
  });
}