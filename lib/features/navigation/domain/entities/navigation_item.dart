import 'package:flutter/material.dart';

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

  /// Sección opcional para agrupar destinos en el drawer
  final String? section;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
    this.id,
    this.badge,
    this.section,
  });

  /// Crea una copia del NavigationItem con campos actualizados
  NavigationItem copyWith({
    String? title,
    IconData? icon,
    Color? color,
    Widget? page,
    String? id,
    String? badge,
    String? section,
  }) {
    return NavigationItem(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      page: page ?? this.page,
      id: id ?? this.id,
      badge: badge ?? this.badge,
      section: section ?? this.section,
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
        other.badge == badge &&
        other.section == section;
  }

  @override
  int get hashCode =>
      title.hashCode ^
      icon.hashCode ^
      color.hashCode ^
      id.hashCode ^
      badge.hashCode ^
      section.hashCode;

  @override
  String toString() => 'NavigationItem(title: $title, id: $id, section: $section)';
}
