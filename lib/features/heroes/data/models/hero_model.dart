import 'package:insight/features/heroes/domain/entities/hero_entity.dart';

class HeroModel extends HeroEntity {
  const HeroModel({required super.heroId, required super.name, required super.iconUrl});

  factory HeroModel.fromJson(int id, Map<String, dynamic> json) {
    return HeroModel(heroId: id, name: json['name'] as String, iconUrl: json['icon_url'] as String);
  }
}
