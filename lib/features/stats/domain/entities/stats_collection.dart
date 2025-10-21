import 'package:insight/features/stats/domain/entities/player_stats.dart';

class StatsCollection {
  final PlayerStats? totalStats;
  final PlayerStats? rankedStats;
  final PlayerStats? classicStats;
  final PlayerStats? brawlStats;
  final DateTime createdAt;
  final String name; // NUEVO: Nombre personalizado

  const StatsCollection({
    this.totalStats,
    this.rankedStats,
    this.classicStats,
    this.brawlStats,
    required this.createdAt,
    String? name, // NUEVO: Parámetro opcional
  }) : name = name ?? ''; // NUEVO: Valor por defecto

  bool get hasAnyStats =>
      totalStats != null ||
      rankedStats != null ||
      classicStats != null ||
      brawlStats != null;

  List<PlayerStats> get availableStats {
    final List<PlayerStats> stats = [];
    if (totalStats != null) stats.add(totalStats!);
    if (rankedStats != null) stats.add(rankedStats!);
    if (classicStats != null) stats.add(classicStats!);
    if (brawlStats != null) stats.add(brawlStats!);
    return stats;
  }

  // NUEVO: Método copyWith para facilitar actualizaciones
  StatsCollection copyWith({
    PlayerStats? totalStats,
    PlayerStats? rankedStats,
    PlayerStats? classicStats,
    PlayerStats? brawlStats,
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

  // NUEVO: Método para obtener nombre auto-generado si está vacío
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
