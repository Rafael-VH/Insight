import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/stats/domain/entities/stats_collection.dart';
//
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_state.dart';
//
import 'package:insight/stats/presentation/pages/stats_detail_page.dart';
import 'package:insight/stats/presentation/widgets/app_sliver_bar.dart';
//
import 'package:insight/stats/presentation/widgets/empty_state_widget.dart';
import 'package:insight/stats/presentation/widgets/error_state_widget.dart';
import 'package:insight/stats/presentation/widgets/stats_collection_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;

  // Variables de estado local
  List<StatsCollection> _allCollections = [];
  List<StatsCollection> _displayedCollections = [];
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Inicializa la pantalla cargando los datos
  void _initializeScreen() {
    // Cargar datos del BLoC
    _loadCollections();

    // Configurar listener de scroll para paginación
    _scrollController.addListener(_onScroll);
  }

  /// Listener para detectar cuando llegar al final del scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreCollections();
    }
  }

  /// Carga las colecciones desde el BLoC
  void _loadCollections() {
    if (mounted) {
      context.read<MLStatsBloc>().add(LoadAllStatsCollectionsEvent());
    }
  }

  /// Carga más colecciones (paginación)
  void _loadMoreCollections() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final startIndex = _currentPage * _pageSize;
    final endIndex = min(startIndex + _pageSize, _allCollections.length);

    if (startIndex < _allCollections.length) {
      setState(() {
        _displayedCollections.addAll(
          _allCollections.sublist(startIndex, endIndex),
        );
        _currentPage++;
        _isLoadingMore = false;
        _hasMoreData = endIndex < _allCollections.length;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
        _hasMoreData = false;
      });
    }
  }

  /// Actualiza los datos cuando el BLoC emite un nuevo estado
  void _updateCollections(List<StatsCollection> collections) {
    setState(() {
      _allCollections = collections;
      _displayedCollections.clear();
      _currentPage = 0;
      _hasMoreData = collections.isNotEmpty;
    });

    // Cargar la primera página
    if (collections.isNotEmpty) {
      _loadMoreCollections();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MLStatsBloc, MLStatsState>(
      listener: (context, state) {
        if (state is MLStatsCollectionsLoaded) {
          _updateCollections(state.collections);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
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
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<MLStatsBloc, MLStatsState>(
      builder: (context, state) {
        // Estado de carga inicial
        if (state is MLStatsLoading && _displayedCollections.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Estado de error
        if (state is MLStatsError && _displayedCollections.isEmpty) {
          return SliverFillRemaining(
            child: ErrorStateWidget(
              title: 'Error al cargar estadísticas',
              message: state.message,
              onRetry: _loadCollections,
            ),
          );
        }

        // Estado vacío
        if (_allCollections.isEmpty && state is! MLStatsLoading) {
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

        // Mostrar colecciones
        return _buildCollectionsWithLatest();
      },
    );
  }

  Widget _buildCollectionsWithLatest() {
    if (_displayedCollections.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final latestCollection = _displayedCollections.first;
    final historyCollections = _displayedCollections.length > 1
        ? _displayedCollections.sublist(1)
        : <StatsCollection>[];

    return SliverList(
      delegate: SliverChildListDelegate([
        // ========== ÚLTIMA ESTADÍSTICA ==========
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
        if (historyCollections.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 32, thickness: 2),
          ),

        // ========== HISTORIAL COMPLETO ==========
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
                    '${_allCollections.length - 1}',
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

          // Indicador de carga para paginación
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Mensaje de fin de datos
          if (!_hasMoreData && historyCollections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay más estadísticas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ] else
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

        const SizedBox(height: 16),
      ]),
    );
  }

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
                  children: const [
                    Icon(Icons.star, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
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
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.white,
                  ),
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

  List<Widget> _buildHistoryList(List<StatsCollection> collections) {
    return List.generate(collections.length, (index) {
      final collection = collections[index];
      final totalIndex = index + 1; // +1 porque el primero es el "latest"

      return Padding(
        padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 8, 16, 8),
        child: StatsCollectionCard(
          collection: collection,
          onTap: () => _showStatsDetail(collection),
          badge: '${_allCollections.length - totalIndex}',
        ),
      );
    });
  }

  Widget _buildModeChip(dynamic mode) {
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
