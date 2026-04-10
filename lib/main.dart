import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/injection/injection_container.dart' as di;
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/screens/main_screen.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_state.dart';
import 'package:insight/features/settings/presentation/config/theme_config.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_bloc.dart';

void main() {
  // Captura errores de Flutter (widgets, rendering, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint(details.toString());
  };

  // Captura errores fuera del contexto de Flutter (async, Dart puro)
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Orientación fija para evitar reflows durante el inicio
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await _initializeDependencies();
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('=== UNHANDLED ERROR ===');
      debugPrint('Error: $error');
      debugPrint('Stack: $stackTrace');
    },
  );
}

/// Inicialización de dependencias con manejo de errores y fallback
Future<void> _initializeDependencies() async {
  try {
    await di.init();
    debugPrint('✓ Dependencias inicializadas correctamente');
  } catch (e, stack) {
    debugPrint('✗ Error en di.init(): $e');
    debugPrint(stack.toString());
    // Re-lanzar para que runZonedGuarded lo capture y lo muestre
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ========== THEME BLOC (DEBE SER PRIMERO) ==========
        BlocProvider<ThemeBloc>(
          create: (context) => di.sl<ThemeBloc>()..add(LoadTheme()),
        ),

        // ========== SETTINGS BLOC (DEPENDE DE THEME) ==========
        BlocProvider<SettingsBloc>(
          create: (context) => di.sl<SettingsBloc>()..add(LoadSettings()),
        ),

        // ========== NAVIGATION BLOC ==========
        BlocProvider<NavigationBloc>(
          create: (context) => di.sl<NavigationBloc>(),
        ),

        // ========== ML STATS BLOC ==========
        BlocProvider<StatsBloc>(create: (context) => di.sl<StatsBloc>()),

        // ========== OCR BLOC ==========
        BlocProvider<OcrBloc>(create: (context) => di.sl<OcrBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          if (themeState is ThemeLoading || themeState is ThemeInitial) {
            return const _SplashApp();
          }

          if (themeState is ThemeError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Insight',
              theme: ThemeData.light(useMaterial3: true),
              darkTheme: ThemeData.dark(useMaterial3: true),
              themeMode: ThemeMode.system,
              home: const MainScreen(),
            );
          }

          if (themeState is ThemeLoaded) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Insight',
              theme: ThemeConfig.buildLightTheme(themeState.currentTheme),
              darkTheme: ThemeConfig.buildDarkTheme(themeState.currentTheme),
              themeMode: themeState.themeMode.flutterThemeMode,
              home: const MainScreen(),
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Insight',
            theme: ThemeData.light(useMaterial3: true),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

/// Splash minimalista mientras cargan las dependencias
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF059669),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights_rounded, size: 64, color: Colors.white),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
