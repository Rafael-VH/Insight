import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/injection/injection_container.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_bloc.dart';
import 'package:insight/features/heroes/presentation/screens/hero_list_screen.dart';
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/screens/history_screen.dart';
import 'package:insight/features/navigation/domain/entities/navigation_item.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_state.dart';
import 'package:insight/features/settings/presentation/screens/settings_screen.dart';
import 'package:insight/features/upload/presentation/screens/home/upload_home_screen.dart';

import 'widgets/main_back_handler.dart';
import 'widgets/main_navigation_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late final List<NavigationItem> _navigationItems;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Clave global del Scaffold para controlar el drawer programáticamente
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  // ── Inicialización ────────────────────────────────────────────

  void _initializeNavigationItems() {
    _navigationItems = [
      // ── General ──────────────────────────────────────────────
      NavigationItem(
        id: 'home',
        title: 'Inicio',
        icon: Icons.home_rounded,
        color: const Color(0xFF3B82F6),
        page: const UploadHomeScreen(),
        section: 'General',
      ),
      NavigationItem(
        id: 'history',
        title: 'Historial',
        icon: Icons.history_rounded,
        color: const Color(0xFF059669),
        // HistoryBloc ya está en el árbol de widgets desde main.dart.
        // BlocProvider.value lo hace disponible para HistoryScreen y
        // todos sus hijos (bottom sheets, diálogos, etc.).
        page: BlocProvider.value(value: sl<HistoryBloc>(), child: const HistoryScreen()),
        section: 'General',
      ),

      // ── Enciclopedia ──────────────────────────────────────────
      NavigationItem(
        id: 'heroes',
        title: 'Héroes',
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFFDC2626),
        page: BlocProvider.value(value: sl<HeroBloc>(), child: const HeroListScreen()),
        section: 'Enciclopedia',
      ),
      // Próximas secciones — páginas placeholder hasta implementarlas
      NavigationItem(
        id: 'items',
        title: 'Ítems',
        icon: Icons.shield_rounded,
        color: const Color(0xFF7C3AED),
        page: const _PlaceholderPage(title: 'Ítems', icon: Icons.shield_rounded),
        section: 'Enciclopedia',
        badge: 'Pronto',
      ),
      NavigationItem(
        id: 'academy',
        title: 'Academia',
        icon: Icons.school_rounded,
        color: const Color(0xFFF59E0B),
        page: const _PlaceholderPage(title: 'Academia', icon: Icons.school_rounded),
        section: 'Enciclopedia',
        badge: 'Pronto',
      ),
      NavigationItem(
        id: 'rankings',
        title: 'Rankings',
        icon: Icons.leaderboard_rounded,
        color: const Color(0xFFEC4899),
        page: const _PlaceholderPage(title: 'Rankings', icon: Icons.leaderboard_rounded),
        section: 'Enciclopedia',
        badge: 'Pronto',
      ),

      // ── App ───────────────────────────────────────────────────
      NavigationItem(
        id: 'settings',
        title: 'Configuración',
        icon: Icons.settings_rounded,
        color: const Color(0xFF6B7280),
        // SettingsScreen necesita HistoryBloc para los bottom sheets
        // de exportar, importar y eliminar. Se propaga con .value
        // para reutilizar la misma instancia del árbol raíz.
        page: BlocProvider.value(value: sl<HistoryBloc>(), child: const SettingsScreen()),
        section: 'App',
      ),
    ];
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  // ── Acciones ──────────────────────────────────────────────────

  void _handleTabChange(int index) {
    _animationController.reverse().then((_) {
      context.read<NavigationBloc>().add(NavigationItemSelected(index));
      _animationController.forward();
    });
  }

  void _handleNavigationStateChanges(BuildContext context, NavigationState state) {
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

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: _handleNavigationStateChanges,
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          final currentIndex = state.currentIndex;

          return MainBackHandler(
            child: Scaffold(
              key: _scaffoldKey,
              // ── Drawer lateral ────────────────────────────────
              drawer: MainNavigationDrawer(
                items: _navigationItems,
                currentIndex: currentIndex,
                onItemSelected: _handleTabChange,
              ),
              // ── AppBar con botón hamburguesa ──────────────────
              appBar: _buildAppBar(currentIndex),
              // ── Contenido principal ───────────────────────────
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: IndexedStack(
                  index: currentIndex,
                  children: _navigationItems.map((item) => item.page).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int currentIndex) {
    final item = _navigationItems[currentIndex];

    return AppBar(
      // El botón hamburguesa abre el drawer
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Menú',
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          Icon(item.icon, size: 20, color: item.color),
          const SizedBox(width: 10),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        ],
      ),
      // Indicador de color de la sección activa
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.color.withValues(alpha: 0.7), item.color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Página placeholder ────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Próximamente disponible',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
