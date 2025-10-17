import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/core/injection/injection_container.dart' as di;
//
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/navigation_bloc.dart';
import 'package:insight/stats/presentation/bloc/ocr_bloc.dart';
import 'package:insight/stats/presentation/bloc/theme_bloc.dart';
//
import 'package:insight/stats/presentation/config/theme_config.dart';
import 'package:insight/stats/presentation/screens/Main/main_screen.dart';

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
        // Bloc de estadísticas
        BlocProvider<MLStatsBloc>(create: (context) => di.sl<MLStatsBloc>()),

        // Bloc de OCR
        BlocProvider<OcrBloc>(create: (context) => di.sl<OcrBloc>()),

        // Bloc de temas
        BlocProvider<ThemeBloc>(
          create: (context) => di.sl<ThemeBloc>()..add(LoadTheme()),
        ),

        // Bloc de navegación (NUEVO)
        BlocProvider<NavigationBloc>(
          create: (context) => di.sl<NavigationBloc>(),
        ),
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
