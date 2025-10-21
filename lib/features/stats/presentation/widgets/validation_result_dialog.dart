import 'package:flutter/material.dart';
//
import 'package:insight/core/utils/stats_validator.dart';

/// Diálogo que muestra los resultados de validación de estadísticas
class ValidationResultDialog extends StatelessWidget {
  const ValidationResultDialog({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onAccept,
    this.useAwesome = true,
  });

  final ValidationResult result;
  final VoidCallback onRetry;
  final VoidCallback onAccept;
  final bool useAwesome;

  @override
  Widget build(BuildContext context) {
    if (useAwesome) {
      return _buildAwesomeDialog(context);
    } else {
      return _buildClassicDialog(context);
    }
  }

  /// Construcción del diálogo clásico
  Widget _buildClassicDialog(BuildContext context) {
    // CORRECCIÓN: Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface, // Adaptado
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildCompletionIndicator(context),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (result.missingFields.isNotEmpty) ...[
                      _buildMissingFieldsSection(context),
                      const SizedBox(height: 16),
                    ],
                    if (result.warningFields.isNotEmpty) ...[
                      _buildWarningsSection(context),
                      const SizedBox(height: 16),
                    ],
                    _buildRecommendations(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildClassicActions(context),
          ],
        ),
      ),
    );
  }

  /// Construcción del diálogo con Awesome Snackbar
  Widget _buildAwesomeDialog(BuildContext context) {
    // CORRECCIÓN: Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 550),
        decoration: BoxDecoration(
          color: colorScheme.surface, // Adaptado
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header mejorado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getHeaderColor().withOpacity(isDark ? 0.3 : 0.1),
                    _getHeaderColor().withOpacity(isDark ? 0.15 : 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Icon(_getHeaderIcon(), size: 56, color: _getHeaderColor()),
                  const SizedBox(height: 12),
                  Text(
                    _getHeaderTitle(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getHeaderColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompletionIndicator(context),
                    const SizedBox(height: 16),
                    if (result.missingFields.isNotEmpty) ...[
                      _buildAwesomeMissingFields(context),
                      const SizedBox(height: 12),
                    ],
                    if (result.warningFields.isNotEmpty) ...[
                      _buildAwesomeWarnings(context),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // Botones mejorados
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAwesomeActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHeaderColor() {
    if (result.isValid && result.warningFields.isEmpty) {
      return Colors.green;
    } else if (result.isValid) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getHeaderIcon() {
    if (result.isValid && result.warningFields.isEmpty) {
      return Icons.check_circle_outline;
    } else if (result.isValid) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.error_outline;
    }
  }

  String _getHeaderTitle() {
    if (result.isValid && result.warningFields.isEmpty) {
      return 'Extracción Exitosa';
    } else if (result.isValid) {
      return 'Extracción con Advertencias';
    } else {
      return 'Extracción Incompleta';
    }
  }

  Widget _buildHeader(BuildContext context) {
    final IconData icon;
    final Color color;
    final String title;

    if (result.isValid && result.warningFields.isEmpty) {
      icon = Icons.check_circle;
      color = Colors.green;
      title = 'Extracción Exitosa';
    } else if (result.isValid) {
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
      title = 'Extracción con Advertencias';
    } else {
      icon = Icons.error_outline;
      color = Colors.red;
      title = 'Extracción Incompleta';
    }

    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletionIndicator(BuildContext context) {
    // CORRECCIÓN: Colores adaptados
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = result.completionPercentage;
    final Color color;

    if (percentage >= 90) {
      color = Colors.green;
    } else if (percentage >= 70) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completitud de Datos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface, // Adaptado
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: isDark
                ? colorScheme.surfaceContainerHighest
                : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${result.validFields} de ${result.totalFields} campos detectados',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6), // Adaptado
          ),
        ),
      ],
    );
  }

  Widget _buildAwesomeMissingFields(BuildContext context) {
    // CORRECCIÓN: Colores adaptados
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[isDark ? 900 : 50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[isDark ? 700 : 200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.close,
                color: Colors.red[isDark ? 300 : 700],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Datos Faltantes (${result.missingFields.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[isDark ? 300 : 900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...result.missingFields
              .take(4)
              .map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 6,
                        color: Colors.red[isDark ? 300 : 700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          field,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[isDark ? 200 : 900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (result.missingFields.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... y ${result.missingFields.length - 4} más',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.red[isDark ? 300 : 700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAwesomeWarnings(BuildContext context) {
    // CORRECCIÓN: Colores adaptados
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[isDark ? 900 : 50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[isDark ? 700 : 200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange[isDark ? 300 : 700],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Campos en 0 (${result.warningFields.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[isDark ? 300 : 900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...result.warningFields
              .take(3)
              .map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 6,
                        color: Colors.orange[isDark ? 300 : 700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          field,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[isDark ? 200 : 900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (result.warningFields.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... y ${result.warningFields.length - 3} más',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange[isDark ? 300 : 700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissingFieldsSection(BuildContext context) {
    // CORRECCIÓN: Colores adaptados
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[isDark ? 900 : 50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[isDark ? 700 : 200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[isDark ? 300 : 700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Datos Faltantes (${result.missingFields.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[isDark ? 300 : 900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...result.missingFields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red[isDark ? 300 : 700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      field,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[isDark ? 200 : 900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection(BuildContext context) {
    // CORRECCIÓN: Colores adaptados
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayWarnings = result.warningFields.take(6).toList();
    final hasMore = result.warningFields.length > 6;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[isDark ? 900 : 50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[isDark ? 700 : 200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange[isDark ? 300 : 700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Campos en 0 (${result.warningFields.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[isDark ? 300 : 900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estos campos pueden ser legítimamente 0:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[isDark ? 200 : 800],
            ),
          ),
          const SizedBox(height: 8),
          ...displayWarnings.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    size: 8,
                    color: Colors.orange[isDark ? 300 : 700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      field,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[isDark ? 200 : 900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... y ${result.warningFields.length - 6} más',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange[isDark ? 300 : 700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    // CORRECCIÓN: Colores adaptados
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recommendations = StatsValidator.getRecommendations(result);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[isDark ? 900 : 50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[isDark ? 700 : 200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[isDark ? 300 : 700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[isDark ? 300 : 900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[isDark ? 300 : 700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[isDark ? 200 : 900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!result.isValid) ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar Captura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (result.isValid)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
            icon: const Icon(Icons.check),
            label: const Text('Aceptar y Continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildAwesomeActions(BuildContext context) {
    return Row(
      children: [
        if (!result.isValid) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: result.isValid
              ? ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccept();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aceptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              : TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required ValidationResult result,
    required VoidCallback onRetry,
    required VoidCallback onAccept,
    bool useAwesome = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValidationResultDialog(
        result: result,
        onRetry: onRetry,
        onAccept: onAccept,
        useAwesome: useAwesome,
      ),
    );
  }
}
