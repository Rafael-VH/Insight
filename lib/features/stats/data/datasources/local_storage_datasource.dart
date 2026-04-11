import 'dart:convert';

import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/data/model/stats_collection_model.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageDataSource {
  Future<void> saveStatsCollection(StatsCollection collection);
  Future<List<StatsCollection>> getAllStatsCollections();
  Future<StatsCollection?> getLatestStatsCollection();
  Future<void> deleteStatsCollection(DateTime createdAt);
  Future<void> clearAllStats();

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
      // Obtener colecciones existentes
      List<StatsCollection> collections = [];
      try {
        collections = await getAllStatsCollections();
      } catch (e) {
        collections = [];
      }

      final exactDuplicateIndex = collections.indexWhere(
        (c) => c.createdAt.millisecondsSinceEpoch == collection.createdAt.millisecondsSinceEpoch,
      );

      if (exactDuplicateIndex != -1) {
        collections[exactDuplicateIndex] = collection;
      } else {
        collections.add(collection);
      }

      collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

      final success = await sharedPreferences.setString(_collectionsKey, jsonString);

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
        await sharedPreferences.remove(_collectionsKey);
        return [];
      }

      if (decoded is! List) {
        await sharedPreferences.remove(_collectionsKey);
        return [];
      }

      final collections = <StatsCollection>[];
      for (int i = 0; i < decoded.length; i++) {
        final item = decoded[i];

        if (item is! Map<String, dynamic>) {
          continue;
        }

        try {
          final collection = StatsCollectionModel.fromJson(item);
          collections.add(collection);
        } catch (e) {
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

      final originalLength = collections.length;
      collections.removeWhere(
        (c) => c.createdAt.millisecondsSinceEpoch == createdAt.millisecondsSinceEpoch,
      );

      if (collections.length == originalLength) {
        throw const FileSystemFailure('Stats collection not found');
      }

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
      final success = await sharedPreferences.setString(_collectionsKey, jsonString);

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

  @override
  Future<void> updateStatsCollectionName(DateTime createdAt, String newName) async {
    try {
      final collections = await getAllStatsCollections();
      final index = collections.indexWhere(
        (c) => c.createdAt.millisecondsSinceEpoch == createdAt.millisecondsSinceEpoch,
      );

      if (index == -1) {
        throw const FileSystemFailure('Stats collection not found');
      }

      collections[index] = collections[index].copyWith(name: newName);

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
      final success = await sharedPreferences.setString(_collectionsKey, jsonString);

      if (!success) {
        throw const FileSystemFailure('Failed to update stats collection name');
      }
    } catch (e) {
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error updating collection name: ${e.toString()}');
    }
  }

  @override
  Future<StatsCollection?> getStatsCollectionByDate(DateTime createdAt) async {
    try {
      final collections = await getAllStatsCollections();

      try {
        final collection = collections.firstWhere(
          (c) => c.createdAt.millisecondsSinceEpoch == createdAt.millisecondsSinceEpoch,
        );
        return collection;
      } catch (e) {
        return null;
      }
    } catch (e) {
      throw FileSystemFailure('Error loading collection by date: ${e.toString()}');
    }
  }
}
