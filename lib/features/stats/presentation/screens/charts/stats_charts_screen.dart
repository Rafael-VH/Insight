import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';
import 'package:intl/intl.dart';

class StatsChartsScreen extends StatefulWidget {
  const StatsChartsScreen({super.key, required this.collection});

  final StatsCollection collection;

  @override
  State<StatsChartsScreen> createState() => _StatsChartsScreenState();
}

class _StatsChartsScreenState extends State<StatsChartsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<PlayerStats> _availableStats;

  @override
  void initState() {
    super.initState();
    _availableStats = widget.collection.availableStats;
    _tabController = TabController(length: _availableStats.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_availableStats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Análisis Visual')),
        body: const Center(child: Text('Sin datos para mostrar')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis Visual',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.collection.displayName,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        bottom: _availableStats.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _availableStats
                    .map(
                      (s) => Tab(
                        icon: Icon(s.mode.icon, size: 16),
                        text: s.mode.shortName,
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
      body: _availableStats.length == 1
          ? _ModeChartsPage(stats: _availableStats.first)
          : TabBarView(
              controller: _tabController,
              children: _availableStats
                  .map((s) => _ModeChartsPage(stats: s))
                  .toList(),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// PÁGINA POR MODO
// ══════════════════════════════════════════════════════════

class _ModeChartsPage extends StatelessWidget {
  const _ModeChartsPage({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryHeaderCard(stats: stats),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Tasa de Victoria', icon: Icons.emoji_events),
        const SizedBox(height: 8),
        _WinRateGauge(winRate: stats.winRate),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Rendimiento', icon: Icons.bar_chart),
        const SizedBox(height: 8),
        _PerformanceBarChart(stats: stats),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Logros', icon: Icons.stars_rounded),
        const SizedBox(height: 8),
        _AchievementsRadarChart(stats: stats),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Economía & Daño por Min',
          icon: Icons.attach_money_rounded,
        ),
        const SizedBox(height: 8),
        _EconomyPieChart(stats: stats),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES COMUNES
// ══════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// TARJETA RESUMEN
// ══════════════════════════════════════════════════════════

class _SummaryHeaderCard extends StatelessWidget {
  const _SummaryHeaderCard({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final color = stats.mode.color;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.04),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(stats.mode.icon, color: color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.mode.fullDisplayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill('Partidas', stats.totalGames.toString(), color),
                _StatPill(
                  'Win%',
                  '${stats.winRate.toStringAsFixed(1)}%',
                  color,
                ),
                _StatPill('KDA', stats.kda.toStringAsFixed(2), color),
                _StatPill('MVP', stats.mvpCount.toString(), color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIN RATE GAUGE
// ══════════════════════════════════════════════════════════

class _WinRateGauge extends StatelessWidget {
  const _WinRateGauge({required this.winRate});

  final double winRate;

  Color _gaugeColor(double pct) {
    if (pct >= 60) return const Color(0xFF059669);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final pct = winRate.clamp(0.0, 100.0);
    final color = _gaugeColor(pct);

    return _ChartCard(
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                startDegreeOffset: 180,
                sectionsSpace: 2,
                centerSpaceRadius: 55,
                sections: [
                  PieChartSectionData(
                    value: pct,
                    color: color,
                    title: '',
                    radius: 28,
                  ),
                  PieChartSectionData(
                    value: 100.0 - pct,
                    color: Colors.grey.shade200,
                    title: '',
                    radius: 28,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Win Rate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// PERFORMANCE BAR CHART
// ══════════════════════════════════════════════════════════

class _PerformanceBarChart extends StatelessWidget {
  const _PerformanceBarChart({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final color = stats.mode.color;
    final totalGames = stats.totalGames > 0 ? stats.totalGames.toDouble() : 1.0;

    // Cada entrada: (etiqueta, valor real, valor máximo de referencia)
    final entries = <_BarEntry>[
      _BarEntry('KDA', stats.kda, 10.0, color),
      _BarEntry('Part.%', stats.teamFightParticipation, 100.0, color),
      _BarEntry(
        'Muertes/P',
        stats.deathsPerGame,
        10.0,
        const Color(0xFFDC2626),
      ),
      _BarEntry('MVP%', stats.mvpCount / totalGames * 100, 100.0, color),
    ];

    return _ChartCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    //tooltipRoundedRadius: 8,
                    getTooltipColor: (_) =>
                        Colors.black.withValues(alpha: 0.75),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final e = entries[groupIndex];
                      return BarTooltipItem(
                        '${e.label}\n${e.rawValue.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entries[idx].label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final normalized =
                      ((e.value.rawValue / e.value.maxValue) * 100).clamp(
                        0.0,
                        100.0,
                      );
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: normalized,
                        color: e.value.color,
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: e.value.color.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: entries
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${e.label}: ${e.rawValue.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BarEntry {
  const _BarEntry(this.label, this.rawValue, this.maxValue, this.color);

  final String label;
  final double rawValue;
  final double maxValue;
  final Color color;
}

// ══════════════════════════════════════════════════════════
// ACHIEVEMENTS RADAR CHART
// ══════════════════════════════════════════════════════════

class _AchievementsRadarChart extends StatelessWidget {
  const _AchievementsRadarChart({required this.stats});

  final PlayerStats stats;

  // Normalización segura: evita división por cero
  static double _norm(num value, num maxRef) {
    if (maxRef <= 0) return 0.0;
    return (value / maxRef * 10.0).clamp(0.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = stats.mode.color;
    final totalGames = stats.totalGames > 0 ? stats.totalGames : 1;

    final labels = [
      'Legendario',
      'Savage',
      'Maniac',
      'Triple Kill',
      'Doble Kill',
      'Primera Sangre',
    ];

    final rawValues = [
      stats.legendary,
      stats.savage,
      stats.maniac,
      stats.tripleKill,
      stats.doubleKill,
      stats.firstBlood,
    ];

    final normalizedValues = [
      _norm(stats.legendary, 10),
      _norm(stats.savage, 5),
      _norm(stats.maniac, 20),
      _norm(stats.tripleKill, 30),
      _norm(stats.doubleKill, 50),
      _norm(stats.firstBlood, totalGames),
    ];

    // fl_chart requiere mínimo 3 puntos y que no sean todos 0
    final allZero = normalizedValues.every((v) => v == 0.0);

    return _ChartCard(
      child: Column(
        children: [
          if (allZero)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'Sin logros registrados',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: [
                    RadarDataSet(
                      dataEntries: normalizedValues
                          .map((v) => RadarEntry(value: v))
                          .toList(),
                      fillColor: color.withValues(alpha: 0.2),
                      borderColor: color,
                      borderWidth: 2,
                      entryRadius: 3,
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  gridBorderData: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(
                    fontSize: 0,
                    color: Colors.transparent,
                  ),
                  getTitle: (index, angle) => RadarChartTitle(
                    text: labels[index],
                    angle: 0, // ← siempre horizontal para legibilidad
                  ),
                  titleTextStyle: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  //titlePadding: 16,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(
              labels.length,
              (i) => _LegendChip(
                label: labels[i],
                value: rawValues[i].toString(),
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// ECONOMY PIE CHART
// ══════════════════════════════════════════════════════════

class _EconomyPieChart extends StatefulWidget {
  const _EconomyPieChart({required this.stats});

  final PlayerStats stats;

  @override
  State<_EconomyPieChart> createState() => _EconomyPieChartState();
}

class _EconomyPieChartState extends State<_EconomyPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final entries = [
      _PieEntry('Oro/Min', s.goldPerMin.toDouble(), const Color(0xFFF59E0B)),
      _PieEntry(
        'Daño Héroe/Min',
        s.heroDamagePerMin.toDouble(),
        const Color(0xFFDC2626),
      ),
      _PieEntry(
        'Daño Torre/P',
        s.towerDamagePerGame.toDouble(),
        const Color(0xFF7C3AED),
      ),
    ];

    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    if (total == 0) {
      return _ChartCard(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'Sin datos de economía',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return _ChartCard(
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final idx =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                      if (_touchedIndex != idx) {
                        setState(() => _touchedIndex = idx);
                      }
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: 32,
                  sections: entries.asMap().entries.map((e) {
                    final isTouched = e.key == _touchedIndex;
                    final pct = (e.value.value / total * 100);
                    return PieChartSectionData(
                      value: e.value.value,
                      color: e.value.color,
                      radius: isTouched ? 65 : 55,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: e.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              NumberFormat.compact().format(e.value),
                              style: TextStyle(
                                fontSize: 14,
                                color: e.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PieEntry {
  const _PieEntry(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
