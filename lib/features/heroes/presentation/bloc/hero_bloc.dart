import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/heroes/domain/usecases/get_hero_detail.dart';
import 'package:insight/features/heroes/domain/usecases/get_heroes.dart';

import 'hero_event.dart';
import 'hero_state.dart';

/// BLoC unificado del módulo Heroes.
///
/// Gestiona dos flujos independientes dentro del mismo BLoC:
///
/// **Flujo de lista**
///   [LoadHeroListEvent] → [HeroListLoading] → [HeroListLoaded] | [HeroListError]
///   [SearchHeroListEvent] → filtra [HeroListLoaded.filtered] sin petición de red.
///
/// **Flujo de detalle**
///   [LoadHeroDetailEvent] → [HeroDetailLoading] → [HeroDetailLoaded] | [HeroDetailError]
///
/// Ambos flujos emiten sus propios estados concretos, por lo que los widgets
/// pueden usar `BlocBuilder` con `buildWhen` para reaccionar solo a los estados
/// que les conciernen y evitar rebuilds innecesarios.
class HeroBloc extends Bloc<HeroEvent, HeroState> {
  final GetHeroes getHeroes;
  final GetHeroDetail getHeroDetail;

  HeroBloc({required this.getHeroes, required this.getHeroDetail}) : super(HeroInitial()) {
    on<LoadHeroListEvent>(_onLoadList);
    on<SearchHeroListEvent>(_onSearch);
    on<LoadHeroDetailEvent>(_onLoadDetail);
  }

  // ── Lista ───────────────────────────────────────────────────────

  Future<void> _onLoadList(LoadHeroListEvent event, Emitter<HeroState> emit) async {
    // Evitar recargas innecesarias salvo que se pida explícitamente.
    if (state is HeroListLoaded && !event.forceRefresh) return;

    emit(HeroListLoading());

    final result = await getHeroes();

    result.fold((failure) => emit(HeroListError(failure.message)), (heroes) {
      if (heroes.isEmpty) {
        emit(const HeroListError('No se encontraron héroes. Verifica tu conexión.'));
        return;
      }
      emit(HeroListLoaded(heroes: heroes, filtered: heroes));
    });
  }

  void _onSearch(SearchHeroListEvent event, Emitter<HeroState> emit) {
    // Solo filtra si ya hay datos cargados.
    if (state is! HeroListLoaded) return;

    final current = state as HeroListLoaded;
    final query = event.query.toLowerCase().trim();

    final filtered = query.isEmpty
        ? current.heroes
        : current.heroes.where((h) => h.name.toLowerCase().contains(query)).toList();

    emit(current.copyWith(filtered: filtered, searchQuery: event.query));
  }

  // ── Detalle ─────────────────────────────────────────────────────

  Future<void> _onLoadDetail(LoadHeroDetailEvent event, Emitter<HeroState> emit) async {
    emit(HeroDetailLoading());

    final result = await getHeroDetail(event.heroId);

    result.fold(
      (failure) => emit(HeroDetailError(failure.message)),
      (detail) => emit(HeroDetailLoaded(detail)),
    );
  }
}
