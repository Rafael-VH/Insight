import 'package:flutter/material.dart';
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
import 'package:insight/features/stats/presentation/bloc/stats/ml_stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
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
        BlocProvider<MLStatsBloc>(create: (context) => di.sl<MLStatsBloc>()),

        // ========== OCR BLOC ==========
        BlocProvider<OcrBloc>(create: (context) => di.sl<OcrBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          // Mientras carga el tema, mostrar splash
          if (themeState is ThemeLoading || themeState is ThemeInitial) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          // Si hay error, usar tema por defecto
          if (themeState is ThemeError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ML Stats OCR',
              theme: ThemeData.light(useMaterial3: true),
              darkTheme: ThemeData.dark(useMaterial3: true),
              themeMode: ThemeMode.system,
              home: const MainScreen(),
            );
          }

          // Tema cargado correctamente
          if (themeState is ThemeLoaded) {
            final appTheme = themeState.currentTheme;
            final themeMode = themeState.themeMode.flutterThemeMode;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ML Stats OCR',

              // Temas personalizados
              theme: ThemeConfig.buildLightTheme(appTheme),
              darkTheme: ThemeConfig.buildDarkTheme(appTheme),
              themeMode: themeMode,

              home: const MainScreen(),
            );
          }

          // Fallback
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ML Stats OCR',
            theme: ThemeData.light(useMaterial3: true),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
