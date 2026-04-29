import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/injection/injection_container.dart' as di;
import 'package:insight/core/presentation/splash/splash_screen.dart';
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/screens/main_screen.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_state.dart';
import 'package:insight/features/settings/presentation/config/theme_config.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:insight/features/upload/presentation/bloc/upload_bloc.dart';

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
        // ── Theme (primero) ──────────────────────────────────
        BlocProvider<ThemeBloc>(create: (_) => di.sl<ThemeBloc>()..add(LoadTheme())),

        // ── Settings ─────────────────────────────────────────
        BlocProvider<SettingsBloc>(create: (_) => di.sl<SettingsBloc>()..add(LoadSettings())),

        // ── Navigation ────────────────────────────────────────
        BlocProvider<NavigationBloc>(create: (_) => di.sl<NavigationBloc>()),

        // ── History ───────────────────────────────────────────
        // LazySingleton → la misma instancia en toda la app.
        // Se precarga la lista al iniciar para que la tab de
        // Historial esté lista sin espera perceptible.
        BlocProvider<HistoryBloc>(
          create: (_) => di.sl<HistoryBloc>()..add(LoadAllStatsCollectionsEvent()),
        ),

        // ── Stats (solo guardado post-OCR) ────────────────────
        BlocProvider<UploadBloc>(create: (_) => di.sl<UploadBloc>()),

        // ── OCR ───────────────────────────────────────────────
        BlocProvider<OcrBloc>(create: (_) => di.sl<OcrBloc>()),
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
              home: const SplashScreen(),
            );
          }

          if (themeState is ThemeLoaded) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Insight',
              theme: ThemeConfig.buildLightTheme(themeState.currentTheme),
              darkTheme: ThemeConfig.buildDarkTheme(themeState.currentTheme),
              themeMode: themeState.themeMode.flutterThemeMode,
              home: const SplashScreen(),
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
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
