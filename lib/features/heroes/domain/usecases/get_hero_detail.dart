import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/repositories/hero_repository.dart';

class GetHeroDetail {
  final HeroRepository repository;
  GetHeroDetail(this.repository);

  Future<Either<Failure, HeroDetail>> call(int heroId) => repository.getHeroDetail(heroId);
}
