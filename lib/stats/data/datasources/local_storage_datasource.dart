// lib/stats/data/datasources/local_storage_datasource.dart
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
      final collections = await getAllStatsCollections();
      collections.add(collection);

      final jsonList = collections
          .map((c) => StatsCollectionModel.fromEntity(c).toJson())
          .toList();

      final jsonString = json.encode(jsonList);
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

      if (jsonString == null) {
        return [];
      }

      final jsonList = json.decode(jsonString) as List;

      return jsonList
          .map(
            (jsonMap) =>
                StatsCollectionModel.fromJson(jsonMap as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      collections.removeWhere(
        (c) =>
            c.createdAt.millisecondsSinceEpoch ==
            createdAt.millisecondsSinceEpoch,
      );

      final jsonList = collections
          .map((c) => StatsCollectionModel.fromEntity(c).toJson())
          .toList();

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
