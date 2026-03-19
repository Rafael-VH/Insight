import 'package:flutter/material.dart';

class UploadAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UploadAppBar({
    super.key,
    required this.title,
    required this.hasStats,
    required this.onShowSummary,
  });

  final String title;
  final bool hasStats;
  final VoidCallback onShowSummary;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (hasStats)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: onShowSummary,
            tooltip: 'Ver resumen de validación',
          ),
      ],
    );
  }
}
