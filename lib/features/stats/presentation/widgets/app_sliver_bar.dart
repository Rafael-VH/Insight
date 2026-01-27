import 'package:flutter/material.dart';

class AppSliverBar extends StatelessWidget {
  const AppSliverBar({
    super.key,
    required this.title,
    required this.colors,
    this.actions,
    this.expandedHeight = 120.0,
    this.icon,
    this.iconSize = 80.0,
  });

  final String title;
  final List<Color> colors;
  final List<Widget>? actions;
  final double expandedHeight;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: colors.first,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: icon != null
              ? Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
