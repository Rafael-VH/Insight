import 'package:flutter/material.dart';

/// Entidad que representa un item del sistema de navegación
///
/// Esta entidad encapsula toda la información necesaria para
/// renderizar y manejar un destino de navegación en la aplicación.
class NavigationItem {
  /// Título que se muestra en el navigation bar
  final String title;

  /// Icono que representa el destino
  final IconData icon;

  /// Color temático del destino
  final Color color;

  /// Widget de la página que se muestra al seleccionar este item
  final Widget page;

  /// Identificador único opcional
  final String? id;

  /// Badge opcional para mostrar notificaciones
  final String? badge;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
    this.id,
    this.badge,
  });

  /// Crea una copia del NavigationItem con campos actualizados
  NavigationItem copyWith({
    String? title,
    IconData? icon,
    Color? color,
    Widget? page,
    String? id,
    String? badge,
  }) {
    return NavigationItem(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      page: page ?? this.page,
      id: id ?? this.id,
      badge: badge ?? this.badge,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NavigationItem &&
        other.title == title &&
        other.icon == icon &&
        other.color == color &&
        other.id == id &&
        other.badge == badge;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        icon.hashCode ^
        color.hashCode ^
        id.hashCode ^
        badge.hashCode;
  }

  @override
  String toString() {
    return 'NavigationItem(title: $title, id: $id, badge: $badge)';
  }
}
