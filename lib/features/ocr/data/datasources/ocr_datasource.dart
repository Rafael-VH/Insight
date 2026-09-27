import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/ocr/data/models/ocr_result_model.dart';
import 'package:insight/features/ocr/domain/entities/ocr_image_source.dart';
import 'package:insight/features/ocr/domain/entities/ocr_result.dart';

/// Lado más corto (px) por debajo del cual la imagen de entrada se escala 2x.
/// REQ-1 — 19% de margen: el corpus real mide 1023x632 (lado corto 632).
const int kOcrMinSideForUpscale = 800;

/// Factor de escalado del preprocesado de OCR.
const int kOcrUpscaleFactor = 2;

/// REQ-1. Función pura: decide el upscale sólo a partir del lado más corto.
/// Sin decodificar imagen y sin depender del engine de Flutter.
/// Dimensiones cero o negativas nunca escalan.
bool shouldUpscaleForOcr(int width, int height) =>
    width > 0 &&
    height > 0 &&
    (width < kOcrMinSideForUpscale || height < kOcrMinSideForUpscale);

/// REQ-2/3/5. Función pura, sin I/O: convierte los bytes de la imagen en bytes
/// PNG escalados 2x, o devuelve `null` como centinela de "usa el archivo
/// original" (tanto si falla la decodificación como si no corresponde escalar).
Uint8List? preprocessImageForOcr(Uint8List bytes) {
  final decoded = decodeImage(bytes);
  if (decoded == null) return null;

  // REQ-3 — hornear la orientación ANTES de redimensionar, si no una entrada
  // rotada se escala de costado.
  final upright = bakeOrientation(decoded);

  if (!shouldUpscaleForOcr(upright.width, upright.height)) return null;

  // REQ-2 — el filtro por defecto de copyResize es `nearest`; se exige bicúbico.
  return encodePng(
    copyResize(
      upright,
      width: upright.width * kOcrUpscaleFactor,
      height: upright.height * kOcrUpscaleFactor,
      interpolation: Interpolation.cubic,
    ),
  );
}

abstract class OcrDataSource {
  Future<String> pickImage(ImageSourceType source);
  Future<OcrResult> recognizeText(String imagePath);
  Future<void> copyTextToClipboard(String text);
}

class OcrDataSourceImpl implements OcrDataSource {
  final ImagePicker imagePicker;
  final TextRecognizer textRecognizer;

  OcrDataSourceImpl({required this.imagePicker, required this.textRecognizer});

  @override
  Future<String> pickImage(ImageSourceType source) async {
    try {
      final ImageSource imageSource = source == ImageSourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final XFile? pickedFile = await imagePicker.pickImage(source: imageSource, imageQuality: 100);

      if (pickedFile == null) {
        return '';
      }

      return pickedFile.path;
    } catch (e) {
      throw ImagePickerFailure('Failed to pick image: ${e.toString()}');
    }
  }

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        throw const TextRecognitionFailure('No text found in image');
      }

      return OcrResultModel.fromRecognizedText(recognizedText, imagePath);
    } catch (e) {
      if (e is TextRecognitionFailure) {
        rethrow;
      }
      throw TextRecognitionFailure('Failed to recognize text: ${e.toString()}');
    }
  }

  @override
  Future<void> copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      throw TextRecognitionFailure('Failed to copy text to clipboard: ${e.toString()}');
    }
  }
}
