import 'package:flutter/material.dart';

/// Tile con switch para configuraciones booleanas.
///
/// Cuando [onPreviewStyle] no es null, al cambiar el switch se ejecuta
/// dicho callback para mostrar una previsualización del nuevo estilo
/// (usado exclusivamente por la opción "Diálogos Mejorados").
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onPreviewStyle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Callback opcional para mostrar preview del estilo al activar/desactivar.
  /// Recibe el nuevo valor del switch.
  final void Function(BuildContext context, bool enabled)? onPreviewStyle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          onChanged(newValue);
          onPreviewStyle?.call(context, newValue);
        },
      ),
    );
  }
}
