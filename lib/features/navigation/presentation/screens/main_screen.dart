import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/domain/entities/navigation_item.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_state.dart';
import 'package:insight/features/settings/presentation/screens/settings_screen.dart';
import 'package:insight/features/stats/presentation/screens/history/history_screen.dart';
import 'package:insight/features/stats/presentation/screens/home/home_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

/// Pantalla principal que gestiona la navegación entre secciones
///
/// Utiliza:
/// - NavigationBloc para gestionar el estado
/// - IndexedStack para mantener el estado de las páginas
/// - SalomonBottomBar para una navegación visual atractiva
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

  /// Inicializa los items de navegación
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

  /// Inicializa las animaciones
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

  /// Maneja el cambio de pestaña con animación
  void _handleTabChange(int index) {
    // Iniciar animación de salida
    _animationController.reverse().then((_) {
      // Cambiar de pestaña
      context.read<NavigationBloc>().add(NavigationItemSelected(index));

      // Animar entrada
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: _handleNavigationStateChanges,
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          return WillPopScope(
            onWillPop: _handleBackPress,
            child: Scaffold(
              body: _buildBody(state),
              bottomNavigationBar: _buildBottomNavigationBar(state),
            ),
          );
        },
      ),
    );
  }

  /// Construye el cuerpo de la pantalla
  Widget _buildBody(NavigationState state) {
    final currentIndex = state.currentIndex;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: IndexedStack(
        index: currentIndex,
        children: _navigationItems.map((item) => item.page).toList(),
      ),
    );
  }

  /// Construye el bottom navigation bar
  Widget _buildBottomNavigationBar(NavigationState state) {
    final currentIndex = state.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
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
            onTap: _handleTabChange,
            selectedItemColor: _navigationItems[currentIndex].color,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
            items: _buildBottomBarItems(),
          ),
        ),
      ),
    );
  }

  /// Construye los items del bottom bar
  List<SalomonBottomBarItem> _buildBottomBarItems() {
    final navigationBloc = context.read<NavigationBloc>();

    return _navigationItems.asMap().entries.map((entry) {
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
                  decoration: BoxDecoration(
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

  /// Maneja los cambios de estado de navegación
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

  /// Maneja el botón de retroceso del sistema
  Future<bool> _handleBackPress() async {
    final navigationBloc = context.read<NavigationBloc>();

    if (navigationBloc.canGoBack) {
      navigationBloc.add(const NavigateBack());
      return false; // No cerrar la app
    } else if (navigationBloc.currentIndex != 0) {
      navigationBloc.add(const NavigationItemSelected(0));
      return false; // No cerrar la app
    }

    // Mostrar diálogo de confirmación para salir
    return await _showExitConfirmation() ?? false;
  }

  /// Muestra diálogo de confirmación para salir
  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la aplicación'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
