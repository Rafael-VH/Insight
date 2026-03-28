import 'package:equatable/equatable.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';

abstract class HeroState extends Equatable {
  const HeroState();

  @override
  List<Object?> get props => [];
}

// ── Compartido ────────────────────────────────────────────────────

/// Estado inicial antes de cualquier evento.
class HeroInitial extends HeroState {}

// ── Lista ─────────────────────────────────────────────────────────

/// Cargando el listado de héroes.
class HeroListLoading extends HeroState {}

/// Listado cargado correctamente.
/// [heroes] es la lista completa; [filtered] es la vista actual tras búsqueda.
class HeroListLoaded extends HeroState {
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

/// Error al cargar el listado de héroes.
class HeroListError extends HeroState {
  final String message;

  const HeroListError(this.message);

  @override
  List<Object> get props => [message];
}

// ── Detalle ───────────────────────────────────────────────────────

/// Cargando el detalle de un héroe.
class HeroDetailLoading extends HeroState {}

/// Detalle de héroe cargado correctamente.
class HeroDetailLoaded extends HeroState {
  final HeroDetail detail;

  const HeroDetailLoaded(this.detail);

  @override
  List<Object> get props => [detail];
}

/// Error al cargar el detalle de un héroe.
class HeroDetailError extends HeroState {
  final String message;

  const HeroDetailError(this.message);

  @override
  List<Object> get props => [message];
}
