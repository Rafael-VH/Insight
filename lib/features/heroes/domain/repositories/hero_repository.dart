import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/heroes/domain/entities/hero_entity.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';

abstract class HeroRepository {
  Future<Either<Failure, List<HeroEntity>>> getHeroes();
  Future<Either<Failure, HeroDetail>> getHeroDetail(int heroId);
}
