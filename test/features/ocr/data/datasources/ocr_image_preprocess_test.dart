import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:insight/features/ocr/data/datasources/ocr_datasource.dart';

/// Fixtures reales del corpus (copias byte a byte de docs/muestra/).
const _kTemporadaActual = 'test/fixtures/ocr/temporadaActual.jpg';
const _kTodasLasTemporadas = 'test/fixtures/ocr/todasLasTemporadas.jpg';

void main() {
  group('shouldUpscaleForOcr', () {
    // Tabla de REQ-1: la decisión depende SOLO del lado más corto.
    const cases = <String, (int width, int height, bool expected)>{
      '1023x632 corpus de producción': (1023, 632, true),
      '632x1023 share rotada (lado corto)': (632, 1023, true),
      '1080x2400 captura de pantalla': (1080, 2400, false),
      'lado corto exactamente 800 pasa': (800, 1200, false),
      'lado corto exactamente 800 (vertical) pasa': (1200, 800, false),
      'lado corto 799 dispara el upscale': (799, 1200, true),
      'lado corto 799 (vertical) dispara el upscale': (1200, 799, true),
      '0x0 nunca escala': (0, 0, false),
      'dimensión negativa nunca escala': (-1, 500, false),
      'alto negativo nunca escala': (500, -1, false),
      'aspecto inusual 4000x300 escala': (4000, 300, true),
      'aspecto inusual 10000x9000 pasa': (10000, 9000, false),
    };

    for (final entry in cases.entries) {
      test('${entry.key} -> ${entry.value.$3}', () {
        expect(
          shouldUpscaleForOcr(entry.value.$1, entry.value.$2),
          entry.value.$3,
        );
      });
    }
  });

  group('preprocessImageForOcr', () {
    test('escala 2x la share real temporadaActual a 2046x1264', () {
      final bytes = File(_kTemporadaActual).readAsBytesSync();

      final upscaled = preprocessImageForOcr(bytes);

      expect(upscaled, isNotNull, reason: 'la share real debe escalarse');
      final decoded = img.decodePng(upscaled!);
      expect(decoded, isNotNull, reason: 'la salida debe ser un PNG válido');
      expect(decoded!.width, 2046);
      expect(decoded.height, 1264);
    });
  });
}
