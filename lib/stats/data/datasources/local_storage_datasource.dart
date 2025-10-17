import 'dart:convert';

import 'package:insight/core/errors/failures.dart';
import 'package:insight/stats/data/model/stats_collection_model.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageDataSource {
  Future<void> saveStatsCollection(StatsCollection collection);
  Future<List<StatsCollection>> getAllStatsCollections();
  Future<StatsCollection?> getLatestStatsCollection();
  Future<void> deleteStatsCollection(DateTime createdAt);
  Future<void> clearAllStats();
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _collectionsKey = 'stats_collections';
  final SharedPreferences sharedPreferences;

  LocalStorageDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveStatsCollection(StatsCollection collection) async {
    try {
      // MEJORADO: Obtener colecciones existentes primero
      List<StatsCollection> collections = [];
      try {
        collections = await getAllStatsCollections();
      } catch (e) {
        // Si hay error al obtener, comenzar con lista vacía
        print('Advertencia: Error al obtener colecciones previas: $e');
        collections = [];
      }

      // VALIDACIÓN: Evitar colecciones duplicadas
      // Buscar si ya existe una colección con la misma fecha (misma sesión)
      final duplicateIndex = collections.indexWhere(
        (c) => c.createdAt.difference(collection.createdAt).inMinutes < 1,
      );

      if (duplicateIndex != -1) {
        // Reemplazar la existente en lugar de agregar duplicada
        collections[duplicateIndex] = collection;
      } else {
        // Agregar la nueva colección
        collections.add(collection);
      }

      // CONVERSIÓN: A modelo y JSON
      final jsonList = collections.map((c) {
        final model = StatsCollectionModel(
          totalStats: c.totalStats,
          rankedStats: c.rankedStats,
          classicStats: c.classicStats,
          brawlStats: c.brawlStats,
          createdAt: c.createdAt,
        );
        return model.toJson();
      }).toList();

      final jsonString = json.encode(jsonList);

      // GUARDADO: Con validación
      final success = await sharedPreferences.setString(
        _collectionsKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to save stats collection');
      }
    } catch (e) {
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error saving stats: ${e.toString()}');
    }
  }

  @override
  Future<List<StatsCollection>> getAllStatsCollections() async {
    try {
      final jsonString = sharedPreferences.getString(_collectionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      dynamic decoded;
      try {
        decoded = json.decode(jsonString);
      } catch (e) {
        print('❌ JSON inválido: $e');
        // Limpiar datos corruptos
        await sharedPreferences.remove(_collectionsKey);
        return [];
      }

      // Validar que sea una lista
      if (decoded is! List) {
        print(
          '❌ Formato inválido: esperaba List, recibió ${decoded.runtimeType}',
        );
        await sharedPreferences.remove(_collectionsKey);
        return [];
      }

      final collections = <StatsCollection>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          print('⚠️ Item inválido saltado: $item');
          continue;
        }

        try {
          final collection = StatsCollectionModel.fromJson(item);
          collections.add(collection);
        } catch (e) {
          print('⚠️ Error al convertir colección: $e');
          continue;
        }
      }

      collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return collections;
    } catch (e) {
      throw FileSystemFailure('Error loading stats: ${e.toString()}');
    }
  }

  @override
  Future<StatsCollection?> getLatestStatsCollection() async {
    try {
      final collections = await getAllStatsCollections();

      if (collections.isEmpty) {
        return null;
      }

      return collections.first;
    } catch (e) {
      throw FileSystemFailure('Error loading latest stats: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteStatsCollection(DateTime createdAt) async {
    try {
      final collections = await getAllStatsCollections();

      // ✅ BÚSQUEDA: Usando comparación de milisegundos
      final originalLength = collections.length;
      collections.removeWhere(
        (c) =>
            c.createdAt.millisecondsSinceEpoch ==
            createdAt.millisecondsSinceEpoch,
      );

      // VALIDACIÓN: Verificar que se eliminó algo
      if (collections.length == originalLength) {
        throw const FileSystemFailure('Stats collection not found');
      }

      // GUARDADO: Actualizar storage
      final jsonList = collections.map((c) {
        final model = StatsCollectionModel(
          totalStats: c.totalStats,
          rankedStats: c.rankedStats,
          classicStats: c.classicStats,
          brawlStats: c.brawlStats,
          createdAt: c.createdAt,
        );
        return model.toJson();
      }).toList();

      final jsonString = json.encode(jsonList);
      final success = await sharedPreferences.setString(
        _collectionsKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to delete stats collection');
      }
    } catch (e) {
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error deleting stats: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllStats() async {
    try {
      final success = await sharedPreferences.remove(_collectionsKey);

      if (!success) {
        throw const FileSystemFailure('Failed to clear all stats');
      }
    } catch (e) {
      throw FileSystemFailure('Error clearing stats: ${e.toString()}');
    }
  }
}
