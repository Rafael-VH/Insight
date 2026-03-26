import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/usecases/get_hero_detail.dart';
import 'package:insight/features/heroes/domain/usecases/get_heroes.dart';
import 'hero_event.dart';
import 'hero_state.dart';

class HeroBloc extends Bloc<HeroEvent, HeroState> {
  final GetHeroes getHeroes;
  final GetHeroDetail getHeroDetail;

  HeroBloc({required this.getHeroes, required this.getHeroDetail})
    : super(HeroInitial()) {
    on<LoadHeroesEvent>(_onLoadHeroes);
    on<SearchHeroesEvent>(_onSearchHeroes);
    on<LoadHeroDetailEvent>(_onLoadHeroDetail);
  }

  Future<void> _onLoadHeroes(
    LoadHeroesEvent event,
    Emitter<HeroState> emit,
  ) async {
    emit(HeroLoading());
    final result = await getHeroes();
    result.fold(
      (failure) => emit(HeroError(failure.message)),
      (heroes) => emit(HeroesLoaded(heroes: heroes, filtered: heroes)),
    );
  }

  void _onSearchHeroes(SearchHeroesEvent event, Emitter<HeroState> emit) {
    if (state is! HeroesLoaded) return;
    final current = state as HeroesLoaded;
    final query = event.query.toLowerCase().trim();

    final List<MlbbHero> filtered = query.isEmpty
        ? current.heroes
        : current.heroes
              .where((h) => h.name.toLowerCase().contains(query))
              .toList();

    emit(current.copyWith(filtered: filtered, searchQuery: event.query));
  }

  Future<void> _onLoadHeroDetail(
    LoadHeroDetailEvent event,
    Emitter<HeroState> emit,
  ) async {
    emit(HeroLoading());
    final result = await getHeroDetail(event.heroId);
    result.fold(
      (failure) => emit(HeroError(failure.message)),
      (detail) => emit(HeroDetailLoaded(detail)),
    );
  }
}
