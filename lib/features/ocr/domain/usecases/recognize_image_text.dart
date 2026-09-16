import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/core/usecases/base_usecase.dart';
import 'package:insight/features/ocr/domain/entities/ocr_result.dart';
import 'package:insight/features/ocr/domain/repositories/ocr_repository.dart';

class RecognizeImageText implements UseCase<OcrResult, ImageSourceParams> {
  final OcrRepository repository;

  RecognizeImageText(this.repository);

  @override
  Future<Either<Failure, OcrResult>> call(ImageSourceParams params) async {
    final imageResult = await repository.pickImage(params.source);

    return imageResult.fold((failure) => Left(failure), (imagePath) async {
      if (imagePath.isEmpty) {
        return const Left(ImagePickerFailure('No image selected'));
      }

      return await repository.recognizeText(imagePath);
    });
  }
}
