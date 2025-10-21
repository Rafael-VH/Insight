import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/features/stats/data/model/ocr_result_model.dart';
//
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/domain/entities/ocr_result.dart';

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

      final XFile? pickedFile = await imagePicker.pickImage(
        source: imageSource,
        imageQuality: 100,
      );

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
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

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
      throw TextRecognitionFailure(
        'Failed to copy text to clipboard: ${e.toString()}',
      );
    }
  }
}
