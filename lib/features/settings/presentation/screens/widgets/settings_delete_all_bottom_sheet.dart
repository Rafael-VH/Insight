import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/history/presentation/bloc/history_state.dart';

/// Bottom sheet de eliminación total desde el módulo Settings.
///
/// Migrado para consumir [HistoryBloc] en lugar del antiguo [StatsBloc].
class SettingsDeleteAllBottomSheet extends StatefulWidget {
  const SettingsDeleteAllBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HistoryBloc>(),
        child: const SettingsDeleteAllBottomSheet(),
      ),
    );
  }

  @override
  State<SettingsDeleteAllBottomSheet> createState() =>
      _SettingsDeleteAllBottomSheetState();
}

class _SettingsDeleteAllBottomSheetState
    extends State<SettingsDeleteAllBottomSheet> {
  int _step = 0;
  bool _isDeleting = false;
  int _totalCollections = 0;
  bool _loadingCount = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<HistoryBloc>().state;
    if (state is HistoryCollectionsLoaded) {
      _totalCollections = state.collections.length;
      _loadingCount = false;
    } else {
      context.read<HistoryBloc>().add(LoadAllStatsCollectionsEvent());
    }
  }

  void _confirmDelete() {
    setState(() => _isDeleting = true);
    context.read<HistoryBloc>().add(ClearAllStatsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryBloc, HistoryState>(
      listener: (context, state) {
        if (state is HistoryCollectionsLoaded && _loadingCount) {
          setState(() {
            _totalCollections = state.collections.length;
            _loadingCount = false;
          });
        }

        if (state is HistoryCleared) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (state is HistoryError && _isDeleting) {
          setState(() => _isDeleting = false);
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: _step == 0
          ? _buildWarningStep(context)
          : _buildConfirmStep(context),
    );
  }

  // ── Paso 1: Advertencia ──────────────────────────────────────

  Widget _buildWarningStep(BuildContext context) {
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              size: 32,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Eliminar todo el historial',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Esta acción es permanente y no se puede deshacer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildImpactCard(colorScheme, isDark),
          const SizedBox(height: 24),
          _buildExportSuggestion(colorScheme, isDark),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingCount || _totalCollections == 0
                  ? null
                  : () => setState(() => _step = 1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continuar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildImpactCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: isDark ? 0.4 : 0.25),
        ),
      ),
      child: _loadingCount
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.library_books_outlined,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Se eliminarán permanentemente',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_totalCollections colección'
                        '${_totalCollections == 1 ? '' : 'es'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExportSuggestion(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF059669)
            .withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF059669)
              .withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF059669),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Consejo: Exporta tus estadísticas antes de eliminarlas '
              'para poder restaurarlas después.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paso 2: Confirmación final ───────────────────────────────

  Widget _buildConfirmStep(BuildContext context) {
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 36,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '¿Estás completamente seguro?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Estás a punto de eliminar $_totalCollections '
            'colección${_totalCollections == 1 ? '' : 'es'}.\n'
            'Esta acción no tiene vuelta atrás.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDeleting ? null : _confirmDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever_rounded),
              label: Text(
                _isDeleting ? 'Eliminando...' : 'Sí, eliminar todo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed:
                _isDeleting ? null : () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Volver'),
            style: TextButton.styleFrom(
              foregroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.6),
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
}
