import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/core/usecases/base_usecase.dart';
import 'package:insight/features/ocr/domain/repositories/ocr_repository.dart';

class CopyToClipboard implements UseCase<void, String> {
  final OcrRepository repository;

  CopyToClipboard(this.repository);

  @override
  Future<Either<Failure, void>> call(String text) async {
    if (text.isEmpty) {
      return const Left(TextRecognitionFailure('No text to copy'));
    }

    return await repository.copyTextToClipboard(text);
  }
}
