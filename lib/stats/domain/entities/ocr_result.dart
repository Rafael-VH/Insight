import 'package:insight/stats/domain/entities/text_block.dart';

class OcrResult {
  final String recognizedText;
  final String imagePath;
  final DateTime processedAt;
  final List<TextBlock> textBlocks;

  const OcrResult({
    required this.recognizedText,
    required this.imagePath,
    required this.processedAt,
    required this.textBlocks,
  });

  bool get hasText => recognizedText.isNotEmpty;
}
