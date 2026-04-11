import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/history/presentation/bloc/history_state.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';

/// Bottom sheet de importación desde el módulo Settings.
///
/// Migrado para consumir [HistoryBloc] en lugar del antiguo [StatsBloc].
class SettingsImportBottomSheet extends StatefulWidget {
  const SettingsImportBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<HistoryBloc>()),
          BlocProvider.value(value: context.read<NavigationBloc>()),
        ],
        child: const SettingsImportBottomSheet(),
      ),
    );
  }

  @override
  State<SettingsImportBottomSheet> createState() =>
      _SettingsImportBottomSheetState();
}

class _SettingsImportBottomSheetState
    extends State<SettingsImportBottomSheet> {
  bool _mergeMode = true;
  bool _isImporting = false;

  // ── Acciones ─────────────────────────────────────────────────

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Selecciona archivo de estadísticas Insight',
    );

    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    setState(() => _isImporting = true);

    context.read<HistoryBloc>().add(
      ImportStatsFromJsonEvent(
        filePath: result.files.single.path!,
        mergeWithExisting: _mergeMode,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryBloc, HistoryState>(
      listener: (context, state) {
        if (state is HistoryImported) {
          Navigator.of(context, rootNavigator: true).pop();
          // Navegar al Historial (índice 1)
          context
              .read<NavigationBloc>()
              .add(const NavigationItemSelected(1));
        }

        if (state is HistoryError && _isImporting) {
          setState(() => _isImporting = false);
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(colorScheme),
          const SizedBox(height: 20),
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildModeSelector(colorScheme, isDark),
          const SizedBox(height: 28),
          _buildImportButton(colorScheme),
          const SizedBox(height: 12),
          TextButton(
            onPressed:
                _isImporting ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6)
                .withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.download_rounded,
            size: 32,
            color: Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Importar estadísticas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Elige cómo quieres combinar el archivo\ncon tus datos actuales.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        _ModeOption(
          selected: _mergeMode,
          icon: Icons.merge_rounded,
          color: const Color(0xFF3B82F6),
          title: 'Fusionar con el historial actual',
          subtitle:
              'Agrega las colecciones del archivo sin borrar las existentes. '
              'Los duplicados se omiten automáticamente.',
          onTap: () => setState(() => _mergeMode = true),
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _ModeOption(
          selected: !_mergeMode,
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFFDC2626),
          title: 'Reemplazar el historial actual',
          subtitle:
              'Borra todas las colecciones existentes y carga únicamente '
              'las del archivo importado.',
          onTap: () => setState(() => _mergeMode = false),
          colorScheme: colorScheme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildImportButton(ColorScheme colorScheme) {
    final color =
        _mergeMode ? const Color(0xFF3B82F6) : const Color(0xFFDC2626);
    final label =
        _mergeMode ? 'Fusionar desde archivo' : 'Reemplazar desde archivo';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isImporting ? null : _pickAndImport,
        icon: _isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.folder_open_rounded),
        label: Text(_isImporting ? 'Importando...' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Widget interno de opción de modo ─────────────────────────────

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color
                : colorScheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    color.withValues(alpha: selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? color : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : colorScheme.outline,
                  width: 2,
                ),
                color: selected ? color : Colors.transparent,
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
