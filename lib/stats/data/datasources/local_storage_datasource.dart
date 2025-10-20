import 'dart:convert';

//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/stats/data/model/stats_collection_model.dart';
//
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageDataSource {
  Future<void> saveStatsCollection(StatsCollection collection);
  Future<List<StatsCollection>> getAllStatsCollections();
  Future<StatsCollection?> getLatestStatsCollection();
  Future<void> deleteStatsCollection(DateTime createdAt);
  Future<void> clearAllStats();

  // NUEVOS MÉTODOS
  Future<void> updateStatsCollectionName(DateTime createdAt, String newName);
  Future<StatsCollection?> getStatsCollectionByDate(DateTime createdAt);
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _collectionsKey = 'stats_collections';
  final SharedPreferences sharedPreferences;

  LocalStorageDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveStatsCollection(StatsCollection collection) async {
    try {
      print('📥 Guardando nueva colección...');

      // Obtener colecciones existentes
      List<StatsCollection> collections = [];
      try {
        collections = await getAllStatsCollections();
        print('✓ Colecciones existentes: ${collections.length}');
      } catch (e) {
        print('⚠ Error al obtener colecciones previas: $e');
        collections = [];
      }

      // CORRECCIÓN: Verificar duplicado SOLO si es exactamente el mismo timestamp
      // (mismo milisegundo = misma instancia)
      final exactDuplicateIndex = collections.indexWhere(
        (c) =>
            c.createdAt.millisecondsSinceEpoch ==
            collection.createdAt.millisecondsSinceEpoch,
      );

      if (exactDuplicateIndex != -1) {
        // Solo reemplazar si es EXACTAMENTE el mismo timestamp
        print('⚠ Encontrado duplicado exacto, reemplazando...');
        collections[exactDuplicateIndex] = collection;
      } else {
        // Siempre agregar si no es el mismo timestamp
        print('✓ Agregando nueva colección');
        collections.add(collection);
      }

      print(
        '📊 Total de colecciones después de guardar: ${collections.length}',
      );

      // Ordenar por fecha (más reciente primero)
      collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Convertir a JSON
      final jsonList = collections.map((c) {
        final model = StatsCollectionModel(
          totalStats: c.totalStats,
          rankedStats: c.rankedStats,
          classicStats: c.classicStats,
          brawlStats: c.brawlStats,
          createdAt: c.createdAt,
          name: c.name, // NUEVO
        );
        return model.toJson();
      }).toList();

      final jsonString = json.encode(jsonList);
      print('💾 Guardando ${jsonString.length} caracteres en storage');

      // Guardar
      final success = await sharedPreferences.setString(
        _collectionsKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to save stats collection');
      }

      print('✅ Colección guardada exitosamente');
    } catch (e) {
      print('❌ Error en saveStatsCollection: $e');
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error saving stats: ${e.toString()}');
    }
  }

  @override
  Future<List<StatsCollection>> getAllStatsCollections() async {
    try {
      print('📖 Cargando todas las colecciones...');

      final jsonString = sharedPreferences.getString(_collectionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        print('ℹ No hay colecciones guardadas');
        return [];
      }

      print('📄 JSON encontrado: ${jsonString.length} caracteres');

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

      print('📋 Encontradas ${decoded.length} colecciones en JSON');

      final collections = <StatsCollection>[];
      for (int i = 0; i < decoded.length; i++) {
        final item = decoded[i];

        if (item is! Map<String, dynamic>) {
          print('⚠️ Item $i inválido saltado: $item');
          continue;
        }

        try {
          final collection = StatsCollectionModel.fromJson(item);
          collections.add(collection);
          print('✓ Colección $i cargada: ${collection.createdAt}');
        } catch (e) {
          print('⚠️ Error al convertir colección $i: $e');
          continue;
        }
      }

      // Ordenar por fecha (más reciente primero)
      collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Total colecciones cargadas: ${collections.length}');

      return collections;
    } catch (e) {
      print('❌ Error en getAllStatsCollections: $e');
      throw FileSystemFailure('Error loading stats: ${e.toString()}');
    }
  }

  @override
  Future<StatsCollection?> getLatestStatsCollection() async {
    try {
      print('🔍 Buscando última colección...');

      final collections = await getAllStatsCollections();

      if (collections.isEmpty) {
        print('ℹ No hay colecciones');
        return null;
      }

      print('✅ Última colección encontrada: ${collections.first.createdAt}');
      return collections.first;
    } catch (e) {
      print('❌ Error en getLatestStatsCollection: $e');
      throw FileSystemFailure('Error loading latest stats: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteStatsCollection(DateTime createdAt) async {
    try {
      print('🗑️ Eliminando colección: $createdAt');

      final collections = await getAllStatsCollections();
      print('📊 Colecciones antes de eliminar: ${collections.length}');

      final originalLength = collections.length;
      collections.removeWhere(
        (c) =>
            c.createdAt.millisecondsSinceEpoch ==
            createdAt.millisecondsSinceEpoch,
      );

      if (collections.length == originalLength) {
        print('❌ Colección no encontrada');
        throw const FileSystemFailure('Stats collection not found');
      }

      print('✓ Colección eliminada. Total ahora: ${collections.length}');

      // Guardar actualización
      final jsonList = collections.map((c) {
        final model = StatsCollectionModel(
          totalStats: c.totalStats,
          rankedStats: c.rankedStats,
          classicStats: c.classicStats,
          brawlStats: c.brawlStats,
          createdAt: c.createdAt,
          name: c.name, // NUEVO
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

      print('✅ Eliminación completada');
    } catch (e) {
      print('❌ Error en deleteStatsCollection: $e');
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error deleting stats: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllStats() async {
    try {
      print('🧹 Limpiando todas las estadísticas...');

      final success = await sharedPreferences.remove(_collectionsKey);

      if (!success) {
        throw const FileSystemFailure('Failed to clear all stats');
      }

      print('✅ Todas las estadísticas eliminadas');
    } catch (e) {
      print('❌ Error en clearAllStats: $e');
      throw FileSystemFailure('Error clearing stats: ${e.toString()}');
    }
  }

  // ==================== NUEVOS MÉTODOS ====================

  @override
  Future<void> updateStatsCollectionName(
    DateTime createdAt,
    String newName,
  ) async {
    try {
      print('✏️ Actualizando nombre de colección: $createdAt');

      final collections = await getAllStatsCollections();
      final index = collections.indexWhere(
        (c) =>
            c.createdAt.millisecondsSinceEpoch ==
            createdAt.millisecondsSinceEpoch,
      );

      if (index == -1) {
        throw const FileSystemFailure('Stats collection not found');
      }

      // Actualizar el nombre usando copyWith
      collections[index] = collections[index].copyWith(name: newName);

      // Guardar todas las colecciones actualizadas
      final jsonList = collections.map((c) {
        final model = StatsCollectionModel(
          totalStats: c.totalStats,
          rankedStats: c.rankedStats,
          classicStats: c.classicStats,
          brawlStats: c.brawlStats,
          createdAt: c.createdAt,
          name: c.name,
        );
        return model.toJson();
      }).toList();

      final jsonString = json.encode(jsonList);
      final success = await sharedPreferences.setString(
        _collectionsKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to update stats collection name');
      }

      print('✅ Nombre actualizado a: $newName');
    } catch (e) {
      print('❌ Error en updateStatsCollectionName: $e');
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure(
        'Error updating collection name: ${e.toString()}',
      );
    }
  }

  @override
  Future<StatsCollection?> getStatsCollectionByDate(DateTime createdAt) async {
    try {
      print('🔍 Buscando colección por fecha: $createdAt');

      final collections = await getAllStatsCollections();

      try {
        final collection = collections.firstWhere(
          (c) =>
              c.createdAt.millisecondsSinceEpoch ==
              createdAt.millisecondsSinceEpoch,
        );
        print('✅ Colección encontrada');
        return collection;
      } catch (e) {
        print('❌ Colección no encontrada');
        return null;
      }
    } catch (e) {
      print('❌ Error en getStatsCollectionByDate: $e');
      throw FileSystemFailure(
        'Error loading collection by date: ${e.toString()}',
      );
    }
  }
}
