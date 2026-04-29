import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/usecases/copy_to_clipboard.dart';
import 'package:insight/features/ocr/domain/usecases/recognize_image_text.dart';
import 'package:insight/features/upload/domain/usecases/base_usecase.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_event.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_state.dart';

class OcrBloc extends Bloc<OcrEvent, OcrState> {
  final RecognizeImageText pickImageAndRecognizeText;
  final CopyToClipboard copyTextToClipboard;

  OcrBloc({required this.pickImageAndRecognizeText, required this.copyTextToClipboard})
    : super(OcrInitial()) {
    on<ProcessImageEvent>(_onProcessImage);
    on<CopyTextEvent>(_onCopyText);
    on<ResetStateEvent>(_onResetState);
  }

  Future<void> _onProcessImage(ProcessImageEvent event, Emitter<OcrState> emit) async {
    emit(OcrLoading());

    final result = await pickImageAndRecognizeText(ImageSourceParams(source: event.source));

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
