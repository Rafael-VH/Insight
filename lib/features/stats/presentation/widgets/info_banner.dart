import 'package:flutter/material.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.textColor,
  });

  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    // Adaptar colores al tema
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBlue = isDark ? Colors.blue[900]! : Colors.blue[50]!;
    final defaultBlueBorder = isDark ? Colors.blue[700]! : Colors.blue[200]!;
    final defaultBlueIcon = isDark ? Colors.blue[300]! : Colors.blue[600]!;
    final defaultBlueText = isDark ? Colors.blue[200]! : Colors.blue[700]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? defaultBlueBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? defaultBlueIcon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? defaultBlueText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
