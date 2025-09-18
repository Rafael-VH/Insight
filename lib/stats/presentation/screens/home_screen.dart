// lib/features/ocr/presentation/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/domain/entities/image_source_type.dart';
import 'package:insight/stats/presentation/bloc/ocr_bloc.dart';
import 'package:insight/stats/presentation/bloc/ocr_event.dart';
import 'package:insight/stats/presentation/bloc/ocr_state.dart';
import 'package:insight/stats/presentation/widgets/image_preview_widget.dart';
import 'package:insight/stats/presentation/widgets/recognized_text_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Text Recognition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OcrBloc>().add(ResetStateEvent());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<OcrBloc, OcrState>(
          listener: (context, state) {
            if (state is OcrError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is TextCopied) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Image Preview
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ImagePreviewWidget(
                    imagePath: state is OcrSuccess
                        ? state.result.imagePath
                        : null,
                  ),
                ),

                // Pick Image Button
                ElevatedButton(
                  onPressed: state is OcrLoading
                      ? null
                      : () => _showImageSourceModal(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pick an image'),
                      if (state is OcrLoading) ...[
                        const SizedBox(width: 20),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(),

                // Recognized Text Section
                Expanded(
                  child: RecognizedTextWidget(
                    text: state is OcrSuccess
                        ? state.result.recognizedText
                        : '',
                    isLoading: state is OcrLoading,
                    onCopyPressed: (text) {
                      context.read<OcrBloc>().add(CopyTextEvent(text));
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<OcrBloc>().add(
                    const ProcessImageEvent(ImageSourceType.gallery),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<OcrBloc>().add(
                    const ProcessImageEvent(ImageSourceType.camera),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
