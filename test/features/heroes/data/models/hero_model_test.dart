import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/heroes/data/models/hero_detail_model.dart';
import 'package:insight/features/heroes/data/models/hero_model.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';

// ── Helpers: construcción de JSON de prueba ──────────────────────

Map<String, dynamic> _buildHeroDetailJson({
  String name = 'Layla',
  String head = 'https://example.com/layla.png',
  String story = 'Una chica con una pistola futurista.',
  List<String> sortlabel = const ['Marksman'],
  List<String> speciality = const ['Reap'],
  List<String> roadsortlabel = const ['Gold Lane'],
  List<dynamic> abilityshow = const [90, 80, 30, 20],
  List<dynamic> heroskilllist = const [],
}) {
  return {
    'data': {
      'records': [
        {
          'data': {
            'hero': {
              'data': {
                'name': name,
                'head': head,
                'story': story,
                'sortlabel': sortlabel,
                'speciality': speciality,
                'roadsortlabel': roadsortlabel,
                'abilityshow': abilityshow,
                'heroskilllist': heroskilllist,
              },
            },
          },
        },
      ],
    },
  };
}

Map<String, dynamic> _buildSkillEntry({
  String skillname = 'Energy Cannon',
  String skilldesc = 'Dispara un rayo de energía a los enemigos.',
  String skillicon = 'https://example.com/skill.png',
  String cooldown = '0/0s',
}) {
  return {
    'skillname': skillname,
    'skilldesc': skilldesc,
    'skillicon': skillicon,
    'skillcd&cost': cooldown,
  };
}

