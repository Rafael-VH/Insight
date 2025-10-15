import 'package:flutter/material.dart';
import 'package:insight/core/utils/stats_validator.dart';

/// Diálogo que muestra los resultados de validación de estadísticas
class ValidationResultDialog extends StatelessWidget {
  const ValidationResultDialog({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onAccept,
  });

  final ValidationResult result;
  final VoidCallback onRetry;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCompletionIndicator(),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (result.missingFields.isNotEmpty) ...[
                      _buildMissingFieldsSection(),
                      const SizedBox(height: 16),
                    ],
                    if (result.warningFields.isNotEmpty) ...[
                      _buildWarningsSection(),
                      const SizedBox(height: 16),
                    ],
                    _buildRecommendations(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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

  Widget _buildCompletionIndicator() {
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
                color: Colors.grey[700],
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
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${result.validFields} de ${result.totalFields} campos detectados',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMissingFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Datos Faltantes (${result.missingFields.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
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
                  Icon(Icons.close, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      field,
                      style: TextStyle(fontSize: 13, color: Colors.red[900]),
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

  Widget _buildWarningsSection() {
    // Mostrar solo los primeros 6 warnings
    final displayWarnings = result.warningFields.take(6).toList();
    final hasMore = result.warningFields.length > 6;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Campos en 0 (${result.warningFields.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estos campos pueden ser legítimamente 0:',
            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
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
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      field,
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
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
                  color: Colors.orange[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = StatsValidator.getRecommendations(result);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
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
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(fontSize: 13, color: Colors.blue[900]),
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

  Widget _buildActions(BuildContext context) {
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

  /// Método estático para mostrar el diálogo
  static Future<void> show({
    required BuildContext context,
    required ValidationResult result,
    required VoidCallback onRetry,
    required VoidCallback onAccept,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValidationResultDialog(
        result: result,
        onRetry: onRetry,
        onAccept: onAccept,
      ),
    );
  }
}
