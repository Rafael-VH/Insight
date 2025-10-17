// lib/core/navigation/presentation/pages/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/stats/domain/entities/navigation_item.dart';
//
import 'package:insight/stats/presentation/bloc/navigation_bloc.dart';
import 'package:insight/stats/presentation/bloc/navigation_event.dart';
import 'package:insight/stats/presentation/bloc/navigation_state.dart';
import 'package:insight/stats/presentation/screens/History/history_screen.dart';
//
import 'package:insight/stats/presentation/screens/Home/home_screen.dart';
import 'package:insight/stats/presentation/screens/Setting/settings_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _initializeNavigationItems();
  }

  void _initializeNavigationItems() {
    _navigationItems = [
      NavigationItem(
        title: 'Inicio',
        icon: Icons.home_rounded,
        color: const Color(0xFF3B82F6),
        page: const HomeScreen(),
      ),
      NavigationItem(
        title: 'Historial',
        icon: Icons.history_rounded,
        color: const Color(0xFF059669),
        page: const HistoryScreen(),
      ),
      NavigationItem(
        title: 'Configuración',
        icon: Icons.settings_rounded,
        color: const Color(0xFF7C3AED),
        page: const SettingsScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        final currentIndex = context.read<NavigationBloc>().currentIndex;

        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: _navigationItems.map((item) => item.page).toList(),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SalomonBottomBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    context.read<NavigationBloc>().add(
                      NavigationItemSelected(index),
                    );
                  },
                  items: _navigationItems
                      .map(
                        (item) => SalomonBottomBarItem(
                          icon: Icon(item.icon),
                          title: Text(item.title),
                          selectedColor: item.color,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
