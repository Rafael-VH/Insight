import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/features/stats/domain/entities/image_source_type.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}

// Parámetros para casos de uso
class ImageSourceParams {
  final ImageSourceType source;

  const ImageSourceParams({required this.source});
}
