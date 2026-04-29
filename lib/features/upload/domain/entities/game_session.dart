import 'package:insight/features/parser/domain/entities/player_performance.dart';

class StatsCollection {
  final PlayerPerformance? totalStats;
  final PlayerPerformance? rankedStats;
  final PlayerPerformance? classicStats;
  final PlayerPerformance? brawlStats;
  final DateTime createdAt;
  final String name;

  const StatsCollection({
    this.totalStats,
    this.rankedStats,
    this.classicStats,
    this.brawlStats,
    required this.createdAt,
    String? name,
  }) : name = name ?? '';

  bool get hasAnyStats =>
      totalStats != null || rankedStats != null || classicStats != null || brawlStats != null;

  List<PlayerPerformance> get availableStats {
    final List<PlayerPerformance> stats = [];
    if (totalStats != null) stats.add(totalStats!);
    if (rankedStats != null) stats.add(rankedStats!);
    if (classicStats != null) stats.add(classicStats!);
    if (brawlStats != null) stats.add(brawlStats!);
    return stats;
  }

  // Método copyWith para facilitar actualizaciones
  StatsCollection copyWith({
    PlayerPerformance? totalStats,
    PlayerPerformance? rankedStats,
    PlayerPerformance? classicStats,
    PlayerPerformance? brawlStats,
    DateTime? createdAt,
    String? name,
  }) {
    return StatsCollection(
      totalStats: totalStats ?? this.totalStats,
      rankedStats: rankedStats ?? this.rankedStats,
      classicStats: classicStats ?? this.classicStats,
      brawlStats: brawlStats ?? this.brawlStats,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
    );
  }

  // Método para obtener nombre auto-generado si está vacío
  String get displayName {
    if (name.isNotEmpty) return name;

    // Generar nombre automático basado en modos disponibles
    final modes = <String>[];
    if (totalStats != null) modes.add('Total');
    if (rankedStats != null) modes.add('Ranked');
    if (classicStats != null) modes.add('Clásica');
    if (brawlStats != null) modes.add('Coliseo');

    if (modes.isEmpty) return 'Sin estadísticas';

    return 'Stats ${modes.join(', ')}';
  }
}
