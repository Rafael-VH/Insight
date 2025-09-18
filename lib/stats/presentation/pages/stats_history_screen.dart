import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_state.dart';
import 'package:insight/stats/presentation/pages/stats_detail_screen.dart';
import 'package:intl/intl.dart';

class StatsHistoryScreen extends StatefulWidget {
  const StatsHistoryScreen({super.key});

  @override
  State<StatsHistoryScreen> createState() => _StatsHistoryScreenState();
}

class _StatsHistoryScreenState extends State<StatsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MLStatsBloc>().add(LoadAllStatsCollectionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Historial de Estadísticas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<MLStatsBloc>().add(
                    LoadAllStatsCollectionsEvent(),
                  );
                },
                tooltip: 'Actualizar',
              ),
            ],
          ),
          BlocBuilder<MLStatsBloc, MLStatsState>(
            builder: (context, state) {
              if (state is MLStatsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is MLStatsCollectionsLoaded) {
                if (state.collections.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final collection = state.collections[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        index == 0 ? 16 : 8,
                        16,
                        index == state.collections.length - 1 ? 16 : 8,
                      ),
                      child: StatsCollectionCard(
                        collection: collection,
                        onTap: () => _showStatsDetail(context, collection),
                      ),
                    );
                  }, childCount: state.collections.length),
                );
              } else if (state is MLStatsError) {
                return SliverFillRemaining(
                  child: _buildErrorState(state.message),
                );
              }

              return const SliverFillRemaining(
                child: Center(child: Text('No hay datos disponibles')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No hay estadísticas guardadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Carga tus primeras estadísticas desde la pantalla principal',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Cargar Estadísticas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 24),
          Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MLStatsBloc>().add(LoadAllStatsCollectionsEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showStatsDetail(BuildContext context, StatsCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailScreen(collection: collection),
      ),
    );
  }
}

class StatsCollectionCard extends StatelessWidget {
  const StatsCollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  final StatsCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(collection.createdAt),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatsPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPreview() {
    final availableStats = collection.availableStats;

    if (availableStats.isEmpty) {
      return const Text(
        'Sin estadísticas disponibles',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: availableStats.map((stats) {
        return Chip(
          label: Text(
            _getStatsModeText(stats),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getStatsModeColor(stats).withOpacity(0.1),
          side: BorderSide(color: _getStatsModeColor(stats), width: 1),
        );
      }).toList(),
    );
  }

  String _getStatsModeText(PlayerStats stats) {
    switch (stats.mode) {
      case GameMode.total:
        return 'Total';
      case GameMode.ranked:
        return 'Ranked';
      case GameMode.classic:
        return 'Classic';
      case GameMode.brawl:
        return 'Brawl';
    }
  }

  Color _getStatsModeColor(PlayerStats stats) {
    switch (stats.mode) {
      case GameMode.total:
        return const Color(0xFF059669);
      case GameMode.ranked:
        return const Color(0xFFDC2626);
      case GameMode.classic:
        return const Color(0xFF2563EB);
      case GameMode.brawl:
        return const Color(0xFF7C3AED);
    }
  }
}
