import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/domain/entities/navigation_item.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MainBottomBar extends StatelessWidget {
  const MainBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavigationItem> items;
  final int currentIndex;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SalomonBottomBar(
            currentIndex: currentIndex,
            onTap: onTap,
            selectedItemColor: items[currentIndex].color,
            unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
            items: _buildItems(context),
          ),
        ),
      ),
    );
  }

  List<SalomonBottomBarItem> _buildItems(BuildContext context) {
    final navigationBloc = context.read<NavigationBloc>();

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final badge = navigationBloc.getBadge(index);

      return SalomonBottomBarItem(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(item.icon),
            if (badge != null)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(item.title),
        selectedColor: item.color,
      );
    }).toList();
  }
}
