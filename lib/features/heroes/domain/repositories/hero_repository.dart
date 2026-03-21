import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';

abstract class HeroRepository {
  Future<Either<Failure, List<MlbbHero>>> getHeroes();
  Future<Either<Failure, HeroDetail>> getHeroDetail(int heroId);
}
