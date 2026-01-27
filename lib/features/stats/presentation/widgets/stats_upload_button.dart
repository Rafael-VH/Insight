import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/stats_upload_type.dart';

class StatsUploadButton extends StatelessWidget {
  const StatsUploadButton({
    super.key,
    required this.uploadType,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  final StatsUploadType uploadType;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Adaptar colores según tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? color.withValues(alpha: 0.2) : color;
    final gradientColor = isDark
        ? color.withValues(alpha: 0.3)
        : color.withValues(alpha: 0.8);
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundColor, gradientColor], // Colores adaptados
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildDescription(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Texto adaptado al tema
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.white;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uploadType.displayName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${uploadType.imageCount} imagen${uploadType.imageCount > 1 ? 'es' : ''}',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          color: textColor.withValues(alpha: 0.8),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      description,
      style: const TextStyle(
        color: Colors.white, // Siempre blanco sobre fondo de color
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}
