import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/injection/injection_container.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_bloc.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_event.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_state.dart';
import 'package:insight/features/heroes/presentation/screens/hero_detail_screen.dart';
import 'package:insight/features/heroes/presentation/widgets/hero_card.dart';
import 'package:insight/features/stats/presentation/widgets/app_sliver_bar.dart';

class HeroListScreen extends StatefulWidget {
  const HeroListScreen({super.key});

  @override
  State<HeroListScreen> createState() => _HeroListScreenState();
}

class _HeroListScreenState extends State<HeroListScreen> {
  final _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lanzar la carga una sola vez, de forma segura tras el primer build.
    if (!_initialized) {
      _initialized = true;
      context.read<HeroBloc>().add(const LoadHeroListEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, int heroId) {
    final state = context.read<HeroBloc>().state;
    final heroMap = <int, MlbbHero>{};

    if (state is HeroListLoaded) {
      for (final h in state.heroes) {
        heroMap[h.heroId] = h;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          // Reutiliza el mismo Singleton — el detalle se carga sobre el
          // estado de lista existente sin crear una nueva instancia.
          value: sl<HeroBloc>(),
          child: HeroDetailScreen(heroId: heroId, heroMap: heroMap),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverBar(
            title: 'Héroes',
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            icon: Icons.sports_esports,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (q) =>
                    context.read<HeroBloc>().add(SearchHeroListEvent(q)),
                decoration: InputDecoration(
                  hintText: 'Buscar héroe...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<HeroBloc>().add(
                              const SearchHeroListEvent(''),
                            );
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),
          ),
          // buildWhen evita rebuilds cuando el BLoC emite estados de detalle.
          BlocBuilder<HeroBloc, HeroState>(
            buildWhen: (_, s) =>
                s is HeroListLoading ||
                s is HeroListLoaded ||
                s is HeroListError,
            builder: (context, state) {
              if (state is HeroListLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is HeroListError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<HeroBloc>().add(
                            const LoadHeroListEvent(forceRefresh: true),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is HeroListLoaded) {
                if (state.filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No se encontraron héroes')),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final hero = state.filtered[index];
                      return HeroCard(
                        hero: hero,
                        onTap: () => _navigateToDetail(context, hero.heroId),
                      );
                    }, childCount: state.filtered.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
