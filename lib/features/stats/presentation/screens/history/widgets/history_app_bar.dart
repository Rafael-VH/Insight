import 'package:flutter/material.dart';
import 'package:insight/features/stats/presentation/widgets/app_sliver_bar.dart';
import 'package:insight/features/stats/presentation/widgets/export_import_bottom_sheet.dart';

class HistoryAppBar extends StatelessWidget {
  const HistoryAppBar({
    super.key,
    required this.sortBy,
    required this.isAscending,
    required this.onRefresh,
    required this.onToggleSort,
  });

  final String sortBy;
  final bool isAscending;
  final VoidCallback onRefresh;
  final void Function(String sortType) onToggleSort;

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return AppSliverBar(
      title: 'Historial de Estadísticas',
      colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      expandedHeight: isKeyboardVisible ? 60.0 : 100.0,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            sortBy == 'date' ? Icons.calendar_today : Icons.sort_by_alpha,
          ),
          tooltip: 'Ordenar',
          onSelected: (value) => onToggleSort(value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'date',
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: sortBy == 'date'
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Por Fecha',
                    style: TextStyle(
                      fontWeight: sortBy == 'date'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'name',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha,
                    color: sortBy == 'name'
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Por Nombre',
                    style: TextStyle(
                      fontWeight: sortBy == 'name'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  const SizedBox(width: 12),
                  Text(isAscending ? 'Ascendente' : 'Descendente'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.import_export_rounded),
          onPressed: () => ExportImportBottomSheet.show(context),
          tooltip: 'Exportar / Importar',
        ),
      ],
    );
  }
}
