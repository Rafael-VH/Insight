import 'package:equatable/equatable.dart';

abstract class HeroEvent extends Equatable {
  const HeroEvent();

  @override
  List<Object?> get props => [];
}

// ── Lista ─────────────────────────────────────────────────────────

/// Carga el listado completo de héroes.
/// [forceRefresh] omite el guard de caché en memoria y fuerza una nueva
/// petición — útil cuando el usuario pulsa "Reintentar" o navega de vuelta.
class LoadHeroListEvent extends HeroEvent {
  final bool forceRefresh;

  const LoadHeroListEvent({this.forceRefresh = false});

  @override
  List<Object> get props => [forceRefresh];
}

/// Filtra la lista cargada por [query] sin hacer una nueva petición de red.
class SearchHeroListEvent extends HeroEvent {
  final String query;

  const SearchHeroListEvent(this.query);

  @override
  List<Object> get props => [query];
}

// ── Detalle ───────────────────────────────────────────────────────

/// Carga el detalle completo de un héroe por su [heroId].
class LoadHeroDetailEvent extends HeroEvent {
  final int heroId;

  const LoadHeroDetailEvent(this.heroId);

  @override
  List<Object> get props => [heroId];
}
