import 'package:flutter/material.dart';

/// Tile informativo de solo lectura, con navegación opcional al presionarlo.
/// Acepta [iconColor] y [titleColor] opcionales para destacar visualmente
/// acciones destructivas (como eliminar todo el historial).
class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// Color personalizado para el ícono. Por defecto usa el color de la superficie.
  final Color? iconColor;

  /// Color personalizado para el título. Por defecto usa [ColorScheme.onSurface].
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? colorScheme.onSurface.withValues(alpha: 0.7);
    final resolvedContainerColor = iconColor != null
        ? iconColor!.withValues(alpha: 0.1)
        : colorScheme.onSurface.withValues(alpha: 0.08);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: resolvedContainerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: resolvedIconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? colorScheme.onSurface,
          fontWeight: titleColor != null ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
