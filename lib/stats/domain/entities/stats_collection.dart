import 'package:insight/stats/domain/entities/player_stats.dart';

class StatsCollection {
  final PlayerStats? totalStats;
  final PlayerStats? rankedStats;
  final PlayerStats? classicStats;
  final PlayerStats? brawlStats;
  final DateTime createdAt;

  const StatsCollection({
    this.totalStats,
    this.rankedStats,
    this.classicStats,
    this.brawlStats,
    required this.createdAt,
  });

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
}
