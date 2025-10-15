import 'package:flutter/material.dart';
//
import 'package:insight/stats/domain/entities/stats_upload_type.dart';
//
import 'package:insight/stats/presentation/pages/History/stats_history_page.dart';
import 'package:insight/stats/presentation/pages/Upload/stats_upload_page.dart';
//
import 'package:insight/stats/presentation/screens/Home/widget/info_banner.dart';
import 'package:insight/stats/presentation/screens/Home/widget/stats_upload_button.dart';
import 'package:insight/stats/presentation/widgets/app_sliver_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverBar(
            title: 'Mobile Legends Stats',
            colors: const [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
            icon: Icons.analytics_rounded,
            expandedHeight: 200.0,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _navigateToHistory(context),
                tooltip: 'Ver historial',
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF9FAFB), Colors.white],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _buildSectionTitle(context),
                  const SizedBox(height: 48),
                  _buildUploadButtons(context),
                  const Spacer(),
                  _buildInfoBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildUploadButtons(BuildContext context) {
    return Column(
      children: [
        StatsUploadButton(
          uploadType: StatsUploadType.total,
          icon: Icons.dashboard_rounded,
          color: const Color(0xFF059669),
          description: 'Carga una imagen con todas tus estadísticas generales',
          onTap: () => _navigateToUpload(context, StatsUploadType.total),
        ),
        const SizedBox(height: 24),
        StatsUploadButton(
          uploadType: StatsUploadType.byModes,
          icon: Icons.view_module_rounded,
          color: const Color(0xFF7C3AED),
          description:
              'Carga 3 imágenes separadas:\nClasificatoria, Clásica y Coliseo',
          onTap: () => _navigateToUpload(context, StatsUploadType.byModes),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return const InfoBanner(
      message:
          'Asegúrate de que las capturas de pantalla muestren claramente todas las estadísticas',
    );
  }

  void _navigateToUpload(BuildContext context, StatsUploadType uploadType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsUploadPage(uploadType: uploadType),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsHistoryPage()),
    );
  }
}
