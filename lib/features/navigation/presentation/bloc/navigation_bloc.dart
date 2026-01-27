// ignore_for_file: avoid_print

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_state.dart';

/// BLoC que gestiona el estado de navegación de la aplicación
///
/// Características:
/// - Cambio de pestañas con validación
/// - Historial de navegación
/// - Actualización de badges
/// - Reseteo de navegación
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  /// Número total de destinos de navegación
  final int totalDestinations;

  /// Historial de índices visitados (útil para navegación hacia atrás)
  final List<int> _history = [0];

  /// Badges actuales de cada destino
  final Map<int, String?> _badges = {};

  NavigationBloc({this.totalDestinations = 3})
    : super(const NavigationInitial()) {
    on<NavigationItemSelected>(_onNavigationItemSelected);
    on<NavigationReset>(_onNavigationReset);
    on<NavigateBack>(_onNavigateBack);
    on<UpdateNavigationBadge>(_onUpdateNavigationBadge);
  }

  // ==================== EVENT HANDLERS ====================

  /// Maneja la selección de un item de navegación
  void _onNavigationItemSelected(
    NavigationItemSelected event,
    Emitter<NavigationState> emit,
  ) {
    // Validar índice
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

    // No hacer nada si ya estamos en ese índice
    if (event.index == state.currentIndex) {
      return;
    }

    final previousIndex = state.currentIndex;

    // Agregar al historial
    if (_history.isEmpty || _history.last != event.index) {
      _history.add(event.index);

      // Limitar el historial a 10 entradas
      if (_history.length > 10) {
        _history.removeAt(0);
      }
    }

    // Emitir estado de cambio
    emit(NavigationChanged(event.index, previousIndex: previousIndex));
  }

  /// Resetea la navegación al estado inicial
  void _onNavigationReset(
    NavigationReset event,
    Emitter<NavigationState> emit,
  ) {
    _history.clear();
    _history.add(0);
    _badges.clear();

    emit(const NavigationInitial());
  }

  /// Navega hacia atrás en el historial
  void _onNavigateBack(NavigateBack event, Emitter<NavigationState> emit) {
    if (_history.length > 1) {
      _history.removeLast();
      final previousIndex = _history.last;

      emit(NavigationChanged(previousIndex, previousIndex: state.currentIndex));
    } else {
      // Si no hay historial, no hacer nada o ir a inicial
      emit(const NavigationInitial());
    }
  }

  /// Actualiza el badge de un destino
  void _onUpdateNavigationBadge(
    UpdateNavigationBadge event,
    Emitter<NavigationState> emit,
  ) {
    // Validar índice
    if (event.index < 0 || event.index >= totalDestinations) {
      emit(
        NavigationError(
          currentIndex: state.currentIndex,
          message: 'Índice de badge inválido: ${event.index}',
        ),
      );
      return;
    }

    // Actualizar badge
    _badges[event.index] = event.badge;

    emit(
      NavigationBadgeUpdated(
        currentIndex: state.currentIndex,
        updatedItemIndex: event.index,
        badge: event.badge,
      ),
    );

    // Volver al estado actual después de notificar
    emit(NavigationChanged(state.currentIndex));
  }

  // ==================== GETTERS ====================

  /// Obtiene el índice actual de navegación
  int get currentIndex => state.currentIndex;

  /// Obtiene el historial de navegación
  List<int> get history => List.unmodifiable(_history);

  /// Obtiene el badge de un destino específico
  String? getBadge(int index) => _badges[index];

  /// Verifica si se puede navegar hacia atrás
  bool get canGoBack => _history.length > 1;

  // ==================== DEBUG ====================

  @override
  void onEvent(NavigationEvent event) {
    super.onEvent(event);
    print('🧭 [NavigationBloc] Event: $event');
  }

  @override
  void onTransition(Transition<NavigationEvent, NavigationState> transition) {
    super.onTransition(transition);
    print(
      '🧭 [NavigationBloc] Transition: ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('❌ [NavigationBloc] Error: $error');
    super.onError(error, stackTrace);
  }

  @override
  Future<void> close() {
    _history.clear();
    _badges.clear();
    return super.close();
  }
}
