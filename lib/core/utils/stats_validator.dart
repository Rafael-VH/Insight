import 'package:insight/stats/domain/entities/player_stats.dart';

/// Resultado de la validación de estadísticas
class ValidationResult {
  final bool isValid;
  final List<String> missingFields;
  final List<String> warningFields;
  final int totalFields;
  final int validFields;

  const ValidationResult({
    required this.isValid,
    required this.missingFields,
    required this.warningFields,
    required this.totalFields,
    required this.validFields,
  });

  double get completionPercentage => (validFields / totalFields) * 100;

  String get summary {
    if (isValid && warningFields.isEmpty) {
      return '✓ Todos los datos extraídos correctamente';
    } else if (missingFields.isEmpty && warningFields.isNotEmpty) {
      return '⚠ Datos extraídos con advertencias (${warningFields.length} campos)';
    } else {
      return '✗ Faltan ${missingFields.length} campos importantes';
    }
  }
}

/// Validador de estadísticas
class StatsValidator {
  /// Valida las estadísticas extraídas
  static ValidationResult validate(PlayerStats stats) {
    final List<String> missingFields = [];
    final List<String> warningFields = [];
    int totalFields = 0;
    int validFields = 0;

    // Validar estadísticas principales (CRÍTICAS)
    totalFields += 3;
    if (stats.totalGames == 0) {
      missingFields.add('Partidas Totales');
    } else {
      validFields++;
    }

    if (stats.winRate == 0.0) {
      missingFields.add('Tasa de Victorias');
    } else {
      validFields++;
    }

    if (stats.mvpCount == 0) {
      warningFields.add('MVP (puede ser legítimamente 0)');
      validFields++; // No es crítico
    } else {
      validFields++;
    }

    // Validar estadísticas de rendimiento (IMPORTANTES)
    totalFields += 6;
    if (stats.kda == 0.0) {
      missingFields.add('KDA');
    } else {
      validFields++;
    }

    if (stats.teamFightParticipation == 0.0) {
      missingFields.add('Participación en Equipo');
    } else {
      validFields++;
    }

    if (stats.goldPerMin == 0) {
      missingFields.add('Oro/Min');
    } else {
      validFields++;
    }

    if (stats.heroDamagePerMin == 0) {
      missingFields.add('DAÑO a Héroe/Min');
    } else {
      validFields++;
    }

    if (stats.deathsPerGame == 0.0) {
      warningFields.add('Muertes/Partida');
      validFields++;
    } else {
      validFields++;
    }

    if (stats.towerDamagePerGame == 0) {
      warningFields.add('Daño a Torre/Partida');
      validFields++;
    } else {
      validFields++;
    }

    // Validar logros (OPCIONALES - pueden ser 0 legítimamente)
    totalFields += 13;
    final achievements = [
      ('Legendario', stats.legendary),
      ('Savage', stats.savage),
      ('Maniac', stats.maniac),
      ('Asesinato Triple', stats.tripleKill),
      ('Asesinato Doble', stats.doubleKill),
      ('MVP Perdedor', stats.mvpLoss),
      ('Asesinatos Máx.', stats.maxKills),
      ('Asistencias Máx.', stats.maxAssists),
      ('Racha de Victorias Máx.', stats.maxWinningStreak),
      ('Primera Sangre', stats.firstBlood),
      ('Daño Causado Máx./min', stats.maxDamageDealt),
      ('Daño Tomado Máx./min', stats.maxDamageTaken),
      ('Oro Máx./min', stats.maxGold),
    ];

    for (var achievement in achievements) {
      if (achievement.$2 == 0) {
        // Los logros pueden ser 0, pero vale la pena notarlo
        warningFields.add(achievement.$1);
      }
      validFields++; // Siempre contamos como válido
    }

    // Un perfil es válido si tiene al menos las estadísticas críticas
    final isValid = missingFields.isEmpty;

    return ValidationResult(
      isValid: isValid,
      missingFields: missingFields,
      warningFields: warningFields,
      totalFields: totalFields,
      validFields: validFields,
    );
  }

  /// Genera un mensaje detallado de error
  static String getDetailedErrorMessage(ValidationResult result) {
    final buffer = StringBuffer();

    if (result.missingFields.isNotEmpty) {
      buffer.writeln('❌ DATOS FALTANTES (${result.missingFields.length}):');
      for (var field in result.missingFields) {
        buffer.writeln('  • $field');
      }
    }

    if (result.warningFields.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('⚠️ ADVERTENCIAS (${result.warningFields.length}):');
      buffer.writeln('Los siguientes campos están en 0:');
      for (var field in result.warningFields.take(5)) {
        // Mostrar solo los primeros 5
        buffer.writeln('  • $field');
      }
      if (result.warningFields.length > 5) {
        buffer.writeln('  ... y ${result.warningFields.length - 5} más');
      }
    }

    buffer.writeln();
    buffer.writeln(
      '📊 Completitud: ${result.completionPercentage.toStringAsFixed(1)}%',
    );

    return buffer.toString();
  }

  /// Genera recomendaciones para mejorar la captura
  static List<String> getRecommendations(ValidationResult result) {
    final recommendations = <String>[];

    if (result.missingFields.isNotEmpty) {
      recommendations.add(
        '📸 Asegúrate de que la imagen muestre claramente todas las estadísticas',
      );
      recommendations.add(
        '💡 Intenta tomar la captura con buena iluminación y sin reflejos',
      );
      recommendations.add(
        '🔍 Verifica que el texto sea legible y no esté borroso',
      );
    }

    if (result.completionPercentage < 50) {
      recommendations.add(
        '⚠️ Se detectaron muy pocos datos. Considera volver a tomar la captura',
      );
    }

    return recommendations;
  }
}
