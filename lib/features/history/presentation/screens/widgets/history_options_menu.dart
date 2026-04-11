import 'package:flutter/material.dart';
import 'package:insight/features/history/presentation/screens/widgets/history_export_import_bottom_sheet.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/screens/charts/charts_screen.dart';

class HistoryOptionsMenu {
  const HistoryOptionsMenu._();

  static void show({
    required BuildContext context,
    required StatsCollection collection,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.more_horiz, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 12),
                  Text(
                    'Opciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            _OptionTile(
              icon: Icons.bar_chart_rounded,
              color: colorScheme.primary,
              label: 'Ver Gráficos',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChartsScreen(collection: collection)),
                );
              },
            ),
            _OptionTile(
              icon: Icons.import_export_rounded,
              color: Colors.teal,
              label: 'Exportar / Importar',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                HistoryExportImportBottomSheet.show(context);
              },
            ),
            _OptionTile(
              icon: Icons.edit,
              color: const Color(0xFF059669),
              label: 'Cambiar Nombre',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                onRename();
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline,
              color: Colors.red,
              label: 'Eliminar',
              labelColor: Colors.red,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: TextStyle(color: labelColor ?? colorScheme.onSurface)),
      onTap: onTap,
    );
  }
}
