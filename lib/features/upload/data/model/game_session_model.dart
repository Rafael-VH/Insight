import 'package:insight/features/parser/domain/entities/player_performance.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

class StatsCollectionModel extends StatsCollection {
  const StatsCollectionModel({
    super.totalStats,
    super.rankedStats,
    super.classicStats,
    super.brawlStats,
    required super.createdAt,
    super.name,
  });

  factory StatsCollectionModel.fromEntity(StatsCollection collection) {
    return StatsCollectionModel(
      totalStats: collection.totalStats,
      rankedStats: collection.rankedStats,
      classicStats: collection.classicStats,
      brawlStats: collection.brawlStats,
      createdAt: collection.createdAt,
      name: collection.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Verificar null antes de convertir
      'totalStats': totalStats?.toJson(),
      'rankedStats': rankedStats?.toJson(),
      'classicStats': classicStats?.toJson(),
      'brawlStats': brawlStats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'name': name, // NUEVO
    };
  }

  factory StatsCollectionModel.fromJson(Map<String, dynamic> json) {
    return StatsCollectionModel(
      // Verificar null correctamente
      totalStats: json['totalStats'] != null
          ? PlayerPerformance.fromJson(json['totalStats'] as Map<String, dynamic>)
          : null,
      rankedStats: json['rankedStats'] != null
          ? PlayerPerformance.fromJson(json['rankedStats'] as Map<String, dynamic>)
          : null,
      classicStats: json['classicStats'] != null
          ? PlayerPerformance.fromJson(json['classicStats'] as Map<String, dynamic>)
          : null,
      brawlStats: json['brawlStats'] != null
          ? PlayerPerformance.fromJson(json['brawlStats'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      name: json['name'] as String? ?? '',
    );
  }
}
