import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

class StatsCollectionModel extends StatsCollection {
  const StatsCollectionModel({
    super.totalStats,
    super.rankedStats,
    super.classicStats,
    super.brawlStats,
    required super.createdAt,
    super.name, // NUEVO
  });

  factory StatsCollectionModel.fromEntity(StatsCollection collection) {
    return StatsCollectionModel(
      totalStats: collection.totalStats,
      rankedStats: collection.rankedStats,
      classicStats: collection.classicStats,
      brawlStats: collection.brawlStats,
      createdAt: collection.createdAt,
      name: collection.name, // NUEVO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // MEJORADO: Verificar null antes de convertir
      'totalStats': totalStats != null ? totalStats!.toJson() : null,
      'rankedStats': rankedStats != null ? rankedStats!.toJson() : null,
      'classicStats': classicStats != null ? classicStats!.toJson() : null,
      'brawlStats': brawlStats != null ? brawlStats!.toJson() : null,
      'createdAt': createdAt.toIso8601String(),
      'name': name, // NUEVO
    };
  }

  factory StatsCollectionModel.fromJson(Map<String, dynamic> json) {
    return StatsCollectionModel(
      // MEJORADO: Verificar null correctamente
      totalStats: json['totalStats'] != null
          ? PlayerStats.fromJson(json['totalStats'] as Map<String, dynamic>)
          : null,
      rankedStats: json['rankedStats'] != null
          ? PlayerStats.fromJson(json['rankedStats'] as Map<String, dynamic>)
          : null,
      classicStats: json['classicStats'] != null
          ? PlayerStats.fromJson(json['classicStats'] as Map<String, dynamic>)
          : null,
      brawlStats: json['brawlStats'] != null
          ? PlayerStats.fromJson(json['brawlStats'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      name:
          json['name'] as String? ??
          '', // NUEVO: Compatibilidad con datos antiguos
    );
  }
}
