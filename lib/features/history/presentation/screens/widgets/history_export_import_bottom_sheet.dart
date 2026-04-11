import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/history/presentation/bloc/history_state.dart';

/// Bottom sheet de exportación / importación del módulo History.
///
/// Versión migrada de [ExportImportBottomSheet] que consume [HistoryBloc]
/// en lugar del antiguo [StatsBloc].
class HistoryExportImportBottomSheet extends StatefulWidget {
  const HistoryExportImportBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<HistoryBloc>(),
        child: const HistoryExportImportBottomSheet(),
      ),
    );
  }

  @override
  State<HistoryExportImportBottomSheet> createState() =>
      _HistoryExportImportBottomSheetState();
}

class _HistoryExportImportBottomSheetState
    extends State<HistoryExportImportBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryBloc, HistoryState>(
      listener: (context, state) {
        if (state is HistoryExporting || state is HistoryImporting) {
          if (mounted) setState(() => _isLoading = true);
        } else if (state is HistoryExported ||
            state is HistoryImported ||
            state is HistoryError) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading ? _buildLoading() : _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: const ValueKey('loading'),
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Procesando archivo...',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Exportar / Importar',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Respalda o restaura tus estadísticas en formato JSON',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _ActionTile(
          icon: Icons.upload_file_rounded,
          color: const Color(0xFF059669),
          title: 'Exportar estadísticas',
          subtitle: 'Genera un archivo .json para compartir o respaldar',
          onTap: () => context
              .read<HistoryBloc>()
              .add(const ExportStatsToJsonEvent()),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.download_rounded,
          color: const Color(0xFF3B82F6),
          title: 'Importar y fusionar',
          subtitle: 'Agrega las del archivo sin borrar las actuales',
          onTap: () => _pickAndImport(context, merge: true),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFFDC2626),
          title: 'Importar y reemplazar',
          subtitle: 'Borra las actuales y carga las del archivo',
          onTap: () => _pickAndImport(context, merge: false),
        ),
      ],
    );
  }

  Future<void> _pickAndImport(
    BuildContext context, {
    required bool merge,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Selecciona archivo ML Stats',
    );

    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    context.read<HistoryBloc>().add(
      ImportStatsFromJsonEvent(
        filePath: result.files.single.path!,
        mergeWithExisting: merge,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
