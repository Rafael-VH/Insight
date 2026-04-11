import 'dart:io';

import 'package:flutter/material.dart';
import 'package:insight/core/utils/stats_validator.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';

/// Tarjeta de carga de imagen completamente rediseñada.
///
/// - Header con color del modo y badge de estado
/// - Zona de imagen con estado vacío / cargado / procesando
/// - Footer con botones de galería y cámara inline
class UploadImageCardWithOverlay extends StatelessWidget {
  const UploadImageCardWithOverlay({
    super.key,
    required this.mode,
    required this.imagePath,
    required this.isProcessing,
    required this.validation,
    required this.onUploadPressed,
    required this.onValidationBadgeTap,
  });

  final GameMode mode;
  final String? imagePath;
  final bool isProcessing;
  final ValidationResult? validation;
  final void Function(ImageSourceType) onUploadPressed;
  final VoidCallback onValidationBadgeTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeColor = mode.color;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor(colorScheme, isDark, modeColor),
          width: _hasFinalState ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────
          _CardHeader(
            mode: mode,
            modeColor: modeColor,
            isDark: isDark,
            colorScheme: colorScheme,
            validation: validation,
            isProcessing: isProcessing,
            onValidationBadgeTap: onValidationBadgeTap,
          ),
          // ── Zona de imagen ───────────────────────────────────
          _ImageZone(
            mode: mode,
            imagePath: imagePath,
            isProcessing: isProcessing,
            modeColor: modeColor,
            isDark: isDark,
            colorScheme: colorScheme,
            onTap: () => _showSourceSheet(context),
          ),
          // ── Footer: botones de fuente ────────────────────────
          if (!isProcessing)
            _SourceButtonsFooter(
              colorScheme: colorScheme,
              isDark: isDark,
              onGallery: () => onUploadPressed(ImageSourceType.gallery),
              onCamera: () => onUploadPressed(ImageSourceType.camera),
            ),
        ],
      ),
    );
  }

  bool get _hasFinalState => validation != null || (imagePath != null && !isProcessing);

  Color _borderColor(ColorScheme cs, bool isDark, Color modeColor) {
    if (isProcessing) return modeColor.withValues(alpha: 0.5);
    if (validation != null) {
      return validation!.isValid
          ? Colors.green.withValues(alpha: 0.6)
          : Colors.red.withValues(alpha: 0.4);
    }
    return cs.outline.withValues(alpha: isDark ? 0.2 : 0.15);
  }

  void _showSourceSheet(BuildContext context) {
    _SourceBottomSheet.show(context, onUploadPressed);
  }
}

// ── Header ────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.mode,
    required this.modeColor,
    required this.isDark,
    required this.colorScheme,
    required this.validation,
    required this.isProcessing,
    required this.onValidationBadgeTap,
  });

  final GameMode mode;
  final Color modeColor;
  final bool isDark;
  final ColorScheme colorScheme;
  final ValidationResult? validation;
  final bool isProcessing;
  final VoidCallback onValidationBadgeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: modeColor.withValues(alpha: isDark ? 0.15 : 0.07),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          // Ícono del modo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(mode.icon, color: modeColor, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.fullDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  mode.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Badge de estado
          _StatusBadge(
            validation: validation,
            isProcessing: isProcessing,
            modeColor: modeColor,
            isDark: isDark,
            onTap: validation != null ? onValidationBadgeTap : null,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.validation,
    required this.isProcessing,
    required this.modeColor,
    required this.isDark,
    this.onTap,
  });

  final ValidationResult? validation;
  final bool isProcessing;
  final Color modeColor;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: modeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: modeColor),
            ),
            const SizedBox(width: 6),
            Text(
              'Procesando',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: modeColor),
            ),
          ],
        ),
      );
    }

    if (validation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Pendiente',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
      );
    }

    final isValid = validation!.isValid;
    final color = isValid ? Colors.green : Colors.red;
    final label = isValid ? 'Completada' : 'Incompleta';
    final icon = isValid ? Icons.check_circle_outline : Icons.error_outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Zona de imagen ────────────────────────────────────────────────

class _ImageZone extends StatelessWidget {
  const _ImageZone({
    required this.mode,
    required this.imagePath,
    required this.isProcessing,
    required this.modeColor,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  final GameMode mode;
  final String? imagePath;
  final bool isProcessing;
  final Color modeColor;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Estado: procesando
    if (isProcessing) {
      return _ProcessingZone(modeColor: modeColor, mode: mode);
    }

    // Estado: imagen cargada
    if (imagePath != null) {
      return _FilledImageZone(imagePath: imagePath!, onTap: onTap);
    }

    // Estado: vacío
    return _EmptyImageZone(
      modeColor: modeColor,
      isDark: isDark,
      colorScheme: colorScheme,
      onTap: onTap,
    );
  }
}

class _EmptyImageZone extends StatelessWidget {
  const _EmptyImageZone({
    required this.modeColor,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  final Color modeColor;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.35),
            style: BorderStyle.solid,
          ),
          color: colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: modeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_photo_alternate_rounded, color: modeColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Toca para cargar imagen',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cámara o galería',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.38)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledImageZone extends StatelessWidget {
  const _FilledImageZone({required this.imagePath, required this.onTap});

  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(imagePath), fit: BoxFit.cover),
          // Overlay oscuro suave
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
              ),
            ),
          ),
          // Botón de reemplazar
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Cambiar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Indicador de éxito
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingZone extends StatelessWidget {
  const _ProcessingZone({required this.modeColor, required this.mode});

  final Color modeColor;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: modeColor.withValues(alpha: 0.06),
        border: Border.all(color: modeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: modeColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Extrayendo estadísticas…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mode.fullDisplayName,
            style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Footer con botones de fuente ─────────────────────────────────

class _SourceButtonsFooter extends StatelessWidget {
  const _SourceButtonsFooter({
    required this.colorScheme,
    required this.isDark,
    required this.onGallery,
    required this.onCamera,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_library_rounded,
              label: 'Galería',
              colorScheme: colorScheme,
              isDark: isDark,
              onTap: onGallery,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'Cámara',
              colorScheme: colorScheme,
              isDark: isDark,
              onTap: onCamera,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet de selección de fuente ──────────────────────────────────

class _SourceBottomSheet {
  static void show(BuildContext context, void Function(ImageSourceType) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SourceSheetContent(onSelected: onSelected),
    );
  }
}

class _SourceSheetContent extends StatelessWidget {
  const _SourceSheetContent({required this.onSelected});

  final void Function(ImageSourceType) onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Seleccionar imagen',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BigSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galería',
                  subtitle: 'Elige una captura',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(ImageSourceType.gallery);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Cámara',
                  subtitle: 'Tomar foto ahora',
                  color: const Color(0xFF059669),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(ImageSourceType.camera);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigSourceButton extends StatelessWidget {
  const _BigSourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
