import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/stats/domain/entities/stats_collection.dart';
//
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_state.dart';
//
import 'package:insight/stats/presentation/pages/Detail/stats_detail_page.dart';
//
import 'package:insight/stats/presentation/screens/History/widget/empty_state_widget.dart';
import 'package:insight/stats/presentation/screens/History/widget/error_state_widget.dart';
import 'package:insight/stats/presentation/screens/History/widget/stats_collection_card.dart';
import 'package:insight/stats/presentation/widgets/app_sliver_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  void _loadCollections() {
    context.read<MLStatsBloc>().add(LoadAllStatsCollectionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverBar(
            title: 'Historial de Estadísticas',
            colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCollections,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<MLStatsBloc, MLStatsState>(
      builder: (context, state) {
        if (state is MLStatsLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is MLStatsError) {
          return SliverFillRemaining(
            child: ErrorStateWidget(
              title: 'Error al cargar estadísticas',
              message: state.message,
              onRetry: _loadCollections,
            ),
          );
        }

        if (state is MLStatsCollectionsLoaded) {
          if (state.collections.isEmpty) {
            return SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.analytics_outlined,
                title: 'No hay estadísticas guardadas',
                subtitle:
                    'Carga tus primeras estadísticas desde la pantalla principal',
                actionButton: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Cargar Estadísticas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            );
          }

          return _buildCollectionsWithLatest(state.collections);
        }

        return const SliverFillRemaining(
          child: Center(child: Text('No hay datos disponibles')),
        );
      },
    );
  }

  // NUEVO: Construye la vista con Latest en la parte superior
  Widget _buildCollectionsWithLatest(List<StatsCollection> collections) {
    // La primera es la más reciente (ya están ordenadas)
    final latestCollection = collections.isNotEmpty ? collections.first : null;

    // El resto son el historial
    final historyCollections = collections.length > 1
        ? collections.sublist(1)
        : <StatsCollection>[];

    return SliverList(
      delegate: SliverChildListDelegate([
        // ========== SECCIÓN: ÚLTIMA ESTADÍSTICA ==========
        if (latestCollection != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Última Estadística',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildLatestStatsCard(latestCollection),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 32, thickness: 2),
          ),
        ],

        // ========== SECCIÓN: HISTORIAL COMPLETO ==========
        if (historyCollections.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial Completo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${historyCollections.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._buildHistoryList(historyCollections),
          const SizedBox(height: 16),
        ] else if (latestCollection != null) ...[
          // Si no hay historial adicional
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No hay más estadísticas guardadas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // NUEVO: Construye la tarjeta destacada de última estadística
  Widget _buildLatestStatsCard(StatsCollection collection) {
    return GestureDetector(
      onTap: () => _showStatsDetail(collection),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF059669).withOpacity(0.9),
              const Color(0xFF10B981),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de "Más Reciente"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text(
                      'MÁS RECIENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fecha y hora
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(collection.createdAt),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Modos disponibles
              if (collection.availableStats.isNotEmpty) ...[
                Text(
                  'Modos capturados:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: collection.availableStats
                      .map((stats) => _buildModeChip(stats.mode))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),

              // Botón de ver detalles
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showStatsDetail(collection),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Ver Detalles',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye la lista de historial
  List<Widget> _buildHistoryList(List<StatsCollection> collections) {
    return List.generate(collections.length, (index) {
      final collection = collections[index];
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          index == 0 ? 0 : 8,
          16,
          index == collections.length - 1 ? 8 : 8,
        ),
        child: StatsCollectionCard(
          collection: collection,
          onTap: () => _showStatsDetail(collection),
          // NUEVO: Badge con número de orden
          badge: '${collections.length - index}',
        ),
      );
    }).toList();
  }

  // Construye un chip de modo de juego
  Widget _buildModeChip(dynamic mode) {
    final modeColor = _getModeColor(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        mode.shortName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Obtiene el color del modo de juego
  Color _getModeColor(dynamic mode) {
    final modeString = mode.toString().toLowerCase();
    if (modeString.contains('ranked')) return const Color(0xFFDC2626);
    if (modeString.contains('classic')) return const Color(0xFF2563EB);
    if (modeString.contains('brawl')) return const Color(0xFF7C3AED);
    return const Color(0xFF059669);
  }

  // Formatea la fecha y hora
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().substring(2);
      return '$day/$month/$year';
    }
  }

  void _showStatsDetail(StatsCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailPage(collection: collection),
      ),
    );
  }
}