void main() {
  // ================================================================
  // HeroModel
  // ================================================================

  group('HeroModel', () {
    group('fromJson', () {
      test('parsea correctamente los campos básicos', () {
        final json = {
          'name': 'Layla',
          'icon_url': 'https://example.com/layla.png',
        };
        final model = HeroModel.fromJson(1, json);
        expect(model.heroId, equals(1));
        expect(model.name, equals('Layla'));
        expect(model.iconUrl, equals('https://example.com/layla.png'));
      });

      test('es una instancia de MlbbHero', () {
        final model = HeroModel.fromJson(
            2, {'name': 'Miya', 'icon_url': 'https://example.com/miya.png'});
        expect(model, isA<MlbbHero>());
      });
    });
  });

  // ================================================================
  // HeroDetailModel
  // ================================================================

  group('HeroDetailModel', () {
    // ── fromJson: estructura válida ──────────────────────────────

    group('fromJson - estructura válida', () {
      test('parsea heroId, name, iconUrl e historia', () {
        final json = _buildHeroDetailJson(
          name: 'Layla',
          head: 'https://example.com/layla.png',
          story: 'Una chica valiente.',
        );
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.heroId, equals(1));
        expect(model.name, equals('Layla'));
        expect(model.iconUrl, equals('https://example.com/layla.png'));
        expect(model.story, equals('Una chica valiente.'));
      });

      test('parsea roles correctamente', () {
        final json =
            _buildHeroDetailJson(sortlabel: ['Marksman', 'Support']);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.roles, equals(['Marksman', 'Support']));
      });

      test('parsea specialties correctamente', () {
        final json = _buildHeroDetailJson(speciality: ['Reap', 'Chase']);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.specialties, equals(['Reap', 'Chase']));
      });

      test('parsea lane desde roadsortlabel', () {
        final json =
            _buildHeroDetailJson(roadsortlabel: ['Gold Lane', 'Mid Lane']);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.lane, equals('Gold Lane'));
      });

      test('lane vacío cuando roadsortlabel es lista vacía', () {
        final json = _buildHeroDetailJson(roadsortlabel: []);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.lane, equals(''));
      });
    });

    // ── fromJson: stats (abilityshow) ────────────────────────────

    group('fromJson - stats', () {
      test('parsea 4 stats con normalizedValue correcto', () {
        final json =
            _buildHeroDetailJson(abilityshow: [90, 80, 30, 20]);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.stats.length, equals(4));
        expect(model.stats[0].normalizedValue, closeTo(0.9, 0.01));
        expect(model.stats[1].normalizedValue, closeTo(0.8, 0.01));
      });

      test('normalizedValue se clampea a 1.0 para valores > 100', () {
        final json = _buildHeroDetailJson(abilityshow: [150]);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.stats[0].normalizedValue, equals(1.0));
      });

      test('normalizedValue se clampea a 0.0 para valores negativos', () {
        final json = _buildHeroDetailJson(abilityshow: [-10]);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.stats[0].normalizedValue, equals(0.0));
      });

      test('stats vacíos cuando abilityshow es vacío', () {
        final json = _buildHeroDetailJson(abilityshow: []);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.stats, isEmpty);
      });

      test('labels correctos para los 4 stats', () {
        final json =
            _buildHeroDetailJson(abilityshow: [90, 80, 30, 20]);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.stats[0].label, equals('Durabilidad'));
        expect(model.stats[1].label, equals('Ofensa'));
        expect(model.stats[2].label, equals('Habilidad'));
        expect(model.stats[3].label, equals('Dificultad'));
      });
    });

    // ── fromJson: skills ─────────────────────────────────────────

    group('fromJson - skills', () {
      test('parsea una habilidad con sus campos', () {
        final skill = _buildSkillEntry(
          skillname: 'Energy Cannon',
          skilldesc: 'Dispara un rayo.',
          skillicon: 'https://example.com/s1.png',
          cooldown: '0s',
        );
        final json = _buildHeroDetailJson(
          heroskilllist: [
            {
              'skilllist': [skill],
            },
          ],
        );
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.skills.length, equals(1));
        expect(model.skills[0].name, equals('Energy Cannon'));
        expect(model.skills[0].iconUrl, equals('https://example.com/s1.png'));
      });

      test('elimina tags HTML de la descripción de la habilidad', () {
        final skill = _buildSkillEntry(
          skilldesc: '<color=red>Daño</color> de energía.',
        );
        final json = _buildHeroDetailJson(
          heroskilllist: [
            {
              'skilllist': [skill],
            },
          ],
        );
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.skills[0].description, equals('Daño de energía.'));
        expect(model.skills[0].description, isNot(contains('<')));
      });

      test('skills vacíos cuando heroskilllist es vacío', () {
        final json = _buildHeroDetailJson(heroskilllist: []);
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.skills, isEmpty);
      });
    });

    // ── fromJson: estructura inválida ────────────────────────────

    group('fromJson - estructura inválida', () {
      test('retorna modelo vacío cuando falta el nodo data.records', () {
        final json = {'data': {}};
        final model = HeroDetailModel.fromJson(99, json, null, null, null);
        expect(model.heroId, equals(99));
        expect(model.name, equals(''));
        expect(model.roles, isEmpty);
        expect(model.skills, isEmpty);
        expect(model.stats, isEmpty);
      });

      test('retorna modelo vacío cuando records es lista vacía', () {
        final json = {
          'data': {'records': []},
        };
        final model = HeroDetailModel.fromJson(99, json, null, null, null);
        expect(model.name, equals(''));
      });

      test('retorna modelo vacío cuando el JSON es completamente vacío', () {
        final model = HeroDetailModel.fromJson(1, {}, null, null, null);
        expect(model.name, equals(''));
        expect(model.builds, isEmpty);
        expect(model.relation, isNull);
      });
    });

    // ── fromJson: builds ─────────────────────────────────────────

    group('fromJson - builds', () {
      test('retorna builds vacíos cuando buildJson es null', () {
        final json = _buildHeroDetailJson();
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.builds, isEmpty);
      });

      test('parsea un build con equipIds y tasas de win/pick', () {
        final buildJson = {
          'data': {
            'records': [
              {
                'data': {
                  'build': [
                    {
                      'equipid': [1, 2, 3, 4, 5, 6],
                      'battleskill': null,
                      'emblem': null,
                      'build_win_rate': 0.58,
                      'build_pick_rate': 0.12,
                    }
                  ],
                },
              },
            ],
          },
        };
        final json = _buildHeroDetailJson();
        final model =
            HeroDetailModel.fromJson(1, json, buildJson, null, null);
        expect(model.builds.length, equals(1));
        expect(model.builds[0].equipIds.length, equals(6));
        expect(model.builds[0].winRate, closeTo(0.58, 0.001));
        expect(model.builds[0].pickRate, closeTo(0.12, 0.001));
      });

      test('limita builds a máximo 3', () {
        final buildList = List.generate(
          5,
          (i) => {
            'equipid': [1],
            'battleskill': null,
            'emblem': null,
            'build_win_rate': 0.5,
            'build_pick_rate': 0.1,
          },
        );
        final buildJson = {
          'data': {
            'records': [
              {
                'data': {'build': buildList},
              },
            ],
          },
        };
        final json = _buildHeroDetailJson();
        final model =
            HeroDetailModel.fromJson(1, json, buildJson, null, null);
        expect(model.builds.length, lessThanOrEqualTo(3));
      });
    });

    // ── fromJson: relation ───────────────────────────────────────

    group('fromJson - relation', () {
      test('retorna null cuando relationJson es null', () {
        final json = _buildHeroDetailJson();
        final model = HeroDetailModel.fromJson(1, json, null, null, null);
        expect(model.relation, isNull);
      });

      test('parsea lista de strongAgainst', () {
        final relationJson = {
          'data': {
            'relation': {
              'strong': {
                'target_hero_id': [2, 3, 4],
              },
              'weak': {
                'target_hero_id': [],
              },
              'assist': {
                'target_hero_id': [],
              },
            },
          },
        };
        final json = _buildHeroDetailJson();
        final model =
            HeroDetailModel.fromJson(1, json, null, relationJson, null);
        expect(model.relation, isNotNull);
        expect(model.relation!.strongAgainst, equals([2, 3, 4]));
      });

      test('filtra IDs ≤ 0 en la relación', () {
        final relationJson = {
          'data': {
            'relation': {
              'strong': {
                'target_hero_id': [0, -1, 5, 6],
              },
              'weak': {'target_hero_id': []},
              'assist': {'target_hero_id': []},
            },
          },
        };
        final json = _buildHeroDetailJson();
        final model =
            HeroDetailModel.fromJson(1, json, null, relationJson, null);
        expect(model.relation!.strongAgainst, equals([5, 6]));
      });
    });
  });
}