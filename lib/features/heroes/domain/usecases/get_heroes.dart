import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/repositories/hero_repository.dart';

class GetHeroes {
  final HeroRepository repository;
  GetHeroes(this.repository);

  Future<Either<Failure, List<MlbbHero>>> call() => repository.getHeroes();
}
