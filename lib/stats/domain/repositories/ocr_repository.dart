import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/stats/domain/entities/image_source_type.dart';
import 'package:insight/stats/domain/entities/ocr_result.dart';

abstract class OcrRepository {
  Future<Either<Failure, String>> pickImage(ImageSourceType source);
  Future<Either<Failure, OcrResult>> recognizeText(String imagePath);
  Future<Either<Failure, void>> copyTextToClipboard(String text);
}
