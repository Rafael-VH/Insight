import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.collection});

  final StatsCollection collection;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _activeTabIndex = 0;

  List<PlayerStats> get _stats => widget.collection.availableStats;

  PlayerStats get _activeStat => _stats[_activeTabIndex];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

    if (_stats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('Sin estadísticas disponibles')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0C10) : colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Back button flotante (sin AppBar) ────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _BackButton(),
              ),
            ),
          ),

          // ── Band de identidad de sesión ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SessionBand(
                collection: widget.collection,
                stats: _stats,
                activeStat: _activeStat,
                formattedDate:
                    dateFormat.format(widget.collection.createdAt),
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ),
          ),

          // ── Tabs por modo (si hay más de uno) ─────────────────
          if (_stats.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _ModeTabs(
                  stats: _stats,
                  activeIndex: _activeTabIndex,
                  onChanged: (i) => setState(() => _activeTabIndex = i),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Barra de completitud ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CompletenessBar(
                stats: _activeStat,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ── Secciones de estadísticas ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatsSection(
                title: 'Estadísticas principales',
                fields: _getPrimaryFields(_activeStat),
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatsSection(
                title: 'Rendimiento por partida',
                fields: _getPerformanceFields(_activeStat),
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatsSection(
                title: 'Logros y récords',
                fields: _getAchievementFields(_activeStat),
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Grupos de campos ──────────────────────────────────────────

  List<_StatField> _getPrimaryFields(PlayerStats s) => [
        _StatField('Partidas totales', '${s.totalGames}', s.totalGames > 0),
        _StatField(
          'Win Rate',
          s.winRate > 0 ? '${s.winRate.toStringAsFixed(2)}%' : '—',
          s.winRate > 0,
          accentColor: s.winRate >= 50 ? const Color(0xFF059669) : null,
        ),
        _StatField('MVP', '${s.mvpCount}', s.mvpCount > 0),
        _StatField(
          'KDA',
          s.kda > 0 ? s.kda.toStringAsFixed(2) : '—',
          s.kda > 0,
          accentColor: s.kda >= 3 ? const Color(0xFF059669) : null,
        ),
      ];

  List<_StatField> _getPerformanceFields(PlayerStats s) => [
        _StatField(
          'Participación equipo',
          s.teamFightParticipation > 0
              ? '${s.teamFightParticipation.toStringAsFixed(1)}%'
              : '—',
          s.teamFightParticipation > 0,
          accentColor: s.teamFightParticipation >= 70
              ? const Color(0xFF059669)
              : null,
        ),
        _StatField(
          'Oro / Min',
          s.goldPerMin > 0 ? '${s.goldPerMin}' : '—',
          s.goldPerMin > 0,
        ),
        _StatField(
          'Daño héroe / Min',
          s.heroDamagePerMin > 0 ? '${s.heroDamagePerMin}' : '—',
          s.heroDamagePerMin > 0,
        ),
        _StatField(
          'Muertes / Partida',
          s.deathsPerGame > 0 ? s.deathsPerGame.toStringAsFixed(1) : '—',
          true,
          accentColor: s.deathsPerGame > 0 && s.deathsPerGame <= 3
              ? null
              : s.deathsPerGame > 3
                  ? const Color(0xFFD97706)
                  : null,
        ),
        _StatField(
          'Daño torre / Partida',
          s.towerDamagePerGame > 0 ? '${s.towerDamagePerGame}' : '—',
          s.towerDamagePerGame > 0,
        ),
        _StatField(
          'MVP Perdedor',
          s.mvpLoss > 0 ? '${s.mvpLoss}' : '—',
          true,
        ),
      ];

  List<_StatField> _getAchievementFields(PlayerStats s) => [
        _StatField('Legendario', '${s.legendary}', s.legendary > 0),
        _StatField('Savage', '${s.savage}', s.savage > 0),
        _StatField('Maniac', '${s.maniac}', s.maniac > 0),
        _StatField('Triple Kill', '${s.tripleKill}', s.tripleKill > 0),
        _StatField('Doble Kill', '${s.doubleKill}', s.doubleKill > 0),
        _StatField('Primera Sangre', '${s.firstBlood}', s.firstBlood > 0),
        _StatField('Asesinatos Máx.', '${s.maxKills}', s.maxKills > 0),
        _StatField(
            'Asistencias Máx.', '${s.maxAssists}', s.maxAssists > 0),
        _StatField('Racha victorias Máx.', '${s.maxWinningStreak}',
            s.maxWinningStreak > 0),
        _StatField('Daño causado Máx./min', '${s.maxDamageDealt}',
            s.maxDamageDealt > 0),
        _StatField('Daño tomado Máx./min', '${s.maxDamageTaken}',
            s.maxDamageTaken > 0),
        _StatField(
            'Oro Máx./min', '${s.maxGold}', s.maxGold > 0),
      ];
}

// ══════════════════════════════════════════════════════════════════
// Widgets del detalle
// ══════════════════════════════════════════════════════════════════

// ── Botón de volver ───────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Volver al historial',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Band de identidad ─────────────────────────────────────────────

class _SessionBand extends StatelessWidget {
  const _SessionBand({
    required this.collection,
    required this.stats,
    required this.activeStat,
    required this.formattedDate,
    required this.isDark,
    required this.colorScheme,
  });

  final StatsCollection collection;
  final List<PlayerStats> stats;
  final PlayerStats activeStat;
  final String formattedDate;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: _DiagonalPatternPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  collection.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 14),
                // Modos chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: stats.map((s) {
                    return _ModeChip(
                      label: s.mode.shortName,
                      color: s.mode.color,
                    );
                  }).toList(),
                ),
                // Quick stats de la stat activa
                if (activeStat.winRate > 0 || activeStat.kda > 0) ...[
                  Container(
                    height: 0.5,
                    color: Colors.white.withValues(alpha: 0.1),
                    margin: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  Row(
                    children: [
                      if (activeStat.winRate > 0)
                        Expanded(
                          child: _QuickStat(
                            value: '${activeStat.winRate.toStringAsFixed(1)}%',
                            label: 'WIN RATE',
                          ),
                        ),
                      if (activeStat.kda > 0)
                        Expanded(
                          child: _QuickStat(
                            value: activeStat.kda.toStringAsFixed(2),
                            label: 'KDA',
                          ),
                        ),
                      if (activeStat.totalGames > 0)
                        Expanded(
                          child: _QuickStat(
                            value: '${activeStat.totalGames}',
                            label: 'PARTIDAS',
                          ),
                        ),
                      if (activeStat.goldPerMin > 0)
                        Expanded(
                          child: _QuickStat(
                            value: '${activeStat.goldPerMin}',
                            label: 'ORO/MIN',
                          ),
                        ),
                      if (activeStat.teamFightParticipation > 0)
                        Expanded(
                          child: _QuickStat(
                            value:
                                '${activeStat.teamFightParticipation.toStringAsFixed(0)}%',
                            label: 'PART.',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tabs de modo ──────────────────────────────────────────────────

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.stats,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<PlayerStats> stats;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.5),
        child: Row(
          children: stats.asMap().entries.map((e) {
            final isActive = e.key == activeIndex;
            final modeColor = e.value.mode.color;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isActive
                        ? modeColor
                        : isDark
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surface,
                    border: e.key < stats.length - 1
                        ? Border(
                            right: BorderSide(
                              color: colorScheme.outline
                                  .withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        e.value.mode.icon,
                        size: 16,
                        color: isActive
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.value.mode.shortName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: isActive
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Barra de completitud ──────────────────────────────────────────

class _CompletenessBar extends StatelessWidget {
  const _CompletenessBar({
    required this.stats,
    required this.isDark,
    required this.colorScheme,
  });

  final PlayerStats stats;
  final bool isDark;
  final ColorScheme colorScheme;

  // Calcula % de completitud de forma local
  double get _completeness {
    int total = 0;
    int found = 0;
    void check(num v) { total++; if (v != 0) found++; }

    check(stats.totalGames);
    check(stats.winRate);
    check(stats.kda);
    check(stats.teamFightParticipation);
    check(stats.goldPerMin);
    check(stats.heroDamagePerMin);
    check(stats.legendary);
    check(stats.savage);
    check(stats.maniac);
    check(stats.tripleKill);
    check(stats.doubleKill);
    check(stats.firstBlood);
    check(stats.maxKills);
    check(stats.maxAssists);
    check(stats.maxWinningStreak);
    check(stats.maxDamageDealt);
    check(stats.maxDamageTaken);
    check(stats.maxGold);

    return total > 0 ? found / total : 0;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _completeness;
    final pctDisplay = (pct * 100).toStringAsFixed(1);

    Color barColor = const Color(0xFF059669);
    if (pct < 0.7) barColor = const Color(0xFFD97706);
    if (pct < 0.5) barColor = const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPLETITUD DE EXTRACCIÓN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              Text(
                '$pctDisplay%',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección de stats ──────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.title,
    required this.fields,
    required this.isDark,
    required this.colorScheme,
  });

  final String title;
  final List<_StatField> fields;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.12),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de sección
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),

          // Grid 2 columnas
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: _StatGrid(
              fields: fields,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.fields,
    required this.colorScheme,
  });

  final List<_StatField> fields;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Divide en pares para layout de 2 columnas
    final rows = <Widget>[];
    for (int i = 0; i < fields.length; i += 2) {
      final left = fields[i];
      final right = i + 1 < fields.length ? fields[i + 1] : null;
      final isLast = i + 2 >= fields.length;

      rows.add(
        Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
          ),
          child: Row(
            children: [
              // Columna izquierda
              Expanded(
                child: _StatCell(
                  field: left,
                  colorScheme: colorScheme,
                  hasBorderRight: right != null,
                ),
              ),
              // Columna derecha (si existe)
              if (right != null)
                Expanded(
                  child: _StatCell(
                    field: right,
                    colorScheme: colorScheme,
                    hasBorderRight: false,
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.field,
    required this.colorScheme,
    required this.hasBorderRight,
  });

  final _StatField field;
  final ColorScheme colorScheme;
  final bool hasBorderRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: hasBorderRight
            ? Border(
                right: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              field.label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(
                  alpha: field.isPresent ? 0.65 : 0.3,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            field.value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: field.accentColor ??
                  (field.isPresent
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.25)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo de campo ───────────────────────────────────────────────

class _StatField {
  final String label;
  final String value;
  final bool isPresent;
  final Color? accentColor;

  const _StatField(
    this.label,
    this.value,
    this.isPresent, {
    this.accentColor,
  });
}

// ── Pintor de patrón diagonal ─────────────────────────────────────

class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1;

    const spacing = 8.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalPatternPainter old) => false;
}
