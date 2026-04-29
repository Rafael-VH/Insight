import 'package:equatable/equatable.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends UploadState {}

class StatsSaving extends UploadState {
  final String message;
  const StatsSaving(this.message);

  @override
  List<Object> get props => [message];
}

class StatsSaved extends UploadState {
  final String message;

  const StatsSaved(this.message);

  @override
  List<Object> get props => [message];
}

class StatsError extends UploadState {
  final String message;
  final String? errorDetails;

  const StatsError(this.message, {this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];
}
