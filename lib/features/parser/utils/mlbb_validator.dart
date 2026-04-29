import 'package:insight/features/parser/domain/entities/player_performance.dart';

/// Resultado de la validación de estadísticas
class ValidationResult {
  final bool isValid;
  final List<String> missingFields;
  final List<String> warningFields;
  final int totalFields;
  final int validFields;
  final Map<String, dynamic> extractedValues;

  const ValidationResult({
    required this.isValid,
    required this.missingFields,
    required this.warningFields,
    required this.totalFields,
    required this.validFields,
    this.extractedValues = const {},
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
  static ValidationResult validate(PlayerPerformance stats) {
    final List<String> missingFields = [];
    final List<String> warningFields = [];
    final Map<String, dynamic> extractedValues = {}; // NUEVO
    int totalFields = 0;
    int validFields = 0;

    // Validar estadísticas principales (CRÍTICAS)
    totalFields += 3;
    if (stats.totalGames == 0) {
      missingFields.add('Partidas Totales');
    } else {
      validFields++;
      extractedValues['Partidas Totales'] = stats.totalGames;
    }

    if (stats.winRate == 0.0) {
      missingFields.add('Tasa de Victorias');
      // Agregar sugerencia específica
      extractedValues['Tasa de Victorias (sugerencia)'] =
          'Verifica que el porcentaje sea visible en la imagen';
    } else {
      validFields++;
      extractedValues['Tasa de Victorias'] = '${stats.winRate}%';
    }

    if (stats.mvpCount == 0) {
      warningFields.add('MVP (puede ser legítimamente 0)');
      validFields++; // No es crítico
    } else {
      validFields++;
      extractedValues['MVP'] = stats.mvpCount;
    }

    // Validar estadísticas de rendimiento (IMPORTANTES)
    totalFields += 6;
    if (stats.kda == 0.0) {
      missingFields.add('KDA');
    } else {
      validFields++;
      extractedValues['KDA'] = stats.kda;
    }

    if (stats.teamFightParticipation == 0.0) {
      missingFields.add('Participación en Equipo');
    } else {
      validFields++;
      extractedValues['Participación en Equipo'] = '${stats.teamFightParticipation}%';
    }

    if (stats.goldPerMin == 0) {
      missingFields.add('Oro/Min');
    } else {
      validFields++;
      extractedValues['Oro/Min'] = stats.goldPerMin;
    }

    if (stats.heroDamagePerMin == 0) {
      missingFields.add('DAÑO a Héroe/Min');
    } else {
      validFields++;
      extractedValues['DAÑO a Héroe/Min'] = stats.heroDamagePerMin;
    }

    if (stats.deathsPerGame == 0.0) {
      warningFields.add('Muertes/Partida');
      validFields++;
    } else {
      validFields++;
      extractedValues['Muertes/Partida'] = stats.deathsPerGame;
    }

    if (stats.towerDamagePerGame == 0) {
      warningFields.add('Daño a Torre/Partida');
      validFields++;
    } else {
      validFields++;
      extractedValues['Daño a Torre/Partida'] = stats.towerDamagePerGame;
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

        // Agregar sugerencia específica para Daño Causado
        if (achievement.$1 == 'Daño Causado Máx./min') {
          extractedValues['Daño Causado Máx./min (sugerencia)'] =
              'Este campo es importante. Verifica que el número sea visible en la imagen.';
        }
      } else {
        extractedValues[achievement.$1] = achievement.$2;
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
      extractedValues: extractedValues, // NUEVO
    );
  }

  /// Genera un mensaje detallado de error
  static String getDetailedErrorMessage(ValidationResult result) {
    final buffer = StringBuffer();

    if (result.missingFields.isNotEmpty) {
      buffer.writeln('❌ DATOS FALTANTES (${result.missingFields.length}):');
      for (var field in result.missingFields) {
        buffer.writeln('  • $field');

        // Agregar sugerencias específicas
        if (field == 'Tasa de Victorias') {
          buffer.writeln('    💡 Asegúrate de que el porcentaje (ej: 59.29%) sea visible');
        }
      }
    }

    if (result.warningFields.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('⚠️ ADVERTENCIAS (${result.warningFields.length}):');
      buffer.writeln('Los siguientes campos están en 0:');
      for (var field in result.warningFields.take(5)) {
        buffer.writeln('  • $field');

        // Sugerencias específicas para campos importantes
        if (field == 'Daño Causado Máx./min') {
          buffer.writeln('    💡 Verifica que el número de 4-5 dígitos sea visible');
        }
      }
      if (result.warningFields.length > 5) {
        buffer.writeln('  ... y ${result.warningFields.length - 5} más');
      }
    }

    buffer.writeln();
    buffer.writeln('📊 Completitud: ${result.completionPercentage.toStringAsFixed(1)}%');

    return buffer.toString();
  }

  /// Genera recomendaciones para mejorar la captura
  static List<String> getRecommendations(ValidationResult result) {
    final recommendations = <String>[];

    if (result.missingFields.isNotEmpty) {
      recommendations.add(
        '📸 Asegúrate de que la imagen muestre claramente todas las estadísticas',
      );
      recommendations.add('💡 Intenta tomar la captura con buena iluminación y sin reflejos');
      recommendations.add('🔍 Verifica que el texto sea legible y no esté borroso');

      // Recomendaciones específicas
      if (result.missingFields.contains('Tasa de Victorias')) {
        recommendations.add(
          '🎯 Tasa de Victorias: Asegúrate de que el porcentaje esté completo (ej: 59.29%)',
        );
      }
    }

    if (result.warningFields.contains('Daño Causado Máx./min')) {
      recommendations.add(
        '⚔️ Daño Causado: Verifica que el número de 4-5 dígitos sea claramente visible',
      );
    }

    if (result.completionPercentage < 50) {
      recommendations.add('⚠️ Se detectaron muy pocos datos. Considera volver a tomar la captura');
    }

    return recommendations;
  }

  /// Método para obtener un informe completo de depuración
  static String getDebugReport(ValidationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('=== REPORTE DE DEPURACIÓN ===\n');
    buffer.writeln('Validez: ${result.isValid ? "✓ VÁLIDO" : "✗ INVÁLIDO"}');
    buffer.writeln('Completitud: ${result.completionPercentage.toStringAsFixed(1)}%');
    buffer.writeln('Campos válidos: ${result.validFields}/${result.totalFields}\n');

    buffer.writeln('--- VALORES EXTRAÍDOS ---');
    result.extractedValues.forEach((key, value) {
      buffer.writeln('$key: $value');
    });

    if (result.missingFields.isNotEmpty) {
      buffer.writeln('\n--- CAMPOS FALTANTES ---');
      for (var field in result.missingFields) {
        buffer.writeln('✗ $field');
      }
    }

    if (result.warningFields.isNotEmpty) {
      buffer.writeln('\n--- ADVERTENCIAS ---');
      for (var field in result.warningFields) {
        buffer.writeln('⚠ $field');
      }
    }

    return buffer.toString();
  }
}
