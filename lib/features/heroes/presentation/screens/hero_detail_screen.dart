import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/heroes/domain/entities/hero_build.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/entities/hero_equipment.dart';
import 'package:insight/features/heroes/domain/entities/hero_relation.dart';
import 'package:insight/features/heroes/domain/entities/hero_skill.dart';
import 'package:insight/features/heroes/domain/entities/hero_stat.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_bloc.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_event.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_state.dart';
import 'package:insight/features/heroes/presentation/utils/hero_role_utils.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class HeroDetailScreen extends StatefulWidget {
  const HeroDetailScreen({
    super.key,
    required this.heroId,
    required this.heroMap,
  });

  final int heroId;
  final Map<int, MlbbHero> heroMap;

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HeroBloc>().add(LoadHeroDetailEvent(widget.heroId));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0C10) : colorScheme.surface,
      body: BlocBuilder<HeroBloc, HeroState>(
        buildWhen: (_, s) =>
            s is HeroDetailLoading ||
            s is HeroDetailLoaded ||
            s is HeroDetailError,
        builder: (context, state) {
          if (state is HeroDetailLoading) {
            return const _LoadingView();
          }
          if (state is HeroDetailError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<HeroBloc>()
                  .add(LoadHeroDetailEvent(widget.heroId)),
            );
          }
          if (state is HeroDetailLoaded) {
            return _DetailContent(
              detail: state.detail,
              heroMap: widget.heroMap,
              currentIndex: _currentIndex,
              onTabChanged: (i) => setState(() => _currentIndex = i),
              isDark: isDark,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Vista principal de detalle
// ══════════════════════════════════════════════════════════════════

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.heroMap,
    required this.currentIndex,
    required this.onTabChanged,
    required this.isDark,
  });

  final HeroDetail detail;
  final Map<int, MlbbHero> heroMap;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      _InfoTab(hero: detail, isDark: isDark),
      _StatsTab(stats: detail.stats, isDark: isDark),
      _BuildsTab(builds: detail.builds, isDark: isDark),
      _CountersTab(
          relation: detail.relation, heroMap: heroMap, isDark: isDark),
    ];

    return Stack(
      children: [
        // Contenido scrolleable
        CustomScrollView(
          slivers: [
            // ── SliverAppBar con header expandible ────────────
            _HeroSliverHeader(detail: detail, isDark: isDark),

            // ── Cuerpo del tab activo ──────────────────────────
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: KeyedSubtree(
                  key: ValueKey(currentIndex),
                  child: Padding(
                    // Espacio para el bottom bar flotante
                    padding: const EdgeInsets.only(bottom: 100),
                    child: pages[currentIndex],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Bottom bar flotante ────────────────────────────────
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: _FloatingTabBar(
              currentIndex: currentIndex,
              onChanged: onTabChanged,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sliver header ─────────────────────────────────────────────────

class _HeroSliverHeader extends StatelessWidget {
  const _HeroSliverHeader({required this.detail, required this.isDark});

  final HeroDetail detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor =
        isDark ? const Color(0xFF111318) : colorScheme.surfaceContainerHighest;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: colorScheme.onSurface,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        detail.name.toUpperCase(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colorScheme.onSurface,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeroHeaderBackground(
          detail: detail,
          isDark: isDark,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

class _HeroHeaderBackground extends StatelessWidget {
  const _HeroHeaderBackground({
    required this.detail,
    required this.isDark,
    required this.colorScheme,
  });

  final HeroDetail detail;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final heroColor = HeroRoleUtils.avatarColorForId(detail.heroId);
    final surfaceColor =
        isDark ? const Color(0xFF111318) : colorScheme.surfaceContainerHighest;

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar + meta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _HeroAvatarLarge(detail: detail, heroColor: heroColor),
              const SizedBox(width: 16),
              // Nombre, roles, lane
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      detail.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: colorScheme.onSurface,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (detail.roles.isNotEmpty)
                      HeroRoleUtils.buildRoleChips(detail.roles),
                    const SizedBox(height: 8),
                    if (detail.lane.isNotEmpty)
                      _LaneIndicator(
                          lane: detail.lane, colorScheme: colorScheme),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stat pills
          if (detail.stats.isNotEmpty)
            Row(
              children: detail.stats
                  .take(4)
                  .map((s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _StatPillSmall(
                              stat: s,
                              isDark: isDark,
                              colorScheme: colorScheme),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _HeroAvatarLarge extends StatelessWidget {
  const _HeroAvatarLarge({required this.detail, required this.heroColor});

  final HeroDetail detail;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: heroColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: detail.iconUrl.isNotEmpty
            ? Image.network(
                detail.iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _AvatarFallback(detail: detail, heroColor: heroColor),
              )
            : _AvatarFallback(detail: detail, heroColor: heroColor),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.detail, required this.heroColor});

  final HeroDetail detail;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: heroColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          detail.name.isNotEmpty ? detail.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: heroColor,
          ),
        ),
      ),
    );
  }
}

class _LaneIndicator extends StatelessWidget {
  const _LaneIndicator({required this.lane, required this.colorScheme});

  final String lane;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.place_rounded,
          size: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Text(
          lane,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _StatPillSmall extends StatelessWidget {
  const _StatPillSmall({
    required this.stat,
    required this.isDark,
    required this.colorScheme,
  });

  final HeroStat stat;
  final bool isDark;
  final ColorScheme colorScheme;

  Color get _valueColor {
    switch (stat.label) {
      case 'Durabilidad':
        return const Color(0xFFEF4444);
      case 'Ofensa':
        return const Color(0xFFF59E0B);
      case 'Habilidad':
        return const Color(0xFF8B5CF6);
      case 'Dificultad':
        return const Color(0xFF10B981);
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF181C24)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar flotante ───────────────────────────────────────────

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.currentIndex,
    required this.onChanged,
    required this.colorScheme,
    required this.isDark,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? const Color(0xFF181C24) : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.12 : 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SalomonBottomBar(
        currentIndex: currentIndex,
        onTap: onChanged,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.45),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            title: const Text('Info'),
            selectedColor: colorScheme.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.bar_chart_rounded),
            title: const Text('Stats'),
            selectedColor: colorScheme.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.build_outlined),
            title: const Text('Builds'),
            selectedColor: colorScheme.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.compare_arrows_rounded),
            title: const Text('Counters'),
            selectedColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab: INFO
// ══════════════════════════════════════════════════════════════════

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.hero, required this.isDark});

  final HeroDetail hero;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historia
          if (hero.story.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF111318)
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                hero.story,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Especialidades
          if (hero.specialties.isNotEmpty) ...[
            _SectionLabel(label: 'Especialidades', colorScheme: colorScheme),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hero.specialties
                  .map((s) => _SpecialtyChip(
                      label: s, colorScheme: colorScheme, isDark: isDark))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Habilidades
          if (hero.skills.isNotEmpty) ...[
            _SectionLabel(label: 'Habilidades', colorScheme: colorScheme),
            const SizedBox(height: 12),
            ...hero.skills.map((s) => _SkillCard(
                skill: s, colorScheme: colorScheme, isDark: isDark)),
          ],
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.label,
    required this.colorScheme,
    required this.isDark,
  });

  final String label;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF181C24)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.colorScheme,
    required this.isDark,
  });

  final HeroSkill skill;
  final ColorScheme colorScheme;
  final bool isDark;

  static const List<Color> _skillColors = [
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111318)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono de habilidad
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: skill.iconUrl.isNotEmpty
                ? Image.network(
                    skill.iconUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _SkillIconFallback(
                      color: _skillColors[0],
                      label: skill.name.isNotEmpty ? skill.name[0] : '?',
                    ),
                  )
                : _SkillIconFallback(
                    color: _skillColors[0],
                    label: skill.name.isNotEmpty ? skill.name[0] : '?',
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (skill.cooldownAndCost.isNotEmpty)
                      Text(
                        skill.cooldownAndCost,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  skill.description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillIconFallback extends StatelessWidget {
  const _SkillIconFallback({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab: STATS
// ══════════════════════════════════════════════════════════════════

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats, required this.isDark});

  final List<HeroStat> stats;
  final bool isDark;

  static const List<Color> _statColors = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (stats.isEmpty) {
      return const _TabEmptyState(message: 'Sin estadísticas disponibles');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Atributos del héroe', colorScheme: colorScheme),
          const SizedBox(height: 20),
          ...stats.asMap().entries.map((e) {
            final color = _statColors[e.key % _statColors.length];
            return _StatBarRow(
              stat: e.value,
              color: color,
              colorScheme: colorScheme,
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }
}

class _StatBarRow extends StatelessWidget {
  const _StatBarRow({
    required this.stat,
    required this.color,
    required this.colorScheme,
    required this.isDark,
  });

  final HeroStat stat;
  final Color color;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.normalizedValue,
              minHeight: 6,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab: BUILDS
// ══════════════════════════════════════════════════════════════════

class _BuildsTab extends StatelessWidget {
  const _BuildsTab({required this.builds, required this.isDark});

  final List<HeroBuild> builds;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (builds.isEmpty) {
      return const _TabEmptyState(message: 'Sin builds disponibles');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: builds.asMap().entries
            .map((e) => _BuildCard(
                heroBuild: e.value,
                index: e.key,
                isDark: isDark))
            .toList(),
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.heroBuild,
    required this.index,
    required this.isDark,
  });

  final HeroBuild heroBuild;
  final int index;
  final bool isDark;

  static const _buildLabels = ['Meta', 'Burst', 'Tank'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final winPct = (heroBuild.winRate * 100).toStringAsFixed(1);
    final pickPct = (heroBuild.pickRate * 100).toStringAsFixed(1);
    final label = index < _buildLabels.length ? _buildLabels[index] : '${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111318)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.12),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Build ${index + 1} — $label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              _BuildRateBadge(
                label: 'WR $winPct%',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              _BuildRateBadge(
                label: 'Pick $pickPct%',
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ítems
          _SectionLabel(
            label: 'Ítems',
            colorScheme: colorScheme,
            small: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: heroBuild.items.isNotEmpty
                ? heroBuild.items
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ItemIcon(item: item),
                        ))
                    .toList()
                : heroBuild.equipIds
                    .map((id) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ItemIconPlaceholder(id: id),
                        ))
                    .toList(),
          ),
          const SizedBox(height: 14),

          // Hechizo y emblema
          _SectionLabel(
            label: 'Hechizo y Emblema',
            colorScheme: colorScheme,
            small: true,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (heroBuild.spellIconUrl.isNotEmpty)
                _SpellCard(
                  iconUrl: heroBuild.spellIconUrl,
                  name: heroBuild.spellName,
                ),
              const SizedBox(width: 10),
              if (heroBuild.emblemIconUrl.isNotEmpty)
                Expanded(
                  child: _EmblemCard(
                    iconUrl: heroBuild.emblemIconUrl,
                    name: heroBuild.emblemName,
                    attrs: heroBuild.emblemAttrs,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildRateBadge extends StatelessWidget {
  const _BuildRateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.item});

  final HeroEquipment item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: item.name,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.5),
              child: item.iconUrl.isNotEmpty
                  ? Image.network(
                      item.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ItemIconPlaceholder(id: item.equipId),
                    )
                  : _ItemIconPlaceholder(id: item.equipId),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 44,
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemIconPlaceholder extends StatelessWidget {
  const _ItemIconPlaceholder({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          '$id',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SpellCard extends StatelessWidget {
  const _SpellCard({required this.iconUrl, required this.name});

  final String iconUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(
              iconUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.flash_on, size: 28, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 48,
            child: Text(
              name,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmblemCard extends StatelessWidget {
  const _EmblemCard({
    required this.iconUrl,
    required this.name,
    required this.attrs,
  });

  final String iconUrl;
  final String name;
  final String attrs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cleanAttrs = attrs
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF181C24)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              iconUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.star_rounded, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (cleanAttrs.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cleanAttrs,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
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

// ══════════════════════════════════════════════════════════════════
// Tab: COUNTERS
// ══════════════════════════════════════════════════════════════════

class _CountersTab extends StatelessWidget {
  const _CountersTab({
    required this.relation,
    required this.heroMap,
    required this.isDark,
  });

  final HeroRelation? relation;
  final Map<int, MlbbHero> heroMap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (relation == null) {
      return const _TabEmptyState(message: 'Sin datos de counters');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (relation!.strongAgainst.isNotEmpty) ...[
            _CounterSection(
              title: 'Fuerte contra',
              dotColor: const Color(0xFF10B981),
              titleColor: const Color(0xFF34D399),
              ids: relation!.strongAgainst,
              borderColor: const Color(0xFFEF4444),
              heroMap: heroMap,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
          if (relation!.weakAgainst.isNotEmpty) ...[
            _CounterSection(
              title: 'Débil contra',
              dotColor: const Color(0xFFEF4444),
              titleColor: const Color(0xFFF87171),
              ids: relation!.weakAgainst,
              borderColor: const Color(0xFF8B5CF6),
              heroMap: heroMap,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
          if (relation!.bestWith.isNotEmpty)
            _CounterSection(
              title: 'Mejores compañeros',
              dotColor: const Color(0xFF3B82F6),
              titleColor: const Color(0xFF60A5FA),
              ids: relation!.bestWith,
              borderColor: const Color(0xFF3B82F6),
              heroMap: heroMap,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _CounterSection extends StatelessWidget {
  const _CounterSection({
    required this.title,
    required this.dotColor,
    required this.titleColor,
    required this.ids,
    required this.borderColor,
    required this.heroMap,
    required this.isDark,
  });

  final String title;
  final Color dotColor;
  final Color titleColor;
  final List<int> ids;
  final Color borderColor;
  final Map<int, MlbbHero> heroMap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: titleColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: ids.map((id) {
            final hero = heroMap[id];
            final avatarColor = HeroRoleUtils.avatarColorForId(id);
            return _CounterHeroAvatar(
              heroId: id,
              name: hero?.name ?? 'ID $id',
              iconUrl: hero?.iconUrl ?? '',
              avatarColor: avatarColor,
              borderColor: borderColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CounterHeroAvatar extends StatelessWidget {
  const _CounterHeroAvatar({
    required this.heroId,
    required this.name,
    required this.iconUrl,
    required this.avatarColor,
    required this.borderColor,
  });

  final int heroId;
  final String name;
  final String iconUrl;
  final Color avatarColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: iconUrl.isNotEmpty
                  ? Image.network(
                      iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _CounterPlaceholder(color: avatarColor, name: name),
                    )
                  : _CounterPlaceholder(color: avatarColor, name: name),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CounterPlaceholder extends StatelessWidget {
  const _CounterPlaceholder({required this.color, required this.name});

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Widgets compartidos
// ══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.colorScheme,
    this.small = false,
  });

  final String label;
  final ColorScheme colorScheme;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: small ? 10 : 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: colorScheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: colorScheme.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
