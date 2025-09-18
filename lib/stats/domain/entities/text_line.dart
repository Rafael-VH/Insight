// lib/features/ocr/domain/entities/text_line.dart
import 'dart:ui';

class TextLine {
  final String text;
  final Rect boundingBox;

  const TextLine({required this.text, required this.boundingBox});
}
