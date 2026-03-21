import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/entities/hero_build.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/entities/hero_equipment.dart';
import 'package:insight/features/heroes/domain/entities/hero_relation.dart';
import 'package:insight/features/heroes/domain/entities/hero_skill.dart';
import 'package:insight/features/heroes/domain/entities/hero_stat.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_detail/hero_detail_bloc.dart';
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
    context.read<HeroDetailBloc>().add(LoadHeroDetailEvent(widget.heroId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HeroDetailBloc, HeroDetailState>(
        builder: (context, state) {
          if (state is HeroDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HeroDetailError) {
            return _buildError(context, state.message);
          }
          if (state is HeroDetailLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<HeroDetailBloc>().add(
              LoadHeroDetailEvent(widget.heroId),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HeroDetailLoaded state) {
    final hero = state.detail;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _InfoTab(hero: hero),
      _StatsTab(stats: hero.stats),
      _BuildsTab(builds: hero.builds),
      _CountersTab(relation: hero.relation, heroMap: widget.heroMap),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hero.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (hero.roles.isNotEmpty)
              Text(
                hero.roles.join(' · '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Contenido activo ──────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: pages[_currentIndex],
            ),
          ),

          // ── Bottom bar flotante ───────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.12,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: SalomonBottomBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  selectedItemColor: colorScheme.primary,
                  unselectedItemColor: colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                  items: [
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.person_outline),
                      title: const Text('Info'),
                      selectedColor: colorScheme.primary,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.bar_chart),
                      title: const Text('Stats'),
                      selectedColor: colorScheme.primary,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.build_outlined),
                      title: const Text('Builds'),
                      selectedColor: colorScheme.primary,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.compare_arrows),
                      title: const Text('Counters'),
                      selectedColor: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Info ─────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.hero});
  final HeroDetail hero;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (hero.roles.isNotEmpty || hero.lane.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hero.roles.isNotEmpty)
                Expanded(
                  child: _ChipGroup(
                    label: 'Rol',
                    items: hero.roles,
                    color: colorScheme.primary,
                  ),
                ),
              if (hero.lane.isNotEmpty)
                Expanded(
                  child: _ChipGroup(
                    label: 'Lane',
                    items: [hero.lane],
                    color: colorScheme.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (hero.specialties.isNotEmpty) ...[
          _ChipGroup(
            label: 'Especialidades',
            items: hero.specialties,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
        ],
        if (hero.story.isNotEmpty) ...[
          _SectionTitle(title: 'Historia', icon: Icons.auto_stories),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              hero.story,
              style: const TextStyle(height: 1.6, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (hero.skills.isNotEmpty) ...[
          _SectionTitle(title: 'Habilidades', icon: Icons.flash_on),
          const SizedBox(height: 12),
          ...hero.skills.map((s) => _SkillCard(skill: s)),
        ],
      ],
    );
  }
}

// ── Tab: Stats ────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats});
  final List<HeroStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(child: Text('Sin estadísticas disponibles'));
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Variaciones del color primario usando opacidad
    final statColors = [
      colorScheme.primary,
      colorScheme.primary.withValues(alpha: 0.85),
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        _SectionTitle(title: 'Atributos del Héroe', icon: Icons.bar_chart),
        const SizedBox(height: 20),
        ...stats.asMap().entries.map((entry) {
          final color = statColors[entry.key % statColors.length];
          final stat = entry.value;
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stat.normalizedValue,
                    minHeight: 10,
                    backgroundColor: colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Tab: Builds ───────────────────────────────────────────────────
class _BuildsTab extends StatelessWidget {
  const _BuildsTab({required this.builds});
  final List<HeroBuild> builds;

  @override
  Widget build(BuildContext context) {
    if (builds.isEmpty) {
      return const Center(child: Text('Sin builds disponibles'));
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: builds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _BuildCard(heroBuild: builds[i], index: i),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({required this.heroBuild, required this.index});
  final HeroBuild heroBuild;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winPct = (heroBuild.winRate * 100).toStringAsFixed(1);
    final pickPct = (heroBuild.pickRate * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            children: [
              Text(
                'Build ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              _StatPill('WR $winPct%', colorScheme.primary),
              const SizedBox(width: 6),
              _StatPill('Pick $pickPct%', colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 14),

          // Ítems
          Text(
            'Ítems',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (heroBuild.items.isNotEmpty)
                ...heroBuild.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ItemIcon(item: item),
                  ),
                )
              else
                ...heroBuild.equipIds.map(
                  (id) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ItemIconPlaceholder(id: id),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Hechizo & Emblema
          Text(
            'Hechizo & Emblema',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
              const SizedBox(width: 12),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
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
            width: 48,
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          '$id',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
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
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(
              iconUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.flash_on, size: 28, color: colorScheme.primary),
            ),
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
            ? colorScheme.surface
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.star, color: colorScheme.primary),
              ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
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

class _StatPill extends StatelessWidget {
  const _StatPill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── Tab: Counters ─────────────────────────────────────────────────
class _CountersTab extends StatelessWidget {
  const _CountersTab({required this.relation, required this.heroMap});
  final HeroRelation? relation;
  final Map<int, MlbbHero> heroMap;

  @override
  Widget build(BuildContext context) {
    if (relation == null) {
      return const Center(child: Text('Sin datos de counters'));
    }
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (relation!.strongAgainst.isNotEmpty) ...[
          _CounterSection(
            title: 'Fuerte contra',
            icon: Icons.arrow_upward,
            sectionType: _CounterType.strong,
            ids: relation!.strongAgainst,
            heroMap: heroMap,
          ),
          const SizedBox(height: 20),
        ],
        if (relation!.weakAgainst.isNotEmpty) ...[
          _CounterSection(
            title: 'Débil contra',
            icon: Icons.arrow_downward,
            sectionType: _CounterType.weak,
            ids: relation!.weakAgainst,
            heroMap: heroMap,
          ),
          const SizedBox(height: 20),
        ],
        if (relation!.bestWith.isNotEmpty)
          _CounterSection(
            title: 'Mejores compañeros',
            icon: Icons.people,
            sectionType: _CounterType.ally,
            ids: relation!.bestWith,
            heroMap: heroMap,
          ),
      ],
    );
  }
}

enum _CounterType { strong, weak, ally }

class _CounterSection extends StatelessWidget {
  const _CounterSection({
    required this.title,
    required this.icon,
    required this.sectionType,
    required this.ids,
    required this.heroMap,
  });
  final String title;
  final IconData icon;
  final _CounterType sectionType;
  final List<int> ids;
  final Map<int, MlbbHero> heroMap;

  // Colores semánticos usando el tema
  Color _sectionColor(ColorScheme cs) {
    switch (sectionType) {
      case _CounterType.strong:
        return cs.primary;
      case _CounterType.weak:
        return cs.error;
      case _CounterType.ally:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _sectionColor(colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ids.map((id) {
            final hero = heroMap[id];
            return SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: hero?.iconUrl.isNotEmpty == true
                          ? Image.network(
                              hero!.iconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _HeroPlaceholder(color: color),
                            )
                          : _HeroPlaceholder(color: color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hero?.name ?? 'ID $id',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.sports_esports, color: color),
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.items,
    required this.color,
  });
  final String label;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: items
              .map(
                (r) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill});
  final HeroSkill skill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (skill.iconUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                skill.iconUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.flash_on, size: 48, color: colorScheme.primary),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (skill.cooldownAndCost.isNotEmpty)
                      Flexible(
                        child: Text(
                          skill.cooldownAndCost,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
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
