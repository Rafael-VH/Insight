import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/ocr/domain/entities/ocr_image_source.dart';
import 'package:insight/features/ocr/domain/entities/ocr_result.dart';

abstract class OcrRepository {
  Future<Either<Failure, String>> pickImage(ImageSourceType source);
  Future<Either<Failure, OcrResult>> recognizeText(String imagePath);
  Future<Either<Failure, void>> copyTextToClipboard(String text);
}
