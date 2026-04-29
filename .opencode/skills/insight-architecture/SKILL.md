---
name: insight-architecture
description: Insight Flutter app Clean Architecture patterns. Use when developing features for this project. Follows feature-first structure with domain/data/presentation layers, BLoC state management, GetIt DI, and repository pattern.
---

# Insight Architecture

This skill defines the architecture patterns and conventions used in the Insight Flutter application.

## Project Structure

Insight follows **feature-first Clean Architecture**:

```
lib/
├── features/
│   ├── [feature_name]/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── controllers/
│   └── [feature_name].dart  # barrel file
├── main.dart
└── app.dart
```

## Technology Stack

- **Flutter SDK**: >=3.10.3
- **State Management**: BLoC (flutter_bloc)
- **Dependency Injection**: GetIt
- **HTTP Client**: http package
- **OCR**: Google ML Kit

## Development Rules

### 1. Feature Organization

- Each feature lives in `lib/features/[feature_name]/`
- Code specific to a feature stays in its folder
- Shared code goes in `shared/` or core modules
- Use barrel files (`[feature].dart`) for clean exports

### 2. Domain Layer

- Define entities as immutable Dart classes
- Create abstract repository interfaces in `domain/repositories/`
- Implement use cases in `domain/usecases/` following base_usecase pattern
- Never import data layer into domain layer

### 3. Data Layer

- Models map to/from JSON (use `json_serializable` or manual mapping)
- Data sources handle external APIs or local storage
- Repository implementations wrap data sources
- Return domain entities, never expose data models externally

### 4. Presentation Layer

- BLoC for complex state: `feature_bloc.dart`, `feature_event.dart`, `feature_state.dart`
- Screens in `screens/[feature]_screen.dart`
- Widgets specific to feature in `widgets/`
- Controllers for reusable business logic

### 5. Dependency Injection

Use GetIt for DI. Register dependencies in feature modules:

```dart
getIt.registerFactory(() => FeatureBloc(
  getIt<FeatureRepository>(),
  getIt<FeatureUseCase>(),
));
```

### 6. Error Handling

- Use Result pattern or sealed classes for error handling
- Never expose exceptions across layer boundaries
- Provide meaningful error messages to users

## Code Examples

### Repository Pattern

```dart
// domain/repositories/feature_repository.dart
abstract class FeatureRepository {
  Future<Result<FeatureEntity, Failure>> getFeature();
}

// data/repositories/feature_repository_impl.dart
class FeatureRepositoryImpl implements FeatureRepository {
  final RemoteDataSource _dataSource;
  
  @override
  Future<Result<FeatureEntity, Failure>> getFeature() async {
    try {
      final model = await _dataSource.fetch();
      return Success(model.toEntity());
    } catch (e) {
      return Error(Failure(e.toString()));
    }
  }
}
```

### BLoC Pattern

```dart
// presentation/bloc/feature_bloc.dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final GetFeatureUseCase _useCase;
  
  FeatureBloc(this._useCase) : super(FeatureInitial()) {
    on<LoadFeature>(_onLoadFeature);
  }
  
  Future<void> _onLoadFeature(
    LoadFeature event,
    Emitter<FeatureState> emit,
  ) async {
    emit(FeatureLoading());
    final result = await _useCase();
    result.fold(
      (failure) => emit(FeatureError(failure.message)),
      (entity) => emit(FeatureLoaded(entity)),
    );
  }
}
```

## When to Use This Skill

- Creating new features in Insight
- Adding screens, widgets, or business logic
- Working with any module in `lib/features/`
- Implementing data access or API calls

## Verification

After making changes, run:

- `flutter analyze` - Check for errors
- `flutter test` - Run tests
- `dart format -w .` - Format code