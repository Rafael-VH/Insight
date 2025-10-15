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
    final defaultBlue = Colors.blue[50]!;
    final defaultBlueBorder = Colors.blue[200]!;
    final defaultBlueIcon = Colors.blue[600]!;
    final defaultBlueText = Colors.blue[700]!;

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
