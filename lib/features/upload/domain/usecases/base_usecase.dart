import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/ocr/domain/entities/ocr_image_source.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}

// Parámetros para casos de uso
class ImageSourceParams {
  final ImageSourceType source;

  const ImageSourceParams({required this.source});
}
