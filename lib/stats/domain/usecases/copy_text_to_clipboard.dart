// lib/features/ocr/domain/usecases/copy_text_to_clipboard.dart
import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/stats/domain/repositories/ocr_repository.dart';
import 'package:insight/stats/domain/usecases/usecase.dart';

class CopyTextToClipboard implements UseCase<void, String> {
  final OcrRepository repository;

  CopyTextToClipboard(this.repository);

  @override
  Future<Either<Failure, void>> call(String text) async {
    if (text.isEmpty) {
      return const Left(TextRecognitionFailure('No text to copy'));
    }

    return await repository.copyTextToClipboard(text);
  }
}
