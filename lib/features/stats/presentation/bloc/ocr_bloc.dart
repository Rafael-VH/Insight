import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/features/stats/domain/usecases/copy_text_to_clipboard.dart';
import 'package:insight/features/stats/domain/usecases/pick_image_and_recognize_text.dart';
import 'package:insight/features/stats/domain/usecases/usecase.dart';
//
import 'package:insight/features/stats/presentation/bloc/ocr_event.dart';
import 'package:insight/features/stats/presentation/bloc/ocr_state.dart';

class OcrBloc extends Bloc<OcrEvent, OcrState> {
  final PickImageAndRecognizeText pickImageAndRecognizeText;
  final CopyTextToClipboard copyTextToClipboard;

  OcrBloc({
    required this.pickImageAndRecognizeText,
    required this.copyTextToClipboard,
  }) : super(OcrInitial()) {
    on<ProcessImageEvent>(_onProcessImage);
    on<CopyTextEvent>(_onCopyText);
    on<ResetStateEvent>(_onResetState);
  }

  Future<void> _onProcessImage(
    ProcessImageEvent event,
    Emitter<OcrState> emit,
  ) async {
    emit(OcrLoading());

    final result = await pickImageAndRecognizeText(
      ImageSourceParams(source: event.source),
    );

    result.fold(
      (failure) => emit(OcrError(failure.message)),
      (ocrResult) => emit(OcrSuccess(ocrResult)),
    );
  }

  Future<void> _onCopyText(CopyTextEvent event, Emitter<OcrState> emit) async {
    final result = await copyTextToClipboard(event.text);

    result.fold(
      (failure) => emit(OcrError(failure.message)),
      (_) => emit(const TextCopied('Text copied to clipboard')),
    );
  }

  void _onResetState(ResetStateEvent event, Emitter<OcrState> emit) {
    emit(OcrInitial());
  }
}
