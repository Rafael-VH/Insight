// lib/features/ocr/domain/entities/text_block.dart
import 'dart:ui';

import 'package:insight/stats/domain/entities/text_line.dart';

class TextBlock {
  final String text;
  final List<TextLine> lines;
  final Rect boundingBox;

  const TextBlock({
    required this.text,
    required this.lines,
    required this.boundingBox,
  });
}
