import 'package:equatable/equatable.dart';
//
import 'package:insight/features/stats/domain/entities/ocr_result.dart';

abstract class OcrState extends Equatable {
  const OcrState();

  @override
  List<Object?> get props => [];
}

class OcrInitial extends OcrState {}

class OcrLoading extends OcrState {}

class OcrSuccess extends OcrState {
  final OcrResult result;

  const OcrSuccess(this.result);

  @override
  List<Object> get props => [result];
}

class OcrError extends OcrState {
  final String message;

  const OcrError(this.message);

  @override
  List<Object> get props => [message];
}

class TextCopied extends OcrState {
  final String message;

  const TextCopied(this.message);

  @override
  List<Object> get props => [message];
}
