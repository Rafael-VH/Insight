// lib/features/ml_stats/presentation/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:insight/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/stats/presentation/pages/stats_history_screen.dart';
import 'package:insight/stats/presentation/pages/stats_upload_screen.dart';

class MLStatsHomeScreen extends StatelessWidget {
  const MLStatsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar con SliverAppBar para mejor experiencia
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Mobile Legends Stats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.analytics_rounded,
                    size: 80,
                    //color: Colors.white.withOpacity(0.3),
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _navigateToHistory(context),
                tooltip: 'Ver historial',
              ),
            ],
          ),

          // Contenido principal
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[50]!, Colors.white],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Título de sección
                  Text(
                    'Cargar Estadísticas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Selecciona cómo deseas cargar tus estadísticas',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Botón 1: Estadísticas Totales
                  _StatsUploadButton(
                    uploadType: StatsUploadType.total,
                    icon: Icons.dashboard_rounded,
                    color: const Color(0xFF059669),
                    description:
                        'Carga una imagen con todas tus estadísticas generales',
                    onTap: () =>
                        _navigateToUpload(context, StatsUploadType.total),
                  ),

                  const SizedBox(height: 24),

                  // Botón 2: Por Modos de Juego
                  _StatsUploadButton(
                    uploadType: StatsUploadType.byModes,
                    icon: Icons.view_module_rounded,
                    color: const Color(0xFF7C3AED),
                    description:
                        'Carga 3 imágenes separadas:\nClasificatoria, Clásica y Coliseo',
                    onTap: () =>
                        _navigateToUpload(context, StatsUploadType.byModes),
                  ),

                  const SizedBox(height: 24),

                  const Spacer(),

                  // Footer info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Asegúrate de que las capturas de pantalla muestren claramente todas las estadísticas',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUpload(BuildContext context, StatsUploadType uploadType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsUploadScreen(uploadType: uploadType),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsHistoryScreen()),
    );
  }
}

class _StatsUploadButton extends StatelessWidget {
  const _StatsUploadButton({
    required this.uploadType,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  final StatsUploadType uploadType;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uploadType.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${uploadType.imageCount} imagen${uploadType.imageCount > 1 ? 'es' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
