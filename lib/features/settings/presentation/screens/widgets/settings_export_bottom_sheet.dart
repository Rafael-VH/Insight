import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:insight/features/stats/data/model/stats_collection_model.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';

/// Bottom sheet flotante que muestra un resumen de las estadísticas
/// actuales —colecciones totales, fecha más reciente y tamaño estimado
/// del archivo— y permite exportarlas a un archivo JSON.
///
/// Toda la lógica de exportación permanece en [StatsBloc]; este widget
/// solo calcula el tamaño estimado localmente antes de confirmar.
class SettingsExportBottomSheet extends StatefulWidget {
  const SettingsExportBottomSheet({super.key});

  /// Método de conveniencia para mostrar el bottom sheet desde cualquier
  /// pantalla. Reutiliza el [StatsBloc] del contexto padre.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StatsBloc>(),
        child: const SettingsExportBottomSheet(),
      ),
    );
  }

  @override
  State<SettingsExportBottomSheet> createState() =>
      _SettingsExportBottomSheetState();
}

class _SettingsExportBottomSheetState extends State<SettingsExportBottomSheet> {
  List<StatsCollection> _collections = [];
  bool _isLoadingPreview = true;
  bool _isExporting = false;

  /// Tamaño estimado del JSON en bytes, calculado localmente.
  /// Se computa una sola vez al cargar las colecciones.
  int _estimatedBytes = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<StatsBloc>().state;
    if (state is StatsCollectionsLoaded) {
      _initPreview(state.collections);
    } else {
      context.read<StatsBloc>().add(LoadAllStatsCollectionsEvent());
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Inicializa el resumen y calcula el tamaño estimado serializando
  /// las colecciones a JSON en memoria. No escribe ningún archivo.
  void _initPreview(List<StatsCollection> collections) {
    final estimatedBytes = _calculateJsonBytes(collections);
    setState(() {
      _collections = collections;
      _estimatedBytes = estimatedBytes;
      _isLoadingPreview = false;
    });
  }

  /// Serializa las colecciones al mismo formato que usa [StatsRepositoryImpl]
  /// y devuelve el tamaño en bytes sin tocar el disco.
  int _calculateJsonBytes(List<StatsCollection> collections) {
    try {
      final exportMap = <String, dynamic>{
        'version': '1.0',
        'app': 'Insight',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'totalCollections': collections.length,
        'collections': collections
            .map((c) => StatsCollectionModel.fromEntity(c).toJson())
            .toList(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);
      return utf8.encode(jsonString).length;
    } catch (_) {
      return 0;
    }
  }

  /// Formatea bytes a una cadena legible: B, KB o MB.
  String _formatSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
    return '$mb MB';
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  String get _latestDate {
    if (_collections.isEmpty) return '—';
    // Las colecciones ya llegan ordenadas de más reciente a más antigua.
    return _formatDate(_collections.first.createdAt);
  }

  // ── Acciones ─────────────────────────────────────────────

  void _export() {
    setState(() => _isExporting = true);
    context.read<StatsBloc>().add(
      ExportStatsToJsonEvent(collections: _collections),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<StatsBloc, StatsState>(
      listener: (context, state) {
        // Actualizamos el preview si acaba de cargar desde el BLoC.
        if (state is StatsCollectionsLoaded && _isLoadingPreview) {
          _initPreview(state.collections);
        }

        // Exportación completada → abrir menú nativo de compartir y cerrar.
        if (state is StatsExported) {
          Navigator.of(context, rootNavigator: true).pop();
          SharePlus.instance.share(
            ShareParams(
              files: [XFile(state.filePath)],
              subject: 'Insight — ${state.totalCollections} colección(es)',
              text: 'Backup de estadísticas de Mobile Legends',
            ),
          );
        }

        // Error durante exportación → cerrar el sheet (el BlocListener
        // de SettingsContent mostrará el snackbar de error).
        if (state is StatsError && _isExporting) {
          setState(() => _isExporting = false);
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
          _buildHeader(context, isDark),
          const SizedBox(height: 24),

          // Resumen informativo con los tres datos solicitados.
          if (_isLoadingPreview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            )
          else
            _buildSummaryCard(context, colorScheme, isDark),

          const SizedBox(height: 28),
          _buildExportButton(colorScheme),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(
              0xFF059669,
            ).withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.upload_file_rounded,
            size: 32,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Exportar estadísticas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Revisa el resumen y confirma para generar\nel archivo .json de respaldo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isEmpty = _collections.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: isEmpty
          // ── Estado vacío ──────────────────────────────────
          ? Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Text(
                  'No hay estadísticas para exportar',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            )
          // ── Resumen con los tres datos ────────────────────
          : Column(
              children: [
                _SummaryRow(
                  icon: Icons.library_books_outlined,
                  label: 'Colecciones a exportar',
                  value: '${_collections.length}',
                  valueColor: const Color(0xFF059669),
                ),
                _buildDivider(colorScheme),
                _SummaryRow(
                  icon: Icons.schedule_rounded,
                  label: 'Registro más reciente',
                  value: _latestDate,
                  valueColor: const Color(0xFF3B82F6),
                ),
                _buildDivider(colorScheme),
                _SummaryRow(
                  icon: Icons.folder_zip_outlined,
                  label: 'Tamaño estimado del archivo',
                  // El tamaño real puede diferir ligeramente porque
                  // StatsRepositoryImpl agrega metadatos de fecha al exportar,
                  // pero la diferencia es de unos pocos bytes.
                  value: _formatSize(_estimatedBytes),
                  valueColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildExportButton(ColorScheme colorScheme) {
    final isEmpty = _collections.isEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isExporting || isEmpty) ? null : _export,
        icon: _isExporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.ios_share_rounded),
        label: Text(_isExporting ? 'Exportando...' : 'Exportar y compartir'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: 0.12,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Widget interno de fila de resumen ────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: valueColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
