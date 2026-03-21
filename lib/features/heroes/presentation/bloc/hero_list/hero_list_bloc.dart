import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/usecases/get_heroes.dart';

// ── Eventos ──────────────────────────────────────────────────────
abstract class HeroListEvent extends Equatable {
  const HeroListEvent();
  @override
  List<Object?> get props => [];
}

class LoadHeroListEvent extends HeroListEvent {}

class SearchHeroListEvent extends HeroListEvent {
  final String query;
  const SearchHeroListEvent(this.query);
  @override
  List<Object> get props => [query];
}

// ── Estados ───────────────────────────────────────────────────────
abstract class HeroListState extends Equatable {
  const HeroListState();
  @override
  List<Object?> get props => [];
}

class HeroListInitial extends HeroListState {}

class HeroListLoading extends HeroListState {}

class HeroListLoaded extends HeroListState {
  final List<MlbbHero> heroes;
  final List<MlbbHero> filtered;
  final String searchQuery;

  const HeroListLoaded({
    required this.heroes,
    required this.filtered,
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [heroes, filtered, searchQuery];

  HeroListLoaded copyWith({
    List<MlbbHero>? heroes,
    List<MlbbHero>? filtered,
    String? searchQuery,
  }) {
    return HeroListLoaded(
      heroes: heroes ?? this.heroes,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class HeroListError extends HeroListState {
  final String message;
  const HeroListError(this.message);
  @override
  List<Object> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────
class HeroListBloc extends Bloc<HeroListEvent, HeroListState> {
  final GetHeroes getHeroes;

  HeroListBloc({required this.getHeroes}) : super(HeroListInitial()) {
    on<LoadHeroListEvent>(_onLoad);
    on<SearchHeroListEvent>(_onSearch);
  }

  Future<void> _onLoad(
    LoadHeroListEvent event,
    Emitter<HeroListState> emit,
  ) async {
    // Si ya está cargado no volver a cargar
    if (state is HeroListLoaded) return;

    emit(HeroListLoading());
    final result = await getHeroes();
    result.fold(
      (failure) => emit(HeroListError(failure.message)),
      (heroes) => emit(HeroListLoaded(heroes: heroes, filtered: heroes)),
    );
  }

  void _onSearch(SearchHeroListEvent event, Emitter<HeroListState> emit) {
    if (state is! HeroListLoaded) return;
    final current = state as HeroListLoaded;
    final query = event.query.toLowerCase().trim();

    final List<MlbbHero> filtered = query.isEmpty
        ? current.heroes
        : current.heroes
              .where((h) => h.name.toLowerCase().contains(query))
              .toList();

    emit(current.copyWith(filtered: filtered, searchQuery: event.query));
  }
}
