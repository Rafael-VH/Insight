import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';

class HeroModel extends MlbbHero {
  const HeroModel({required super.heroId, required super.name, required super.iconUrl});

  factory HeroModel.fromJson(int id, Map<String, dynamic> json) {
    return HeroModel(heroId: id, name: json['name'] as String, iconUrl: json['icon_url'] as String);
  }
}
