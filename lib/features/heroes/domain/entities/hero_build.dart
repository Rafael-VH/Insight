import 'package:insight/features/heroes/domain/entities/hero_equipment.dart';

class HeroBuild {
  final List<HeroEquipment> items;
  final List<int> equipIds;
  final String spellName;
  final String spellIconUrl;
  final String emblemName;
  final String emblemIconUrl;
  final String emblemAttrs;
  final double winRate;
  final double pickRate;

  const HeroBuild({
    this.items = const [],
    required this.equipIds,
    required this.spellName,
    required this.spellIconUrl,
    required this.emblemName,
    required this.emblemIconUrl,
    this.emblemAttrs = '',
    required this.winRate,
    required this.pickRate,
  });
}
