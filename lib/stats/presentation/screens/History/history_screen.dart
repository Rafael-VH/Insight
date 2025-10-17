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

class StatsHistoryPage extends StatefulWidget {
  const StatsHistoryPage({super.key});

  @override
  State<StatsHistoryPage> createState() => _StatsHistoryPageState();
}

class _StatsHistoryPageState extends State<StatsHistoryPage> {
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

          return _buildCollectionsList(state.collections);
        }

        return const SliverFillRemaining(
          child: Center(child: Text('No hay datos disponibles')),
        );
      },
    );
  }

  Widget _buildCollectionsList(List<StatsCollection> collections) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final collection = collections[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            index == 0 ? 16 : 8,
            16,
            index == collections.length - 1 ? 16 : 8,
          ),
          child: StatsCollectionCard(
            collection: collection,
            onTap: () => _showStatsDetail(context, collection),
          ),
        );
      }, childCount: collections.length),
    );
  }

  void _showStatsDetail(BuildContext context, StatsCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailPage(collection: collection),
      ),
    );
  }
}
