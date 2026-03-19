import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/data/datasources/json_export_datasource.dart';
import 'package:insight/features/stats/data/datasources/local_storage_datasource.dart';
import 'package:insight/features/stats/data/model/stats_collection_model.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  final LocalStorageDataSource localDataSource;
  final JsonExportDataSource jsonExportDataSource;

  StatsRepositoryImpl({
    required this.localDataSource,
    required this.jsonExportDataSource,
  });

  @override
  Future<Either<Failure, void>> saveStatsCollection(
    StatsCollection collection,
  ) async {
    try {
      await localDataSource.saveStatsCollection(collection);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<StatsCollection>>>
  getAllStatsCollections() async {
    try {
      final collections = await localDataSource.getAllStatsCollections();
      return Right(collections);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StatsCollection?>> getLatestStatsCollection() async {
    try {
      final collection = await localDataSource.getLatestStatsCollection();
      return Right(collection);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStatsCollection(
    DateTime createdAt,
  ) async {
    try {
      await localDataSource.deleteStatsCollection(createdAt);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllStats() async {
    try {
      await localDataSource.clearAllStats();
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatsCollectionName(
    DateTime createdAt,
    String newName,
  ) async {
    try {
      await localDataSource.updateStatsCollectionName(createdAt, newName);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StatsCollection?>> getStatsCollectionByDate(
    DateTime createdAt,
  ) async {
    try {
      final collection = await localDataSource.getStatsCollectionByDate(
        createdAt,
      );
      return Right(collection);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Error inesperado: ${e.toString()}'));
    }
  }

  // Exportar

  @override
  Future<Either<Failure, String>> exportStatsToJson(
    List<StatsCollection> collections,
  ) async {
    try {
      if (collections.isEmpty) {
        return const Left(
          FileSystemFailure('No hay colecciones para exportar'),
        );
      }

      final exportMap = <String, dynamic>{
        'version': '1.0',
        'app': 'Insight',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'totalCollections': collections.length,
        'collections': collections
            .map((c) => StatsCollectionModel.fromEntity(c).toJson())
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);

      final now = DateTime.now();
      final fileName =
          'ml_stats_${now.year}${_pad(now.month)}${_pad(now.day)}'
          '_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}.json';

      final filePath = await jsonExportDataSource.writeJsonFile(
        fileName,
        jsonString,
      );

      return Right(filePath);
    } on FileSystemException catch (e) {
      return Left(FileSystemFailure('Error de sistema: ${e.message}'));
    } catch (e) {
      return Left(FileSystemFailure('Error al exportar: ${e.toString()}'));
    }
  }

  // Importar

  @override
  Future<Either<Failure, List<StatsCollection>>> importStatsFromJson(
    String filePath,
  ) async {
    try {
      final jsonString = await jsonExportDataSource.readJsonFile(filePath);

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Left(
          ParseFailure('El archivo no tiene el formato esperado'),
        );
      }

      final version = decoded['version'] as String?;
      if (version == null) {
        return const Left(ParseFailure('Falta el campo "version"'));
      }
      final major = int.tryParse(version.split('.').first) ?? 0;
      if (major != 1) {
        return Left(ParseFailure('Versión no compatible: $version'));
      }

      final rawList = decoded['collections'];
      if (rawList == null || rawList is! List) {
        return const Left(
          ParseFailure(
            'El campo "collections" falta o tiene formato incorrecto',
          ),
        );
      }
      if (rawList.isEmpty) {
        return const Left(ParseFailure('El archivo no contiene colecciones'));
      }

      final collections = <StatsCollection>[];
      for (int i = 0; i < rawList.length; i++) {
        try {
          final item = rawList[i];
          if (item is! Map<String, dynamic>) continue;
          collections.add(StatsCollectionModel.fromJson(item));
        } catch (_) {
          continue; // Saltar ítems corruptos sin fallar todo
        }
      }

      if (collections.isEmpty) {
        return const Left(
          ParseFailure('No se pudo parsear ninguna colección válida'),
        );
      }

      return Right(collections);
    } on FormatException catch (e) {
      return Left(ParseFailure('JSON malformado: ${e.message}'));
    } on FileSystemException catch (e) {
      return Left(FileSystemFailure('Error al leer archivo: ${e.message}'));
    } catch (e) {
      return Left(FileSystemFailure('Error al importar: ${e.toString()}'));
    }
  }

  // Batch save

  @override
  Future<Either<Failure, int>> saveCollectionsBatch(
    List<StatsCollection> collections, {
    bool replaceExisting = false,
  }) async {
    try {
      if (replaceExisting) {
        await localDataSource.clearAllStats();
      }

      final existing = replaceExisting
          ? <int>{}
          : (await localDataSource.getAllStatsCollections())
                .map((c) => c.createdAt.millisecondsSinceEpoch)
                .toSet();

      int savedCount = 0;
      for (final collection in collections) {
        final ts = collection.createdAt.millisecondsSinceEpoch;
        if (!existing.contains(ts)) {
          await localDataSource.saveStatsCollection(collection);
          existing.add(ts);
          savedCount++;
        }
      }
      return Right(savedCount);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(
        FileSystemFailure('Error en guardado batch: ${e.toString()}'),
      );
    }
  }

  // Helper privado
  String _pad(int n) => n.toString().padLeft(2, '0');
}
