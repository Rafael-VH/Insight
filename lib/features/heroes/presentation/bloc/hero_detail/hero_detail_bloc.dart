import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/usecases/get_hero_detail.dart';

// ── Eventos ──────────────────────────────────────────────────────
abstract class HeroDetailEvent extends Equatable {
  const HeroDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadHeroDetailEvent extends HeroDetailEvent {
  final int heroId;
  const LoadHeroDetailEvent(this.heroId);
  @override
  List<Object> get props => [heroId];
}

// ── Estados ───────────────────────────────────────────────────────
abstract class HeroDetailState extends Equatable {
  const HeroDetailState();
  @override
  List<Object?> get props => [];
}

class HeroDetailInitial extends HeroDetailState {}

class HeroDetailLoading extends HeroDetailState {}

class HeroDetailLoaded extends HeroDetailState {
  final HeroDetail detail;
  const HeroDetailLoaded(this.detail);
  @override
  List<Object> get props => [detail];
}

class HeroDetailError extends HeroDetailState {
  final String message;
  const HeroDetailError(this.message);
  @override
  List<Object> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────
class HeroDetailBloc extends Bloc<HeroDetailEvent, HeroDetailState> {
  final GetHeroDetail getHeroDetail;

  HeroDetailBloc({required this.getHeroDetail}) : super(HeroDetailInitial()) {
    on<LoadHeroDetailEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadHeroDetailEvent event,
    Emitter<HeroDetailState> emit,
  ) async {
    emit(HeroDetailLoading());
    final result = await getHeroDetail(event.heroId);
    result.fold(
      (failure) => emit(HeroDetailError(failure.message)),
      (detail) => emit(HeroDetailLoaded(detail)),
    );
  }
}
