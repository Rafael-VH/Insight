import 'package:equatable/equatable.dart';

/// Eventos base para el sistema de navegación
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Seleccionar un item de navegación por índice
class NavigationItemSelected extends NavigationEvent {
  final int index;

  const NavigationItemSelected(this.index);

  @override
  List<Object> get props => [index];

  @override
  String toString() => 'NavigationItemSelected(index: $index)';
}

/// Evento: Resetear navegación al estado inicial (índice 0)
class NavigationReset extends NavigationEvent {
  const NavigationReset();

  @override
  String toString() => 'NavigationReset()';
}

/// Evento: Navegar a un destino por ID
class NavigateToDestination extends NavigationEvent {
  final String destinationId;

  const NavigateToDestination(this.destinationId);

  @override
  List<Object> get props => [destinationId];

  @override
  String toString() => 'NavigateToDestination(id: $destinationId)';
}

/// Evento: Navegar hacia atrás
class NavigateBack extends NavigationEvent {
  const NavigateBack();

  @override
  String toString() => 'NavigateBack()';
}

/// Evento: Actualizar badge de un item
class UpdateNavigationBadge extends NavigationEvent {
  final int index;
  final String? badge;

  const UpdateNavigationBadge({required this.index, this.badge});

  @override
  List<Object?> get props => [index, badge];

  @override
  String toString() => 'UpdateNavigationBadge(index: $index, badge: $badge)';
}
