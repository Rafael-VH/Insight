import 'package:flutter/material.dart';
import 'package:insight/features/parser/domain/entities/player_stats.dart';
import 'package:insight/features/upload/domain/entities/stats_collection.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';

/// Card destacada para la sesión más reciente.
/// Fondo oscuro (tinta del tema), modos como chips de color,
/// y métricas clave de la stat más completa disponible.
class HistoryLatestCard extends StatelessWidget {
  const HistoryLatestCard({
    super.key,
    required this.collection,
    required this.formattedDate,
    required this.relativeTime,
    required this.onTap,
    required this.onOptionsPressed,
  });

  final StatsCollection collection;
  final String formattedDate;
  final String relativeTime;
  final VoidCallback onTap;
  final VoidCallback onOptionsPressed;

  // Obtiene la stat con más datos para mostrar métricas
  PlayerStats? get _primaryStat =>
      collection.totalStats ??
      collection.rankedStats ??
      collection.classicStats ??
      collection.brawlStats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _primaryStat;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onOptionsPressed,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Textura de fondo sutil
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
                  // ── Header: badge + acciones ────────────────
                  Row(
                    children: [
                      _LatestBadge(),
                      const Spacer(),
                      _IconButton(
                        icon: Icons.bar_chart_rounded,
                        onTap: onTap,
                        tooltip: 'Ver gráficos',
                      ),
                      const SizedBox(width: 6),
                      _IconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: onOptionsPressed,
                        tooltip: 'Más opciones',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Nombre ──────────────────────────────────
                  Text(
                    collection.displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // ── Fecha ────────────────────────────────────
                  Text(
                    '$formattedDate · $relativeTime',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Modos como chips ─────────────────────────
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: collection.availableStats.map((s) {
                      return _ModeChip(label: s.mode.shortName, color: s.mode.color);
                    }).toList(),
                  ),

                  // ── Métricas inline ──────────────────────────
                  if (stats != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      height: 0.5,
                      color: Colors.white.withValues(alpha: 0.1),
                      margin: const EdgeInsets.only(bottom: 14),
                    ),
                    Row(
                      children: [
                        if (stats.winRate > 0)
                          Expanded(
                            child: _StatInline(
                              value: '${stats.winRate.toStringAsFixed(1)}%',
                              label: 'WIN RATE',
                            ),
                          ),
                        if (stats.kda > 0)
                          Expanded(
                            child: _StatInline(value: stats.kda.toStringAsFixed(2), label: 'KDA'),
                          ),
                        if (stats.totalGames > 0)
                          Expanded(
                            child: _StatInline(value: '${stats.totalGames}', label: 'PARTIDAS'),
                          ),
                        if (stats.mvpCount > 0)
                          Expanded(
                            child: _StatInline(value: '${stats.mvpCount}', label: 'MVP'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subwidgets internos ───────────────────────────────────────────

class _LatestBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text(
            'MÁS RECIENTE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Icon(icon, size: 15, color: Colors.white70),
        ),
      ),
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
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

class _StatInline extends StatelessWidget {
  const _StatInline({required this.value, required this.label});
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
            fontSize: 18,
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

// ── Pintor de patrón diagonal ─────────────────────────────────────

class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1;

    const spacing = 8.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalPatternPainter old) => false;
}
