import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:insight/core/errors/failures.dart';

const _base = 'https://raw.githubusercontent.com/Rafael-VH/MLBB-Data/main';

abstract class HeroRemoteDataSource {
  Future<Map<String, dynamic>> fetchHeroIndex();
  Future<Map<String, dynamic>> fetchHeroDetails();
  Future<Map<String, dynamic>> fetchHeroList();
  Future<Map<String, dynamic>> fetchGuideBuilds();
  Future<Map<String, dynamic>> fetchEquipment(); // nuevo
}

class HeroRemoteDataSourceImpl implements HeroRemoteDataSource {
  final http.Client client;
  HeroRemoteDataSourceImpl({required this.client});

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await client.get(Uri.parse('$_base/$path'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw FileSystemFailure('Error al cargar $path (${response.statusCode})');
  }

  @override
  Future<Map<String, dynamic>> fetchHeroIndex() => _get('heroes/hero_index.json');

  @override
  Future<Map<String, dynamic>> fetchHeroDetails() => _get('heroes/hero_details.json');

  @override
  Future<Map<String, dynamic>> fetchHeroList() => _get('heroes/hero_list.json');

  @override
  Future<Map<String, dynamic>> fetchGuideBuilds() => _get('guides/guide_builds.json');

  @override
  Future<Map<String, dynamic>> fetchEquipment() => _get('academy/academy_equipment.json');
}
