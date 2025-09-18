// lib/features/ocr/presentation/widgets/recognized_text_widget.dart
import 'package:flutter/material.dart';

class RecognizedTextWidget extends StatelessWidget {
  const RecognizedTextWidget({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onCopyPressed,
  });

  final String text;
  final bool isLoading;
  final Function(String) onCopyPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recognized Text",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => onCopyPressed(text),
                  tooltip: 'Copy text',
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing image...'),
                      ],
                    ),
                  )
                : Scrollbar(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: SelectableText(
                          text.isEmpty ? "No text recognized" : text,
                          style: TextStyle(
                            fontSize: 16,
                            color: text.isEmpty
                                ? Colors.grey[600]
                                : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
