//
import 'package:equatable/equatable.dart';
import 'package:insight/stats/domain/entities/image_source_type.dart';

abstract class OcrEvent extends Equatable {
  const OcrEvent();

  @override
  List<Object> get props => [];
}

class ProcessImageEvent extends OcrEvent {
  final ImageSourceType source;

  const ProcessImageEvent(this.source);

  @override
  List<Object> get props => [source];
}

class CopyTextEvent extends OcrEvent {
  final String text;

  const CopyTextEvent(this.text);

  @override
  List<Object> get props => [text];
}

class ResetStateEvent extends OcrEvent {}
