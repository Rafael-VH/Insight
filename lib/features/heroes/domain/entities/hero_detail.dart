import 'package:insight/features/heroes/domain/entities/hero_build.dart';
import 'package:insight/features/heroes/domain/entities/hero_relation.dart';
import 'package:insight/features/heroes/domain/entities/hero_skill.dart';
import 'package:insight/features/heroes/domain/entities/hero_stat.dart';

class HeroDetail {
  final int heroId;
  final String name;
  final String iconUrl;
  final String story;
  final List<String> roles;
  final List<String> specialties;
  final String lane;
  final List<HeroSkill> skills;
  final List<HeroStat> stats;
  final List<HeroBuild> builds;
  final HeroRelation? relation;

  const HeroDetail({
    required this.heroId,
    required this.name,
    required this.iconUrl,
    required this.story,
    required this.roles,
    required this.specialties,
    required this.lane,
    this.skills = const [],
    this.stats = const [],
    this.builds = const [],
    this.relation,
  });
}
