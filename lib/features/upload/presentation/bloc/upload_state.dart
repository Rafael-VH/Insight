import 'package:equatable/equatable.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsSaving extends StatsState {
  final String message;
  const StatsSaving(this.message);

  @override
  List<Object> get props => [message];
}

class StatsSaved extends StatsState {
  final String message;

  const StatsSaved(this.message);

  @override
  List<Object> get props => [message];
}

class StatsError extends StatsState {
  final String message;
  final String? errorDetails;

  const StatsError(this.message, {this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];
}
