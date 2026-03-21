import 'package:insight/features/heroes/domain/entities/hero_build.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/entities/hero_equipment.dart';
import 'package:insight/features/heroes/domain/entities/hero_relation.dart';
import 'package:insight/features/heroes/domain/entities/hero_skill.dart';
import 'package:insight/features/heroes/domain/entities/hero_stat.dart';

class HeroDetailModel extends HeroDetail {
  const HeroDetailModel({
    required super.heroId,
    required super.name,
    required super.iconUrl,
    required super.story,
    required super.roles,
    required super.specialties,
    required super.lane,
    super.skills,
    super.stats,
    super.builds,
    super.relation,
  });

  factory HeroDetailModel.fromJson(
    int id,
    Map<String, dynamic> detailJson,
    Map<String, dynamic>? buildJson,
    Map<String, dynamic>? relationJson,
    Map<int, Map<String, dynamic>>? equipmentMap,
  ) {
    // ── hero_details ─────────────────────────────────────────
    final records = detailJson['data']?['records'] as List?;
    if (records == null || records.isEmpty) {
      return HeroDetailModel._empty(id);
    }

    final recordData = records[0]['data'] as Map<String, dynamic>?;
    if (recordData == null) return HeroDetailModel._empty(id);

    final heroData = recordData['hero']?['data'] as Map<String, dynamic>?;
    if (heroData == null) return HeroDetailModel._empty(id);

    final name = heroData['name'] as String? ?? '';
    final iconUrl = heroData['head'] as String? ?? '';
    final story = heroData['story'] as String? ?? '';

    // Roles
    final sortlabel = heroData['sortlabel'] as List?;
    final roles =
        sortlabel
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Especialidades
    final speciality = heroData['speciality'] as List?;
    final specialties =
        speciality
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Lane
    final roadsortlabel = heroData['roadsortlabel'] as List?;
    final lane =
        roadsortlabel
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .firstOrNull ??
        '';

    // ── Skills ───────────────────────────────────────────────
    final skills = <HeroSkill>[];
    final skillListRaw = heroData['heroskilllist'] as List?;
    if (skillListRaw != null && skillListRaw.isNotEmpty) {
      final firstGroup = skillListRaw[0]['skilllist'] as List?;
      if (firstGroup != null) {
        for (final s in firstGroup) {
          final sm = s as Map<String, dynamic>;
          final cleanDesc = (sm['skilldesc'] as String? ?? '').replaceAll(
            RegExp(r'<[^>]*>'),
            '',
          );
          skills.add(
            HeroSkill(
              name: sm['skillname'] as String? ?? '',
              description: cleanDesc,
              iconUrl: sm['skillicon'] as String? ?? '',
              cooldownAndCost: sm['skillcd&cost'] as String? ?? '',
            ),
          );
        }
      }
    }

    // ── Stats (abilityshow) ───────────────────────────────────
    const statLabels = ['Durabilidad', 'Ofensa', 'Habilidad', 'Dificultad'];
    final stats = <HeroStat>[];
    final abilityshow = heroData['abilityshow'] as List?;
    if (abilityshow != null) {
      for (int i = 0; i < abilityshow.length && i < statLabels.length; i++) {
        final raw = int.tryParse(abilityshow[i].toString()) ?? 0;
        stats.add(
          HeroStat(
            label: statLabels[i],
            value: '$raw',
            normalizedValue: (raw / 100).clamp(0.0, 1.0),
          ),
        );
      }
    }

    // ── Builds ────────────────────────────────────────────────
    final builds = <HeroBuild>[];
    if (buildJson != null) {
      final buildRecords = buildJson['data']?['records'] as List?;
      if (buildRecords != null && buildRecords.isNotEmpty) {
        final buildData = buildRecords[0]['data'] as Map<String, dynamic>?;
        final buildList = buildData?['build'] as List?;

        if (buildList != null) {
          for (final b in buildList.take(3)) {
            final bm = b as Map<String, dynamic>;

            // IDs de ítems
            final equipRaw = bm['equipid'] as List?;
            final equipIds =
                equipRaw
                    ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                    .where((e) => e > 0)
                    .toList() ??
                [];

            // Resolver ítems desde equipmentMap
            final items = equipIds.map((eid) {
              final eData = equipmentMap?[eid];
              return HeroEquipment(
                equipId: eid,
                name: eData?['name'] as String? ?? 'Item $eid',
                iconUrl: eData?['icon_url'] as String? ?? '',
                category: eData?['category'] as String? ?? '',
                price: (eData?['price'] as num?)?.toInt() ?? 0,
              );
            }).toList();

            // Hechizo
            final spellData =
                bm['battleskill']?['data']?['__data'] as Map<String, dynamic>?;
            final spellName = spellData?['skillname'] as String? ?? '';
            final spellIcon = spellData?['skillicon'] as String? ?? '';

            // Emblema
            final emblemData = bm['emblem']?['data'] as Map<String, dynamic>?;
            final emblemName = emblemData?['emblemname'] as String? ?? '';
            final emblemIcon = emblemData?['attriicon'] as String? ?? '';
            final emblemAttrMap =
                emblemData?['emblemattr'] as Map<String, dynamic>?;
            final emblemAttrs = emblemAttrMap?['emblemattr'] as String? ?? '';

            builds.add(
              HeroBuild(
                items: items,
                equipIds: List<int>.from(equipIds),
                spellName: spellName,
                spellIconUrl: spellIcon,
                emblemName: emblemName,
                emblemIconUrl: emblemIcon,
                emblemAttrs: emblemAttrs,
                winRate: (bm['build_win_rate'] as num?)?.toDouble() ?? 0.0,
                pickRate: (bm['build_pick_rate'] as num?)?.toDouble() ?? 0.0,
              ),
            );
          }
        }
      }
    }

    // ── Relation ──────────────────────────────────────────────
    HeroRelation? relation;
    if (relationJson != null) {
      final rel = relationJson['data']?['relation'] as Map<String, dynamic>?;
      if (rel != null) {
        List<int> parseIds(dynamic node) {
          final ids = node?['target_hero_id'] as List?;
          return ids
                  ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                  .where((e) => e > 0)
                  .toList() ??
              [];
        }

        relation = HeroRelation(
          strongAgainst: parseIds(rel['strong']),
          weakAgainst: parseIds(rel['weak']),
          bestWith: parseIds(rel['assist']),
        );
      }
    }

    return HeroDetailModel(
      heroId: id,
      name: name,
      iconUrl: iconUrl,
      story: story,
      roles: List<String>.from(roles),
      specialties: List<String>.from(specialties),
      lane: lane,
      skills: skills,
      stats: stats,
      builds: builds,
      relation: relation,
    );
  }

  factory HeroDetailModel._empty(int id) => HeroDetailModel(
    heroId: id,
    name: '',
    iconUrl: '',
    story: '',
    roles: const [],
    specialties: const [],
    lane: '',
  );
}
