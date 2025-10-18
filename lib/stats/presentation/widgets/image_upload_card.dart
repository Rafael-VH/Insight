import 'dart:io';

import 'package:flutter/material.dart';
//
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/image_source_type.dart';

class ImageUploadCard extends StatelessWidget {
  const ImageUploadCard({
    super.key,
    required this.gameMode,
    required this.imagePath,
    required this.isProcessing,
    required this.onUploadPressed,
  });

  final GameMode gameMode;
  final String? imagePath;
  final bool isProcessing;
  final Function(ImageSourceType) onUploadPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getGameModeColor().withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getGameModeColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGameModeIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDisplayName(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getGameModeColor(),
                    ),
                  ),
                ),
                if (imagePath != null && !isProcessing)
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                if (isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Image preview or upload button
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: imagePath == null
                ? _buildUploadArea(context)
                : _buildImagePreview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    return InkWell(
      onTap: isProcessing ? null : () => _showImageSourceDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Procesando imagen...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Toca para cargar imagen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Captura de ${_getDisplayName()}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(imagePath!),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: isProcessing
                  ? null
                  : () => _showImageSourceDialog(context),
              tooltip: 'Cambiar imagen',
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seleccionar imagen desde',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.blue[700]),
                  ),
                  title: const Text('Cámara'),
                  subtitle: const Text('Tomar una foto nueva'),
                  onTap: () {
                    Navigator.pop(context);
                    onUploadPressed(ImageSourceType.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_library, color: Colors.green[700]),
                  ),
                  title: const Text('Galería'),
                  subtitle: const Text('Elegir de la galería'),
                  onTap: () {
                    Navigator.pop(context);
                    onUploadPressed(ImageSourceType.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getGameModeColor() {
    switch (gameMode) {
      case GameMode.total:
        return const Color(0xFF059669);
      case GameMode.ranked:
        return const Color(0xFFDC2626);
      case GameMode.classic:
        return const Color(0xFF2563EB);
      case GameMode.brawl:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _getGameModeIcon() {
    switch (gameMode) {
      case GameMode.total:
        return Icons.dashboard;
      case GameMode.ranked:
        return Icons.military_tech;
      case GameMode.classic:
        return Icons.games;
      case GameMode.brawl:
        return Icons.sports_mma;
    }
  }

  String _getDisplayName() {
    switch (gameMode) {
      case GameMode.total:
        return 'Estadísticas Totales';
      case GameMode.ranked:
        return 'Clasificatoria';
      case GameMode.classic:
        return 'Clásica';
      case GameMode.brawl:
        return 'Coliseo';
    }
  }
}
