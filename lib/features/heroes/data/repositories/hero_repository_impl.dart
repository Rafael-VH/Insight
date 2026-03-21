import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/heroes/data/datasources/hero_cache_datasource.dart';
import 'package:insight/features/heroes/data/datasources/hero_remote_datasource.dart';
import 'package:insight/features/heroes/data/models/hero_detail_model.dart';
import 'package:insight/features/heroes/data/models/hero_model.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/repositories/hero_repository.dart';

class HeroRepositoryImpl implements HeroRepository {
  final HeroRemoteDataSource remote;
  final HeroCacheDataSource cache;

  List<MlbbHero>? _heroesMemory;
  Map<String, dynamic>? _detailsMemory;
  Map<int, Map<String, dynamic>>? _relationsMemory;
  Map<String, dynamic>? _buildsMemory;
  Map<int, Map<String, dynamic>>? _equipmentMemory;

  HeroRepositoryImpl({required this.remote, required this.cache});

  // ── Precarga eager ────────────────────────────────────────
  Future<Either<Failure, void>> preloadData() async {
    try {
      if (cache.isCacheValid()) {
        final ci = await cache.getCachedIndex();
        final cd = await cache.getCachedDetails();
        final cl = await cache.getCachedList();
        if (ci != null && cd != null && cl != null) {
          _detailsMemory = json.decode(cd);
          _relationsMemory = _buildRelationsMap(json.decode(cl));
          _heroesMemory = _parseHeroIndex(json.decode(ci));
          return const Right(null);
        }
      }

      // Descargar index y details (obligatorios)
      final indexData = await remote.fetchHeroIndex();
      final detailsData = await remote.fetchHeroDetails();

      // hero_list opcional (para relaciones)
      Map<String, dynamic>? listData;
      try {
        listData = await remote.fetchHeroList();
      } catch (_) {
        listData = null;
      }

      await cache.saveEagerCache(
        indexJson: json.encode(indexData),
        detailsJson: json.encode(detailsData),
        listJson: json.encode(listData ?? {}),
      );

      _heroesMemory = _parseHeroIndex(indexData);
      _detailsMemory = detailsData;
      if (listData != null) {
        _relationsMemory = _buildRelationsMap(listData);
      }

      return const Right(null);
    } catch (e) {
      // Fallback a caché expirada
      try {
        final ci = await cache.getCachedIndex();
        final cd = await cache.getCachedDetails();
        final cl = await cache.getCachedList();
        if (ci != null && cd != null) {
          _detailsMemory = json.decode(cd);
          if (cl != null && cl.isNotEmpty) {
            _relationsMemory = _buildRelationsMap(json.decode(cl));
          }
          _heroesMemory = _parseHeroIndex(json.decode(ci));
          return const Right(null);
        }
      } catch (_) {}
      return Left(FileSystemFailure('Sin conexión y sin caché disponible'));
    }
  }

  // ── Precarga lazy: builds + equipment en paralelo ─────────
  Future<void> _ensureBuildsAndEquipmentLoaded() async {
    final needsBuilds = _buildsMemory == null;
    final needsEquipment = _equipmentMemory == null;
    if (!needsBuilds && !needsEquipment) return;

    // Intentar desde caché primero
    if (needsBuilds && cache.isBuildsValid()) {
      final cb = await cache.getCachedBuilds();
      if (cb != null) {
        try {
          _buildsMemory = json.decode(cb);
        } catch (_) {}
      }
    }
    if (needsEquipment && cache.isEquipmentValid()) {
      final ce = await cache.getCachedEquipment();
      if (ce != null) {
        try {
          _equipmentMemory = _parseEquipmentMap(json.decode(ce));
        } catch (_) {}
      }
    }

    // Descargar lo que aún falte en paralelo
    final futures = <Future>[];

    if (_buildsMemory == null) {
      futures.add(
        remote
            .fetchGuideBuilds()
            .then((data) async {
              await cache.saveBuildsCache(json.encode(data));
              _buildsMemory = data;
            })
            .catchError((_) async {
              final cb = await cache.getCachedBuilds();
              if (cb != null) {
                try {
                  _buildsMemory = json.decode(cb);
                } catch (_) {}
              }
            }),
      );
    }

    if (_equipmentMemory == null) {
      futures.add(
        remote
            .fetchEquipment()
            .then((data) async {
              await cache.saveEquipmentCache(json.encode(data));
              _equipmentMemory = _parseEquipmentMap(data);
            })
            .catchError((_) async {
              final ce = await cache.getCachedEquipment();
              if (ce != null) {
                try {
                  _equipmentMemory = _parseEquipmentMap(json.decode(ce));
                } catch (_) {}
              }
            }),
      );
    }

    if (futures.isNotEmpty) await Future.wait(futures);
  }

  @override
  Future<Either<Failure, List<MlbbHero>>> getHeroes() async {
    if (_heroesMemory != null) return Right(_heroesMemory!);
    final preload = await preloadData();
    return preload.fold((f) => Left(f), (_) => Right(_heroesMemory ?? []));
  }

  @override
  Future<Either<Failure, HeroDetail>> getHeroDetail(int heroId) async {
    if (_detailsMemory == null) {
      final preload = await preloadData();
      if (preload.isLeft()) {
        return Left(FileSystemFailure('No se pudieron cargar los datos'));
      }
    }

    // Carga lazy de builds y equipment
    await _ensureBuildsAndEquipmentLoaded();

    final detailEntry = _detailsMemory?[heroId.toString()];
    if (detailEntry == null) {
      return Left(FileSystemFailure('Héroe $heroId no encontrado'));
    }

    final relationEntry = _relationsMemory?[heroId];
    final buildEntry = _buildsMemory?[heroId.toString()];

    return Right(
      HeroDetailModel.fromJson(
        heroId,
        detailEntry as Map<String, dynamic>,
        buildEntry as Map<String, dynamic>?,
        relationEntry,
        _equipmentMemory,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Map<int, Map<String, dynamic>> _buildRelationsMap(
    Map<String, dynamic> listJson,
  ) {
    final result = <int, Map<String, dynamic>>{};
    final records = listJson['data']?['records'] as List?;
    if (records == null) return result;

    for (final record in records) {
      final recordMap = record as Map<String, dynamic>?;
      if (recordMap == null) continue;
      final heroId = recordMap['data']?['hero_id'] as int?;
      if (heroId != null) {
        result[heroId] = recordMap;
      }
    }
    return result;
  }

  Map<int, Map<String, dynamic>> _parseEquipmentMap(Map<String, dynamic> data) {
    final result = <int, Map<String, dynamic>>{};
    final raw = data['data'] ?? data;

    if (raw is List) {
      for (final item in raw) {
        final m = item as Map<String, dynamic>?;
        if (m == null) continue;
        final id =
            m['equipment_id'] as int? ??
            int.tryParse(m['id']?.toString() ?? '') ??
            0;
        if (id > 0) result[id] = m;
      }
    } else if (raw is Map) {
      raw.forEach((key, value) {
        final id = int.tryParse(key.toString()) ?? 0;
        if (id > 0 && value is Map<String, dynamic>) {
          result[id] = value;
        }
      });
    }
    return result;
  }

  List<MlbbHero> _parseHeroIndex(Map<String, dynamic> data) {
    return data.entries.map((e) {
      final id = int.tryParse(e.key) ?? 0;
      return HeroModel.fromJson(id, e.value as Map<String, dynamic>);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
