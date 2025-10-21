import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/data/datasources/ocr_datasource.dart';
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/domain/entities/ocr_result.dart';
import 'package:insight/features/stats/domain/repositories/ocr_repository.dart';

class OcrRepositoryImpl implements OcrRepository {
  final OcrDataSource dataSource;

  OcrRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, String>> pickImage(ImageSourceType source) async {
    try {
      final imagePath = await dataSource.pickImage(source);
      return Right(imagePath);
    } on ImagePickerFailure catch (e) {
      return Left(ImagePickerFailure(e.message));
    } catch (e) {
      return Left(ImagePickerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, OcrResult>> recognizeText(String imagePath) async {
    try {
      final result = await dataSource.recognizeText(imagePath);
      return Right(result);
    } on TextRecognitionFailure catch (e) {
      return Left(TextRecognitionFailure(e.message));
    } catch (e) {
      return Left(TextRecognitionFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> copyTextToClipboard(String text) async {
    try {
      await dataSource.copyTextToClipboard(text);
      return const Right(null);
    } on TextRecognitionFailure catch (e) {
      return Left(TextRecognitionFailure(e.message));
    } catch (e) {
      return Left(TextRecognitionFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
