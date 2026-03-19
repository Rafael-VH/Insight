import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_state.dart';

/// BLoC que gestiona el estado de navegación de la aplicación
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final int totalDestinations;

  final List<int> _history = [0];
  final Map<int, String?> _badges = {};

  NavigationBloc({this.totalDestinations = 3})
    : super(const NavigationInitial()) {
    on<NavigationItemSelected>(_onNavigationItemSelected);
    on<NavigationReset>(_onNavigationReset);
    on<NavigateBack>(_onNavigateBack);
    on<UpdateNavigationBadge>(_onUpdateNavigationBadge);
  }

  void _onNavigationItemSelected(
    NavigationItemSelected event,
    Emitter<NavigationState> emit,
  ) {
    if (event.index < 0 || event.index >= totalDestinations) {
      emit(
        NavigationError(
          currentIndex: state.currentIndex,
          message: 'Índice de navegación inválido: ${event.index}',
          errorDetails:
              'El índice debe estar entre 0 y ${totalDestinations - 1}',
        ),
      );
      return;
    }

    if (event.index == state.currentIndex) {
      return;
    }

    final previousIndex = state.currentIndex;

    if (_history.isEmpty || _history.last != event.index) {
      _history.add(event.index);

      if (_history.length > 10) {
        _history.removeAt(0);
      }
    }

    emit(NavigationChanged(event.index, previousIndex: previousIndex));
  }

  void _onNavigationReset(
    NavigationReset event,
    Emitter<NavigationState> emit,
  ) {
    _history.clear();
    _history.add(0);
    _badges.clear();

    emit(const NavigationInitial());
  }

  void _onNavigateBack(NavigateBack event, Emitter<NavigationState> emit) {
    if (_history.length > 1) {
      _history.removeLast();
      final previousIndex = _history.last;

      emit(NavigationChanged(previousIndex, previousIndex: state.currentIndex));
    } else {
      emit(const NavigationInitial());
    }
  }

  void _onUpdateNavigationBadge(
    UpdateNavigationBadge event,
    Emitter<NavigationState> emit,
  ) {
    if (event.index < 0 || event.index >= totalDestinations) {
      emit(
        NavigationError(
          currentIndex: state.currentIndex,
          message: 'Índice de badge inválido: ${event.index}',
        ),
      );
      return;
    }

    _badges[event.index] = event.badge;

    emit(
      NavigationBadgeUpdated(
        currentIndex: state.currentIndex,
        updatedItemIndex: event.index,
        badge: event.badge,
      ),
    );

    emit(NavigationChanged(state.currentIndex));
  }

  int get currentIndex => state.currentIndex;
  List<int> get history => List.unmodifiable(_history);
  String? getBadge(int index) => _badges[index];
  bool get canGoBack => _history.length > 1;

  @override
  Future<void> close() {
    _history.clear();
    _badges.clear();
    return super.close();
  }
}
