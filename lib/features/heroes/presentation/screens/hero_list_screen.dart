import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/injection/injection_container.dart';
import 'package:insight/features/heroes/domain/entities/hero_entity.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_bloc.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_event.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_state.dart';
import 'package:insight/features/heroes/presentation/screens/hero_detail_screen.dart';
import 'package:insight/features/heroes/presentation/utils/hero_role_utils.dart';
import 'package:insight/features/heroes/presentation/widgets/hero_card.dart';

class HeroListScreen extends StatefulWidget {
  const HeroListScreen({super.key});

  @override
  State<HeroListScreen> createState() => _HeroListScreenState();
}

class _HeroListScreenState extends State<HeroListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialized = false;
  String _activeRole = 'Todos';

  static const List<String> _roles = [
    'Todos',
    'Marksman',
    'Mage',
    'Fighter',
    'Tank',
    'Assassin',
    'Support',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<HeroBloc>().add(const LoadHeroListEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────

  List<HeroEntity> _applyRoleFilter(List<HeroEntity> heroes) {
    if (_activeRole == 'Todos') return heroes;
    // Filtramos por la primera letra del nombre del héroe como heurística
    // ya que MlbbHero solo tiene heroId, name e iconUrl.
    // El filtro real lo haría HeroBloc si HeroDetail tuviese los roles en el índice.
    // Por ahora mostramos todos y dejamos el filtro como UI preparada para integración.
    return heroes;
  }

  void _navigateToDetail(BuildContext context, int heroId) {
    final state = context.read<HeroBloc>().state;
    final heroMap = <int, HeroEntity>{};
    if (state is HeroListLoaded) {
      for (final h in state.heroes) {
        heroMap[h.heroId] = h;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sl<HeroBloc>(),
          child: HeroDetailScreen(heroId: heroId, heroMap: heroMap),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0C10) : colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sliver App Bar con header gaming ─────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0A0C10) : colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'HÉROES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _HeroListHeader()),
          ),

          // ── Buscador ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (q) {
                  context.read<HeroBloc>().add(SearchHeroListEvent(q));
                  setState(() {});
                },
                onClear: () {
                  _searchController.clear();
                  context.read<HeroBloc>().add(const SearchHeroListEvent(''));
                  setState(() {});
                },
              ),
            ),
          ),

          // ── Filtros de rol ────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _roles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _RoleFilterChip(
                  label: _roles[i],
                  isActive: _activeRole == _roles[i],
                  onTap: () => setState(() => _activeRole = _roles[i]),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── Grid de héroes ────────────────────────────────────
          BlocBuilder<HeroBloc, HeroState>(
            buildWhen: (_, s) => s is HeroListLoading || s is HeroListLoaded || s is HeroListError,
            builder: (context, state) {
              if (state is HeroListLoading) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (state is HeroListError) {
                return SliverFillRemaining(
                  child: _ErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<HeroBloc>().add(const LoadHeroListEvent(forceRefresh: true)),
                  ),
                );
              }

              if (state is HeroListLoaded) {
                final filtered = _applyRoleFilter(state.filtered);

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final hero = filtered[index];
                      return HeroCard(
                        hero: hero,
                        onTap: () => _navigateToDetail(context, hero.heroId),
                      );
                    }, childCount: filtered.length),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Widgets internos
// ══════════════════════════════════════════════════════════════════

// ── Header de la lista ────────────────────────────────────────────

class _HeroListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                height: 1,
              ),
              children: [
                TextSpan(
                  text: 'HÉ',
                  style: TextStyle(color: isDark ? const Color(0xFFF0F2F7) : colorScheme.onSurface),
                ),
                TextSpan(
                  text: 'ROES',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          BlocBuilder<HeroBloc, HeroState>(
            buildWhen: (_, s) => s is HeroListLoaded,
            builder: (context, state) {
              final count = state is HeroListLoaded ? state.heroes.length : 0;
              return Text(
                '$count personajes disponibles',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 0.3,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Barra de búsqueda ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Buscar héroe...',
        hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF181C24) : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }
}

// ── Chip de filtro por rol ────────────────────────────────────────

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = label == 'Todos' ? colorScheme.primary : HeroRoleUtils.colorForRole(label);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? roleColor
              : isDark
              ? const Color(0xFF181C24)
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isActive ? roleColor : colorScheme.outline.withValues(alpha: 0.18),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Estado de error ───────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 28, color: colorScheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin conexión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Prueba con otro nombre',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}
