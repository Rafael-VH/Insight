// lib/stats/data/models/stats_collection_model.dart
import 'package:insight/stats/domain/entities/player_stats.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';

class StatsCollectionModel extends StatsCollection {
  const StatsCollectionModel({
    super.totalStats,
    super.rankedStats,
    super.classicStats,
    super.brawlStats,
    required super.createdAt,
  });

  factory StatsCollectionModel.fromEntity(StatsCollection collection) {
    return StatsCollectionModel(
      totalStats: collection.totalStats,
      rankedStats: collection.rankedStats,
      classicStats: collection.classicStats,
      brawlStats: collection.brawlStats,
      createdAt: collection.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStats': totalStats?.toJson(),
      'rankedStats': rankedStats?.toJson(),
      'classicStats': classicStats?.toJson(),
      'brawlStats': brawlStats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StatsCollectionModel.fromJson(Map<String, dynamic> json) {
    return StatsCollectionModel(
      totalStats: json['totalStats'] != null
          ? PlayerStats.fromJson(json['totalStats'])
          : null,
      rankedStats: json['rankedStats'] != null
          ? PlayerStats.fromJson(json['rankedStats'])
          : null,
      classicStats: json['classicStats'] != null
          ? PlayerStats.fromJson(json['classicStats'])
          : null,
      brawlStats: json['brawlStats'] != null
          ? PlayerStats.fromJson(json['brawlStats'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
