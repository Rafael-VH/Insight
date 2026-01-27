import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:insight/features/stats/domain/entities/ocr_result.dart';
import 'package:insight/features/stats/domain/entities/text_block.dart'
    as entities;
import 'package:insight/features/stats/domain/entities/text_line.dart'
    as entities;

class OcrResultModel extends OcrResult {
  const OcrResultModel({
    required super.recognizedText,
    required super.imagePath,
    required super.processedAt,
    required super.textBlocks,
  });

  factory OcrResultModel.fromRecognizedText(
    RecognizedText recognizedText,
    String imagePath,
  ) {
    final textBlocks = recognizedText.blocks.map((block) {
      return entities.TextBlock(
        text: block.text,
        boundingBox: block.boundingBox,
        lines: block.lines.map((line) {
          return entities.TextLine(
            text: line.text,
            boundingBox: line.boundingBox,
          );
        }).toList(),
      );
    }).toList();

    final fullText = recognizedText.blocks
        .map((block) => block.lines.map((line) => line.text).join('\n'))
        .join('\n');

    return OcrResultModel(
      recognizedText: fullText,
      imagePath: imagePath,
      processedAt: DateTime.now(),
      textBlocks: textBlocks,
    );
  }
}
