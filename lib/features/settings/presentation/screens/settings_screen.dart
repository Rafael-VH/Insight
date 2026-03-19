import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_event.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/stats/presentation/widgets/app_sliver_bar.dart';

// Widgets locales de esta pantalla
import 'widgets/settings_content.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverBar(
            title: 'Configuración',
            colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
            icon: Icons.settings,
          ),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is SettingsError) {
                return SliverFillRemaining(
                  child: _ErrorView(message: state.message),
                );
              }

              if (state is SettingsLoaded) {
                return SettingsContent(settings: state.settings);
              }

              return const SliverFillRemaining(
                child: Center(child: Text('Cargando...')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Vista de error interna — solo usada por este screen.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar configuración',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
