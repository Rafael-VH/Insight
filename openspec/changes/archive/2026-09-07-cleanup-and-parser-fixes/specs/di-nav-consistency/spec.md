# DI & Navigation Consistency Specification

## Purpose

The dependency container and navigation must match the real app: no phantom registrations, no stale destination count, no dead widgets, and shared usecase infrastructure located core-ward in the dependency graph.

## Requirements

### Requirement: Remove the phantom http registration

The system MUST remove the unused `http` import (injection_container.dart:3) and the `sl.registerLazySingleton(() => http.Client())` registration (injection_container.dart:83). Grep confirms no code resolves a `http.Client` from the container anywhere in `lib/` or `test/`.

#### Scenario: No dangling network registration

- GIVEN the http import and registration removed
- WHEN grep for `package:http` and `http.Client` runs across `lib/` and `test/`
- THEN zero matches remain
- AND `flutter analyze` reports no undefined references

### Requirement: Align totalDestinations with the real navigation items

The system MUST register `NavigationBloc(totalDestinations: 3)` (currently 7, injection_container.dart:203), matching the 3 `NavigationItem`s built in main_screen.dart:47-81 (home, history, settings). Navigation semantics MUST NOT change: valid indices still navigate, out-of-range and negative indices still emit `NavigationError`.

#### Scenario: Stale destination count corrected

- GIVEN main_screen.dart builds exactly 3 destination items
- WHEN a `NavigationItemSelected` for a valid index (0-2) is dispatched through the DI-registered bloc
- THEN `NavigationChanged` is emitted
- AND selecting index ≥3 still emits `NavigationError`
- AND `flutter test` for the navigation suite stays green (tests construct their own bloc, navigation_bloc_test.dart:12)

#### Scenario: No index-out-of-bounds crashes

- GIVEN the app running with `totalDestinations: 3`
- WHEN the user navigates between the 3 destinations
- THEN no range errors occur in the `IndexedStack` (main_screen.dart:141-144)

### Requirement: Delete the unused _PlaceholderPage widget

The system MUST delete `_PlaceholderPage` (main_screen.dart:188-222) after confirming no usage: grep shows only the class declaration and constructor, no instantiation in any navigation item.

#### Scenario: Placeholder removed without breakage

- GIVEN grep confirms `_PlaceholderPage` is never instantiated
- WHEN the class is deleted from main_screen.dart
- THEN the app compiles and `MainScreen` builds its 3 real pages

### Requirement: Move base_usecase.dart to core and repoint all importers

The system MUST move `lib/features/upload/domain/usecases/base_usecase.dart` to `lib/core/usecases/base_usecase.dart` and update ALL 4 import sites to the new path: `ocr_bloc.dart:4`, `recognize_image_text.dart:5`, `get_settings.dart:5`, `copy_to_clipboard.dart:4`. The dependency direction after the move MUST be core-ward: the generic base type no longer lives inside the upload feature.

#### Scenario: All import sites updated

- GIVEN the file moved to `lib/core/usecases/`
- WHEN grep for `upload/domain/usecases/base_usecase.dart` runs
- THEN zero matches remain across `lib/` and `test/`
- AND all 4 files import `package:insight/core/usecases/base_usecase.dart`
- AND `flutter analyze` is clean

## Acceptance Criteria

- Grep-proof: no `package:http`, no `upload/domain/usecases/base_usecase.dart`, no `_PlaceholderPage` usage
- `flutter analyze` clean; `flutter test` green