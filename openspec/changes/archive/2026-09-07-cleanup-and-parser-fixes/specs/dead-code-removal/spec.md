# Dead Code Removal Specification

## Purpose

Remove every file verified to have zero imports, plus the dependency that only it used. Each removal MUST be re-verified as unimported immediately before deletion, and the app MUST still compile and pass tests afterwards.

## Requirements

### Requirement: Remove all zero-import files

The system MUST remove the following files, each verified by grep to have no importer outside its own pair (evidence in parentheses):

- `lib/features/upload/domain/repositories/session_repository.dart` + `lib/features/upload/data/repositories/session_repository_impl.dart` — the dead twin of HistoryRepository; impl (196 lines) imports the domain file (24 lines) but nothing imports the impl
- `lib/features/upload/presentation/widgets/upload_source_button.dart` — zero imports
- `lib/features/upload/presentation/widgets/upload_image_picker_card.dart` — zero imports
- `lib/features/navigation/presentation/screens/widgets/main_bottom_bar.dart` — zero imports
- The 7 feature barrels: `lib/features/{upload,settings,navigation,parser,insights,ocr,history}/{upload,settings,navigation,parser,insights,ocr,history}.dart` — zero imports (all code uses direct paths, e.g. injection_container.dart:19-27)
- The 4 core widgets: `lib/core/widgets/{session_summary_card,error_state_widget,empty_state_widget,app_info_banner}.dart` — zero imports
- `lib/features/settings/domain/usecases/usecases.dart` — zero imports (DI imports each usecase directly)

#### Scenario: Verify zero imports before each deletion

- GIVEN a target file from the list
- WHEN grep is run for its path across `lib/` and `test/`
- THEN no import references are found (except the session_repository self-pair)
- AND only then is the file deleted

#### Scenario: App still compiles and tests pass

- GIVEN all listed files removed
- WHEN `flutter analyze` and `flutter test` run
- THEN analysis is clean and the suite is green

### Requirement: Drop the salomon_bottom_bar dependency

The `salomon_bottom_bar` package (pubspec.yaml:19) MUST be removed from dependencies, but only after re-verifying that `main_bottom_bar.dart` is its sole consumer (grep: matches exist only in that file, lines 5, 38, 50, 58).

#### Scenario: Dependency has no remaining consumers

- GIVEN `main_bottom_bar.dart` deleted
- WHEN grep for `salomon` runs across `lib/` and `test/`
- THEN zero matches remain
- AND the package is removed from pubspec.yaml

## Acceptance Criteria

- `flutter analyze` clean; `flutter test` green after removals
- Grep for every removed file path returns no imports