import 'package:equatable/equatable.dart';

abstract class HeroEvent extends Equatable {
  const HeroEvent();
  @override
  List<Object?> get props => [];
}

class LoadHeroesEvent extends HeroEvent {}

class SearchHeroesEvent extends HeroEvent {
  final String query;
  const SearchHeroesEvent(this.query);
  @override
  List<Object> get props => [query];
}

class LoadHeroDetailEvent extends HeroEvent {
  final int heroId;
  const LoadHeroDetailEvent(this.heroId);
  @override
  List<Object> get props => [heroId];
}
