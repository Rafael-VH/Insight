import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/ocr/data/datasources/ocr_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockTextRecognizer extends Mock implements TextRecognizer {}

class _MockImagePicker extends Mock implements ImagePicker {}

/// Canal de path_provider: `getTemporaryDirectory` lo resuelve el host.
const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

const _kFixture = 'test/fixtures/ocr/temporadaActual.jpg';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `any()` necesita un valor de referencia para el tipo del parámetro.
  setUpAll(
    () => registerFallbackValue(InputImage.fromFilePath('fallback.png')),
  );

  late Directory tempDir;
  late _MockTextRecognizer recognizer;
  late List<InputImage> captured;
  late Uint8List? capturedBytes;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ocr_upscale_test');
    recognizer = _MockTextRecognizer();
    captured = <InputImage>[];
    capturedBytes = null;

    // Captura el InputImage REAL que recibe ML Kit, junto a los bytes en disco
    // que ese path apunta en ese instante (antes del borrado en finally).
    when(() => recognizer.processImage(any())).thenAnswer((invocation) async {
      final inputImage = invocation.positionalArguments.first as InputImage;
      captured.add(inputImage);
      final file = File(inputImage.filePath!);
      if (file.existsSync()) {
        capturedBytes = file.readAsBytesSync();
      }
      return RecognizedText(text: 'MVP 320', blocks: const <TextBlock>[]);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _pathProviderChannel,
          (call) async => tempDir.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  OcrDataSourceImpl buildDataSource() => OcrDataSourceImpl(
    imagePicker: _MockImagePicker(),
    textRecognizer: recognizer,
  );

  File realShareIn(Directory dir) =>
      File('${dir.path}/temporadaActual.jpg')
        ..writeAsBytesSync(File(_kFixture).readAsBytesSync());

  File garbageIn(Directory dir) => File('${dir.path}/basura.jpg')
    ..writeAsBytesSync(
      Uint8List.fromList(List<int>.generate(512, (i) => (i * 37) % 256)),
    );

  group('recognizeText — rama de preprocesado', () {
    test(
      'REQ-4/6 upscale: ML Kit recibe un PNG temporal 2046x1264 y el resultado '
      'conserva la ruta original',
      () async {
        final original = realShareIn(tempDir);

        final result = await buildDataSource().recognizeText(original.path);

        // La imagen entregada NO es la original, sino el PNG temporal.
        expect(captured.single.filePath, isNot(original.path));
        expect(captured.single.filePath, startsWith(tempDir.path));
        expect(
          captured.single.filePath,
          contains(RegExp(r'ocr_upscale_\d+\.png$')),
        );
        // Ese archivo temporal es el PNG escalado real, no un stub.
        final decoded = img.decodePng(capturedBytes!);
        expect(decoded, isNotNull);
        expect(decoded!.width, 2046);
        expect(decoded.height, 1264);
        // REQ-6: el thumbnail sigue viendo la imagen que el usuario tomó.
        expect(result.imagePath, original.path);
        // El temporal no se acumula en disco.
        expect(File(captured.single.filePath!).existsSync(), isFalse);
      },
    );

    test('el PNG temporal se borra aunque el reconocedor falle', () async {
      when(() => recognizer.processImage(any())).thenAnswer((invocation) async {
        captured.add(invocation.positionalArguments.first as InputImage);
        throw Exception('fallo nativo');
      });
      final original = realShareIn(tempDir);

      await expectLater(
        () => buildDataSource().recognizeText(original.path),
        throwsA(isA<TextRecognitionFailure>()),
      );

      expect(captured.single.filePath, isNot(original.path));
      expect(File(captured.single.filePath!).existsSync(), isFalse);
    });
  });

  group('recognizeText — degradación (REQ-5)', () {
    test(
      'decodificación nula: el reconocedor recibe la ruta original',
      () async {
        final garbage = garbageIn(tempDir);

        final result = await buildDataSource().recognizeText(garbage.path);

        expect(captured.single.filePath, garbage.path);
        expect(result.imagePath, garbage.path);
      },
    );

    test('preprocesado que lanza: se degrada a la ruta original', () async {
      final missing = '${tempDir.path}/no-existe.jpg';

      final result = await buildDataSource().recognizeText(missing);

      expect(captured.single.filePath, missing);
      expect(result.imagePath, missing);
    });

    test('degradación no deja archivos temporales', () async {
      final garbage = garbageIn(tempDir);

      await buildDataSource().recognizeText(garbage.path);

      expect(tempDir.listSync().where((e) => e.path.endsWith('.png')), isEmpty);
    });
  });
}
