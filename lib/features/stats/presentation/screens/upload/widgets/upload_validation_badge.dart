import 'package:flutter/material.dart';
import 'package:insight/core/utils/stats_validator.dart';

class UploadValidationBadge extends StatelessWidget {
  const UploadValidationBadge({
    super.key,
    required this.validation,
    required this.onTap,
  });

  final ValidationResult validation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final IconData icon;
    final Color color;

    if (validation.isValid && validation.warningFields.isEmpty) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (validation.isValid) {
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      icon = Icons.error;
      color = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
