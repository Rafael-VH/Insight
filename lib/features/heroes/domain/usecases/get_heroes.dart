import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/heroes/domain/entities/hero_entity.dart';
import 'package:insight/features/heroes/domain/repositories/hero_repository.dart';

class GetHeroes {
  final HeroRepository repository;
  GetHeroes(this.repository);

  Future<Either<Failure, List<HeroEntity>>> call() => repository.getHeroes();
}
