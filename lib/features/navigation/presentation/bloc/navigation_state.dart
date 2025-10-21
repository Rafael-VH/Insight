import 'package:equatable/equatable.dart';

/// Estados base para el sistema de navegación
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];

  /// Índice actual de navegación (útil para acceso rápido)
  int get currentIndex => 0;
}

/// Estado: Navegación inicial
class NavigationInitial extends NavigationState {
  @override
  final int currentIndex;

  const NavigationInitial({this.currentIndex = 0});

  @override
  List<Object> get props => [currentIndex];

  @override
  String toString() => 'NavigationInitial(index: $currentIndex)';
}

/// Estado: Navegación cambiada
class NavigationChanged extends NavigationState {
  @override
  final int currentIndex;

  /// Índice anterior (útil para animaciones)
  final int? previousIndex;

  /// Timestamp del cambio
  final DateTime timestamp;

  NavigationChanged(this.currentIndex, {this.previousIndex})
    : timestamp = DateTime.now();

  @override
  List<Object?> get props => [currentIndex, previousIndex, timestamp];

  @override
  String toString() =>
      'NavigationChanged(current: $currentIndex, previous: $previousIndex)';
}

/// Estado: Navegación en transición (útil para animaciones)
class NavigationTransitioning extends NavigationState {
  @override
  final int currentIndex;
  final int targetIndex;

  const NavigationTransitioning({
    required this.currentIndex,
    required this.targetIndex,
  });

  @override
  List<Object> get props => [currentIndex, targetIndex];

  @override
  String toString() =>
      'NavigationTransitioning(from: $currentIndex, to: $targetIndex)';
}

/// Estado: Badge actualizado
class NavigationBadgeUpdated extends NavigationState {
  @override
  final int currentIndex;
  final int updatedItemIndex;
  final String? badge;

  const NavigationBadgeUpdated({
    required this.currentIndex,
    required this.updatedItemIndex,
    this.badge,
  });

  @override
  List<Object?> get props => [currentIndex, updatedItemIndex, badge];

  @override
  String toString() =>
      'NavigationBadgeUpdated(item: $updatedItemIndex, badge: $badge)';
}

/// Estado: Error de navegación
class NavigationError extends NavigationState {
  @override
  final int currentIndex;
  final String message;
  final String? errorDetails;

  const NavigationError({
    required this.currentIndex,
    required this.message,
    this.errorDetails,
  });

  @override
  List<Object?> get props => [currentIndex, message, errorDetails];

  @override
  String toString() => 'NavigationError(message: $message)';
}
