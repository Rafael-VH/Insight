import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/stats/domain/entities/ocr_result.dart';
//
import 'package:insight/stats/domain/repositories/ocr_repository.dart';
//
import 'package:insight/stats/domain/usecases/usecase.dart';

class PickImageAndRecognizeText
    implements UseCase<OcrResult, ImageSourceParams> {
  final OcrRepository repository;

  PickImageAndRecognizeText(this.repository);

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
