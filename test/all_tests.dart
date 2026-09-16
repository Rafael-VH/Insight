// ================================================================
// Archivo raíz de pruebas — importa todos los suites del proyecto.
//
// Para ejecutar todas las pruebas:
//   flutter test
//
// Para ejecutar un módulo específico:
//   flutter test test/core/utils/stats_parser_test.dart
// ================================================================

// Core
import 'core/utils/stats_parser_test.dart' as stats_parser;
import 'core/utils/stats_validator_test.dart' as stats_validator;

// Stats — Entities & Models
import 'features/stats/domain/entities/entities_test.dart' as stats_entities;
import 'features/stats/data/models/stats_collection_model_test.dart'
    as stats_collection_model;

// Stats — BLoC & Controller
import 'features/stats/presentation/controllers/stats_upload_controller_test.dart'
    as upload_controller;

// Settings — Entities
import 'features/settings/domain/entities/settings_entities_test.dart'
    as settings_entities;

// Navigation — BLoC
import 'features/navigation/bloc/navigation_bloc_test.dart' as nav_bloc;

void main() {
  // Core utilities
  stats_parser.main();
  stats_validator.main();

  // Stats module
  stats_entities.main();
  stats_collection_model.main();
  upload_controller.main();

  // Settings module
  settings_entities.main();

  // Navigation module
  nav_bloc.main();
}
