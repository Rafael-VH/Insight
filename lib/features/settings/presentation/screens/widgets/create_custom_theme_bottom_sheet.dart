import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/domain/entities/app_theme.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_state.dart';

class CreateCustomThemeBottomSheet extends StatefulWidget {
  const CreateCustomThemeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeBloc>(),
        child: const CreateCustomThemeBottomSheet(),
      ),
    );
  }

  @override
  State<CreateCustomThemeBottomSheet> createState() =>
      _CreateCustomThemeBottomSheetState();
}

class _CreateCustomThemeBottomSheetState
    extends State<CreateCustomThemeBottomSheet> {
  final _nameController = TextEditingController(text: 'Mi Tema Personalizado');
  final _formKey = GlobalKey<FormState>();

  Color _lightSeed = const Color(0xFF7C3AED);
  Color _darkSeed = const Color(0xFF9333EA);

  bool _previewLight = true;
  bool _isSaving = false;

  static const List<Color> _presetColors = [
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFF6366F1),
    Color(0xFF0F172A),
    Color(0xFF78716C),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  AppTheme _buildPreviewTheme() {
    return AppTheme(
      id: 'custom_preview',
      name: _nameController.text.isEmpty ? 'Mi Tema' : _nameController.text,
      lightColorScheme: ColorScheme.fromSeed(
        seedColor: _lightSeed,
        brightness: Brightness.light,
      ),
      darkColorScheme: ColorScheme.fromSeed(
        seedColor: _darkSeed,
        brightness: Brightness.dark,
      ),
      isCustom: true,
    );
  }

  String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).toUpperCase().substring(2)}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final theme = AppTheme(
      id: id,
      name: name,
      lightColorScheme: ColorScheme.fromSeed(
        seedColor: _lightSeed,
        brightness: Brightness.light,
      ),
      darkColorScheme: ColorScheme.fromSeed(
        seedColor: _darkSeed,
        brightness: Brightness.dark,
      ),
      isCustom: true,
    );

    setState(() => _isSaving = true);
    context.read<ThemeBloc>().add(SaveCustomTheme(theme));
  }

  // ── Color picker ─────────────────────────────────────────────
  Widget _buildColorPicker({
    required String label,
    required Color currentColor,
    required void Function(Color) onColorSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _colorToHex(currentColor),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            final isSelected = currentColor.value == color.value;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color:
                            ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Vista previa ──────────────────────────────────────────────
  Widget _buildPreview() {
    final preview = _buildPreviewTheme();
    final scheme = _previewLight
        ? preview.lightColorScheme
        : preview.darkColorScheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PreviewToggleBtn(
                label: 'Claro',
                isActive: _previewLight,
                onTap: () => setState(() => _previewLight = true),
              ),
              _PreviewToggleBtn(
                label: 'Oscuro',
                isActive: !_previewLight,
                onTap: () => setState(() => _previewLight = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // AppBar simulado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: _previewLight ? scheme.primary : scheme.surface,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.insights,
                        size: 16,
                        color: _previewLight
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Insight'
                          : _nameController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _previewLight
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Cuerpo simulado
              Container(
                padding: const EdgeInsets.all(12),
                color: scheme.surface,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PreviewChip(
                      label: 'Inicio',
                      bgColor: scheme.primary.withValues(alpha: 0.12),
                      textColor: scheme.primary,
                    ),
                    _PreviewChip(
                      label: 'Historial',
                      bgColor: scheme.primary,
                      textColor: scheme.onPrimary,
                    ),
                    _PreviewChip(
                      label: 'Config',
                      bgColor: scheme.primary.withValues(alpha: 0.12),
                      textColor: scheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Build principal ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ThemeBloc, ThemeState>(
      listener: (context, state) {
        if (state is ThemeLoaded && _isSaving) {
          // Fix: sin rootNavigator para no cerrar SettingsScreen
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tema personalizado guardado'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        if (state is ThemeError && _isSaving) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Tema Personalizado',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Elige colores para tu tema único',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nombre del tema
                Text(
                  'Nombre del tema',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Ej: Mi Tema Especial',
                    filled: true,
                    fillColor: isDark
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre no puede estar vacío';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Color modo claro
                _buildColorPicker(
                  label: 'Color primario — modo claro',
                  currentColor: _lightSeed,
                  onColorSelected: (color) =>
                      setState(() => _lightSeed = color),
                ),
                const SizedBox(height: 16),

                Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                const SizedBox(height: 16),

                // Color modo oscuro
                _buildColorPicker(
                  label: 'Color primario — modo oscuro',
                  currentColor: _darkSeed,
                  onColorSelected: (color) => setState(() => _darkSeed = color),
                ),
                const SizedBox(height: 20),

                Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                const SizedBox(height: 16),

                // Vista previa
                Text(
                  'Vista previa',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPreview(),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Tema',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────
class _PreviewToggleBtn extends StatelessWidget {
  const _PreviewToggleBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: colorScheme.outline.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
