import 'package:equatable/equatable.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';

abstract class HeroState extends Equatable {
  const HeroState();
  @override
  List<Object?> get props => [];
}

class HeroInitial extends HeroState {}

class HeroLoading extends HeroState {}

class HeroesLoaded extends HeroState {
  final List<MlbbHero> heroes;
  final List<MlbbHero> filtered;
  final String searchQuery;

  const HeroesLoaded({
    required this.heroes,
    required this.filtered,
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [heroes, filtered, searchQuery];

  HeroesLoaded copyWith({
    List<MlbbHero>? heroes,
    List<MlbbHero>? filtered,
    String? searchQuery,
  }) {
    return HeroesLoaded(
      heroes: heroes ?? this.heroes,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class HeroDetailLoaded extends HeroState {
  final HeroDetail detail;
  const HeroDetailLoaded(this.detail);
  @override
  List<Object> get props => [detail];
}

class HeroError extends HeroState {
  final String message;
  const HeroError(this.message);
  @override
  List<Object> get props => [message];
}
