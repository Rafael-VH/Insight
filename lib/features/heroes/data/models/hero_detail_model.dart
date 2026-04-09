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

  // ── Constantes ────────────────────────────────────────────────

  static const int _maxBuilds = 3;

  static const List<String> _statLabels = [
    'Durabilidad',
    'Ofensa',
    'Habilidad',
    'Dificultad',
  ];

  // ── Factory principal ─────────────────────────────────────────

  factory HeroDetailModel.fromJson(
    int id,
    Map<String, dynamic> detailJson,
    Map<String, dynamic>? buildJson,
    Map<String, dynamic>? relationJson,
    Map<int, Map<String, dynamic>>? equipmentMap,
  ) {
    // Extraer el nodo raíz del héroe. Si la estructura no es válida
    // se retorna un modelo vacío en lugar de lanzar una excepción
    // no controlada que colapsaría toda la pantalla de detalle.
    final heroData = _extractHeroData(detailJson);
    if (heroData == null) {
      return HeroDetailModel._empty(id);
    }

    return HeroDetailModel(
      heroId: id,
      name: _parseString(heroData['name']),
      iconUrl: _parseString(heroData['head']),
      story: _parseString(heroData['story']),
      roles: _parseStringList(heroData['sortlabel']),
      specialties: _parseStringList(heroData['speciality']),
      lane: _parseLane(heroData['roadsortlabel']),
      skills: _parseSkills(heroData['heroskilllist']),
      stats: _parseStats(heroData['abilityshow']),
      builds: _parseBuilds(buildJson, equipmentMap),
      relation: _parseRelation(relationJson),
    );
  }

  // ── Extracción del nodo raíz ──────────────────────────────────

  /// Navega la estructura `data.records[0].data.hero.data` y retorna
  /// el mapa del héroe, o `null` si algún nivel está ausente.
  static Map<String, dynamic>? _extractHeroData(
    Map<String, dynamic> detailJson,
  ) {
    final records = detailJson['data']?['records'];
    if (records is! List || records.isEmpty) return null;

    final recordData = records[0];
    if (recordData is! Map<String, dynamic>) return null;

    final heroWrapper = recordData['data']?['hero'];
    if (heroWrapper is! Map<String, dynamic>) return null;

    final heroData = heroWrapper['data'];
    if (heroData is! Map<String, dynamic>) return null;

    return heroData;
  }

  // ── Parsers de campos simples ─────────────────────────────────

  static String _parseString(dynamic value) =>
      value is String ? value : '';

  /// Convierte una lista dinámica a `List<String>` descartando
  /// entradas nulas o vacías. Seguro con cualquier tipo de entrada.
  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Extrae el primer valor no vacío de `roadsortlabel`.
  static String _parseLane(dynamic value) {
    if (value is! List) return '';
    return value
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .firstOrNull ??
        '';
  }

  /// Convierte un valor dinámico a `double` de forma segura.
  /// Acepta `int`, `double` y `String` numérico.
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convierte un valor dinámico a `int` de forma segura.
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ── Parser: skills ────────────────────────────────────────────

  /// Parsea `heroskilllist` → `List<HeroSkill>`.
  ///
  /// La API retorna una lista de grupos; solo se usa el primer grupo
  /// (`skilllist`). Cada ítem puede tener la clave `skillcd&cost`
  /// (con ampersand literal) que se accede de forma segura con `[]`.
  static List<HeroSkill> _parseSkills(dynamic rawSkillList) {
    if (rawSkillList is! List || rawSkillList.isEmpty) return const [];

    final firstGroup = rawSkillList[0];
    if (firstGroup is! Map<String, dynamic>) return const [];

    final skillList = firstGroup['skilllist'];
    if (skillList is! List) return const [];

    final result = <HeroSkill>[];
    for (final item in skillList) {
      if (item is! Map<String, dynamic>) continue;

      // Eliminar etiquetas HTML del texto de descripción.
      final rawDesc = _parseString(item['skilldesc']);
      final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '');

      // La clave usa '&' literal — acceso mediante [] es seguro.
      final cooldownAndCost = _parseString(item['skillcd&cost']);

      result.add(
        HeroSkill(
          name: _parseString(item['skillname']),
          description: cleanDesc,
          iconUrl: _parseString(item['skillicon']),
          cooldownAndCost: cooldownAndCost,
        ),
      );
    }
    return result;
  }

  // ── Parser: stats ─────────────────────────────────────────────

  /// Parsea `abilityshow` → `List<HeroStat>`.
  ///
  /// Los valores llegan como enteros de 0–100.
  /// `normalizedValue` se clampea al rango [0.0, 1.0].
  static List<HeroStat> _parseStats(dynamic rawAbilityShow) {
    if (rawAbilityShow is! List) return const [];

    final result = <HeroStat>[];
    for (int i = 0; i < rawAbilityShow.length && i < _statLabels.length; i++) {
      final raw = _toInt(rawAbilityShow[i]);
      result.add(
        HeroStat(
          label: _statLabels[i],
          value: '$raw',
          normalizedValue: (raw / 100.0).clamp(0.0, 1.0),
        ),
      );
    }
    return result;
  }

  // ── Parser: builds ────────────────────────────────────────────

  /// Parsea `guide_builds.json` → `List<HeroBuild>`.
  ///
  /// Limita a [_maxBuilds] builds para no sobrecargar la UI.
  static List<HeroBuild> _parseBuilds(
    Map<String, dynamic>? buildJson,
    Map<int, Map<String, dynamic>>? equipmentMap,
  ) {
    if (buildJson == null) return const [];

    final buildRecords = buildJson['data']?['records'];
    if (buildRecords is! List || buildRecords.isEmpty) return const [];

    final buildData = buildRecords[0];
    if (buildData is! Map<String, dynamic>) return const [];

    final buildList = buildData['data']?['build'];
    if (buildList is! List) return const [];

    final result = <HeroBuild>[];

    for (final item in buildList.take(_maxBuilds)) {
      if (item is! Map<String, dynamic>) continue;

      final equipIds = _parseEquipIds(item['equipid']);
      final items = _resolveEquipment(equipIds, equipmentMap);

      result.add(
        HeroBuild(
          equipIds: equipIds,
          items: items,
          spellName: _parseSpellName(item['battleskill']),
          spellIconUrl: _parseSpellIcon(item['battleskill']),
          emblemName: _parseEmblemField(item['emblem'], 'emblemname'),
          emblemIconUrl: _parseEmblemField(item['emblem'], 'attriicon'),
          emblemAttrs: _parseEmblemAttrs(item['emblem']),
          winRate: _toDouble(item['build_win_rate']),
          pickRate: _toDouble(item['build_pick_rate']),
        ),
      );
    }
    return result;
  }

  /// Extrae la lista de IDs de equipo de `equipid`, filtrando valores
  /// inválidos (0 o negativos).
  static List<int> _parseEquipIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map<int>(_toInt)
        .where((id) => id > 0)
        .toList();
  }

  /// Resuelve los IDs de equipo contra el mapa de equipamiento descargado.
  /// Si un ID no está en el mapa se genera un placeholder con el ID visible.
  static List<HeroEquipment> _resolveEquipment(
    List<int> ids,
    Map<int, Map<String, dynamic>>? equipmentMap,
  ) {
    if (equipmentMap == null) return const [];
    return ids.map((id) {
      final data = equipmentMap[id];
      return HeroEquipment(
        equipId: id,
        name: _parseString(data?['name']),
        iconUrl: _parseString(data?['icon_url']),
        category: _parseString(data?['category']),
        price: _toInt(data?['price']),
      );
    }).toList();
  }

  /// Navega `battleskill.data.__data.skillname` de forma segura.
  static String _parseSpellName(dynamic battleskill) =>
      _parseString(
        _safeMap(battleskill)?['data']?['__data']?['skillname'],
      );

  /// Navega `battleskill.data.__data.skillicon` de forma segura.
  static String _parseSpellIcon(dynamic battleskill) =>
      _parseString(
        _safeMap(battleskill)?['data']?['__data']?['skillicon'],
      );

  /// Extrae un campo simple del nodo `emblem.data`.
  static String _parseEmblemField(dynamic emblem, String key) =>
      _parseString(_safeMap(_safeMap(emblem)?['data'])?[key]);

  /// Parsea los atributos del emblema.
  ///
  /// La API puede retornar `emblemattr` como:
  /// - `String` con el texto directo
  /// - `Map<String, dynamic>` con clave interna `emblemattr`
  /// - `List` de strings
  ///
  /// Los tres casos se normalizan a una sola cadena.
  static String _parseEmblemAttrs(dynamic emblem) {
    final emblemData = _safeMap(_safeMap(emblem)?['data']);
    if (emblemData == null) return '';

    final raw = emblemData['emblemattr'];

    if (raw is String) return raw;

    if (raw is Map<String, dynamic>) {
      final inner = raw['emblemattr'];
      if (inner is String) return inner;
    }

    if (raw is List) {
      return raw.whereType<String>().join('\n');
    }

    return '';
  }

  // ── Parser: relation ──────────────────────────────────────────

  /// Parsea `hero_list.json` relation node → `HeroRelation`.
  static HeroRelation? _parseRelation(Map<String, dynamic>? relationJson) {
    if (relationJson == null) return null;

    final rel = relationJson['data']?['relation'];
    if (rel is! Map<String, dynamic>) return null;

    return HeroRelation(
      strongAgainst: _parseHeroIds(rel['strong']),
      weakAgainst: _parseHeroIds(rel['weak']),
      bestWith: _parseHeroIds(rel['assist']),
    );
  }

  /// Extrae `target_hero_id` de un nodo de relación,
  /// filtrando IDs inválidos (≤ 0).
  static List<int> _parseHeroIds(dynamic node) {
    if (node is! Map<String, dynamic>) return const [];
    final ids = node['target_hero_id'];
    if (ids is! List) return const [];
    return ids.map<int>(_toInt).where((id) => id > 0).toList();
  }

  // ── Helpers internos ──────────────────────────────────────────

  /// Castea [value] a `Map<String, dynamic>` de forma segura.
  /// Retorna `null` si el valor no es del tipo esperado.
  static Map<String, dynamic>? _safeMap(dynamic value) =>
      value is Map<String, dynamic> ? value : null;

  // ── Factory vacío ─────────────────────────────────────────────

  /// Modelo vacío para cuando la estructura JSON no es válida.
  ///
  /// Retornar un modelo con `name` vacío en lugar de lanzar
  /// una excepción permite que el repositorio decida si exponer
  /// un `Left(Failure)` o ignorarlo. El repositorio actual ya
  /// tiene esta lógica con el guard `if (detailEntry == null)`.
  factory HeroDetailModel._empty(int id) => HeroDetailModel(
    heroId: id,
    name: '',
    iconUrl: '',
    story: '',
    roles: const [],
    specialties: const [],
    lane: '',
    skills: const [],
    stats: const [],
    builds: const [],
    relation: null,
  );
}
