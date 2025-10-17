import 'package:flutter/material.dart';

/// Entidad que representa un item del Bottom Navigation Bar
class NavigationItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });
}
