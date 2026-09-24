# Test Suite Health Specification

## Purpose

After this change, the full test suite must be green and every test must actually gate the behavior it claims to verify. Two suites are currently broken by construction: navigation_bloc_test.dart:138-145 escapes its async assertion, and widget_test.dart is a stale counter-template test that cannot pass against the real app.

## Requirements

### Requirement: Full suite exits 0

The system MUST pass `flutter test` with exit code 0 — all suites green, no failures — after the test suites are fixed.

#### Scenario: Green suite

- GIVEN the fixed test files
- WHEN `flutter test` runs
- THEN the process exits 0 with zero failing tests

#### Scenario: Regression guard

- GIVEN a subsequent regression in the touched suites
- WHEN `flutter test` runs
- THEN the failing suite reports the failure (no silent passes)

### Requirement: Resolve the async escape in getBadge test

The test `getBadge retorna el badge correcto después de actualizar` (navigation_bloc_test.dart:138-145) MUST NOT place its `expect` inside an un-awaited `Future.delayed` callback. It MUST either await the assertion or be rewritten as a `blocTest` (bloc_test is already a dependency and used throughout the file), so the expectation genuinely gates the test.

#### Scenario: Assertion gates the test

- GIVEN the rewritten test asserting `getBadge(2)` equals `'3'` after `UpdateNavigationBadge(index: 2, badge: '3')`
- WHEN the test runs
- THEN the assertion is evaluated within the test body (no async escape)
- AND the test fails if the badge value differs

### Requirement: Replace stale counter smoke test with a boot smoke test

The counter template in widget_test.dart (lines 1-30) references UI that no longer exists (no counter in `MyApp`; MyApp requires initialized DI, main.dart:71) and MUST be replaced — deletion alone is NOT acceptable. The replacement MUST be a boot smoke test that: calls `SharedPreferences.setMockInitialValues({})`, initializes the container via `di.init()`, pumps `MyApp`, advances past the splash sequence (splash_screen.dart:150-179), and verifies `MainScreen` renders.

#### Scenario: App boots to main screen

- GIVEN mocked SharedPreferences and initialized DI
- WHEN `MyApp` is pumped and splash timers are advanced
- THEN `MainScreen` renders without exceptions
- AND the smoke test finds one or more MainScreen features (`UploadHomeScreen`, app bar title `Inicio`)

#### Scenario: No stale counter assertions remain

- GIVEN the replaced test file
- WHEN the file is inspected
- THEN no assertion references `Icons.add` or a counter value

## Acceptance Criteria

- `flutter test` exits 0 (full suite, not a subset)
- `flutter analyze` reports no issues