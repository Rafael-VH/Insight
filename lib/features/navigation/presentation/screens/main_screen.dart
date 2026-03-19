import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/domain/entities/navigation_item.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_state.dart';
import 'package:insight/features/settings/presentation/screens/settings_screen.dart';
import 'package:insight/features/stats/presentation/screens/history/history_screen.dart';
import 'package:insight/features/stats/presentation/screens/home/home_screen.dart';

// Widgets locales de esta pantalla
import 'widgets/main_back_handler.dart';
import 'widgets/main_bottom_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final List<NavigationItem> _navigationItems;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _initializeNavigationItems();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==================== INICIALIZACIÓN ====================

  void _initializeNavigationItems() {
    _navigationItems = [
      NavigationItem(
        id: 'home',
        title: 'Inicio',
        icon: Icons.home_rounded,
        color: const Color(0xFF3B82F6),
        page: const HomeScreen(),
      ),
      NavigationItem(
        id: 'history',
        title: 'Historial',
        icon: Icons.history_rounded,
        color: const Color(0xFF059669),
        page: const HistoryScreen(),
      ),
      NavigationItem(
        id: 'settings',
        title: 'Configuración',
        icon: Icons.settings_rounded,
        color: const Color(0xFF7C3AED),
        page: const SettingsScreen(),
      ),
    ];
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  // ==================== ACCIONES ====================

  void _handleTabChange(int index) {
    _animationController.reverse().then((_) {
      context.read<NavigationBloc>().add(NavigationItemSelected(index));
      _animationController.forward();
    });
  }

  void _handleNavigationStateChanges(
    BuildContext context,
    NavigationState state,
  ) {
    if (state is NavigationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: _handleNavigationStateChanges,
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          return MainBackHandler(
            child: Scaffold(
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: IndexedStack(
                  index: state.currentIndex,
                  children: _navigationItems.map((item) => item.page).toList(),
                ),
              ),
              bottomNavigationBar: MainBottomBar(
                items: _navigationItems,
                currentIndex: state.currentIndex,
                onTap: _handleTabChange,
              ),
            ),
          );
        },
      ),
    );
  }
}
