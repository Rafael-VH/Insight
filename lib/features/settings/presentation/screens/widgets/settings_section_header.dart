import 'package:flutter/material.dart';

/// Encabezado de sección con texto en color primario del módulo settings.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
