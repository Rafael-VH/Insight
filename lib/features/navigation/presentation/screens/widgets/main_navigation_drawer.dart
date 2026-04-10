import 'package:flutter/material.dart';
import 'package:insight/features/navigation/domain/entities/navigation_item.dart';

/// Drawer lateral con agrupación por secciones y soporte de badges.
///
/// Renderiza automáticamente un encabezado de sección (`Text` estilo
/// overline) cada vez que el campo [NavigationItem.section] cambia
/// respecto al ítem anterior. Esto permite agrupar visualmente
/// "General", "Enciclopedia", "App", etc.
class MainNavigationDrawer extends StatelessWidget {
  const MainNavigationDrawer({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<NavigationItem> items;
  final int currentIndex;
  final void Function(int index) onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationDrawer(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        // Cerrar el drawer antes de cambiar la página
        Navigator.of(context).pop();
        onItemSelected(index);
      },
      children: _buildChildren(context, colorScheme, isDark),
    );
  }

  List<Widget> _buildChildren(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final children = <Widget>[];

    // ── Encabezado del drawer ────────────────────────────────────
    children.add(_DrawerHeader(colorScheme: colorScheme, isDark: isDark));

    String? lastSection;
    int destinationIndex = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // Insertar encabezado de sección cuando cambia el grupo
      if (item.section != null && item.section != lastSection) {
        if (lastSection != null) {
          // Divisor entre secciones (excepto antes de la primera)
          children.add(const Divider(indent: 16, endIndent: 16, height: 1));
        }
        children.add(_SectionLabel(label: item.section!));
        lastSection = item.section;
      }

      children.add(
        NavigationDrawerDestination(
          icon: _buildIcon(item, destinationIndex, colorScheme, false),
          selectedIcon: _buildIcon(item, destinationIndex, colorScheme, true),
          label: _buildLabel(context, item),
        ),
      );
      destinationIndex++;
    }

    return children;
  }

  Widget _buildIcon(
    NavigationItem item,
    int index,
    ColorScheme colorScheme,
    bool selected,
  ) {
    // Obtener badge del BLoC si no está en el item
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(item.icon, color: selected ? item.color : null),
        if (item.badge != null)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, NavigationItem item) {
    // Si no hay badge de texto extenso, devolver solo el título
    if (item.badge == null) {
      return Text(item.title);
    }
    return Row(
      children: [
        Text(item.title),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.badge!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets internos del drawer ───────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.colorScheme, required this.isDark});

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / ícono de la app
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Insight',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'ML Stats OCR',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
