import 'package:flutter/material.dart';
import 'package:insight/stats/domain/entities/game_mode.dart';

/// Extensions para GameMode para centralizar la lógica de UI
extension GameModeUI on GameMode {
  /// Color representativo del modo de juego
  Color get color {
    switch (this) {
      case GameMode.total:
        return const Color(0xFF059669);
      case GameMode.ranked:
        return const Color(0xFFDC2626);
      case GameMode.classic:
        return const Color(0xFF2563EB);
      case GameMode.brawl:
        return const Color(0xFF7C3AED);
    }
  }

  /// Icono representativo del modo de juego
  IconData get icon {
    switch (this) {
      case GameMode.total:
        return Icons.dashboard;
      case GameMode.ranked:
        return Icons.military_tech;
      case GameMode.classic:
        return Icons.games;
      case GameMode.brawl:
        return Icons.sports_mma;
    }
  }

  /// Nombre corto para mostrar en chips y etiquetas
  String get shortName {
    switch (this) {
      case GameMode.total:
        return 'Total';
      case GameMode.ranked:
        return 'Ranked';
      case GameMode.classic:
        return 'Classic';
      case GameMode.brawl:
        return 'Brawl';
    }
  }

  /// Nombre completo para títulos de pantallas
  String get fullDisplayName {
    switch (this) {
      case GameMode.total:
        return 'Estadísticas Totales';
      case GameMode.ranked:
        return 'Clasificatoria';
      case GameMode.classic:
        return 'Clásica';
      case GameMode.brawl:
        return 'Coliseo';
    }
  }
}
