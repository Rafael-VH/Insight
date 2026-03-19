import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';
import 'package:insight/features/stats/presentation/screens/details/detail_screen.dart';
import 'package:insight/features/stats/presentation/services/dialog_service.dart';
import 'package:insight/features/stats/presentation/widgets/empty_state_widget.dart';
import 'package:insight/features/stats/presentation/widgets/error_state_widget.dart';
import 'package:insight/features/stats/presentation/widgets/export_import_bottom_sheet.dart';
import 'package:insight/features/stats/presentation/widgets/stats_collection_card.dart';

// Widgets locales de esta pantalla
import 'widgets/history_app_bar.dart';
import 'widgets/history_delete_dialog.dart';
import 'widgets/history_filter_bar.dart';
import 'widgets/history_latest_card.dart';
import 'widgets/history_options_menu.dart';
import 'widgets/history_rename_dialog.dart';
import 'widgets/history_search_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  static const int _pageSize = 10;

  List<StatsCollection> _allCollections = [];
  final List<StatsCollection> _displayedCollections = [];
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  String _searchQuery = '';
  String _sortBy = 'date';
  bool _isAscending = false;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _allCollections.clear();
    _displayedCollections.clear();
    super.dispose();
  }

  // ==================== PAGINACIÓN Y FILTRADO ====================

  void _onScroll() {
    if (_isLoadingMore || !_hasMoreData) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreCollections();
    }
  }

  void _loadCollections() {
    if (mounted) {
      context.read<StatsBloc>().add(LoadAllStatsCollectionsEvent());
    }
  }

  void _loadMoreCollections() {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);

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

  void _updateCollections(List<StatsCollection> collections) {
    setState(() {
      _allCollections = _filterAndSortCollections(collections);
      _displayedCollections.clear();
      _currentPage = 0;
      _hasMoreData = _allCollections.isNotEmpty;
    });
    if (_allCollections.isNotEmpty) _loadMoreCollections();
  }

  List<StatsCollection> _filterAndSortCollections(
    List<StatsCollection> collections,
  ) {
    var filtered = collections;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final name = c.displayName.toLowerCase();
        final date = _formatDate(c.createdAt).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || date.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final comparison = _sortBy == 'date'
          ? a.createdAt.compareTo(b.createdAt)
          : a.displayName.compareTo(b.displayName);
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _reloadWithFilters();
  }

  void _onToggleSort(String sortType) {
    setState(() {
      if (_sortBy == sortType) {
        _isAscending = !_isAscending;
      } else {
        _sortBy = sortType;
        _isAscending = false;
      }
    });
    _reloadWithFilters();
  }

  void _reloadWithFilters() {
    final bloc = context.read<StatsBloc>();
    if (bloc.state is StatsCollectionsLoaded) {
      _updateCollections((bloc.state as StatsCollectionsLoaded).collections);
    }
  }

  // ==================== ACCIONES ====================

  void _showDetail(StatsCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(collection: collection)),
    );
  }

  void _showOptions(StatsCollection collection) {
    HistoryOptionsMenu.show(
      context: context,
      collection: collection,
      onRename: () => _renameCollection(collection),
      onDelete: () => _deleteCollection(collection),
    );
  }

  Future<void> _renameCollection(StatsCollection collection) async {
    final newName = await HistoryRenameDialog.show(
      context: context,
      currentName: collection.displayName,
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != collection.displayName) {
      context.read<StatsBloc>().add(
        UpdateStatsCollectionNameEvent(
          createdAt: collection.createdAt,
          newName: newName,
        ),
      );
    }
  }

  Future<void> _deleteCollection(StatsCollection collection) async {
    final confirmed = await HistoryDeleteDialog.show(
      context: context,
      collection: collection,
      formattedDate: _formatDate(collection.createdAt),
    );

    if (confirmed == true) {
      context.read<StatsBloc>().add(
        DeleteStatsCollectionEvent(collection.createdAt),
      );
    }
  }

  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Hace unos segundos';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours}h';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';

    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().substring(2);
    return '$d/$m/$y';
  }

  bool get _useAwesomeSnackbar {
    final state = context.read<SettingsBloc>().state;
    return state is SettingsLoaded ? state.settings.useAwesomeSnackbar : true;
  }

  // ==================== BLOC LISTENERS ====================

  void _handleStatsState(BuildContext context, StatsState state) {
    if (state is StatsCollectionsLoaded) {
      _updateCollections(state.collections);
    } else if (state is StatsNameUpdated) {
      DialogService.showSuccess(
        context,
        message: state.message,
        useAwesome: _useAwesomeSnackbar,
      );
    } else if (state is StatsDeleted) {
      DialogService.showSuccess(
        context,
        message: state.message,
        useAwesome: _useAwesomeSnackbar,
      );
    } else if (state is StatsError) {
      DialogService.showError(
        context,
        title: 'Error',
        message: state.message,
        errorDetails: state.errorDetails,
        useAwesome: _useAwesomeSnackbar,
      );
    }
  }

  void _handleExportImportState(BuildContext context, StatsState state) async {
    if (state is StatsExported) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(state.filePath)],
          subject: 'Insight — ${state.totalCollections} colección(es)',
          text: 'Backup de estadísticas de Mobile Legends',
        ),
      );
    } else if (state is StatsImported) {
      if (!context.mounted) return;
      final msg = state.skippedCount > 0
          ? '✅ ${state.importedCount} importada(s), ${state.skippedCount} duplicada(s) omitida(s)'
          : '✅ ${state.importedCount} colección(es) importada(s)'
                '${state.merged ? ' y fusionada(s)' : ', datos anteriores reemplazados'}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return BlocListener<StatsBloc, StatsState>(
      listener: _handleExportImportState,
      child: BlocListener<StatsBloc, StatsState>(
        listener: _handleStatsState,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                HistoryAppBar(
                  sortBy: _sortBy,
                  isAscending: _isAscending,
                  onRefresh: _loadCollections,
                  onToggleSort: _onToggleSort,
                ),
                HistorySearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
                HistoryFilterBar(
                  totalResults: _allCollections.length,
                  searchQuery: _searchQuery,
                  onClearSearch: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<StatsBloc, StatsState>(
      builder: (context, state) {
        if (state is StatsLoading && _displayedCollections.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is StatsError && _displayedCollections.isEmpty) {
          return SliverFillRemaining(
            child: ErrorStateWidget(
              title: 'Error al cargar estadísticas',
              message: state.message,
              onRetry: _loadCollections,
            ),
          );
        }

        if (_allCollections.isEmpty && state is! StatsLoading) {
          return SliverFillRemaining(
            child: EmptyStateWidget(
              icon: Icons.analytics_outlined,
              title: _searchQuery.isNotEmpty
                  ? 'No se encontraron resultados'
                  : 'No hay estadísticas guardadas',
              subtitle: _searchQuery.isNotEmpty
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Importa tus estadísticas desde un archivo JSON',
              actionButton: _searchQuery.isEmpty
                  ? ElevatedButton.icon(
                      onPressed: () => ExportImportBottomSheet.show(context),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Importar Estadísticas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        }

        return _buildList();
      },
    );
  }

  Widget _buildList() {
    if (_displayedCollections.isEmpty && _allCollections.isNotEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final latest = _displayedCollections.isNotEmpty
        ? _displayedCollections.first
        : null;
    final history = _displayedCollections.length > 1
        ? _displayedCollections.sublist(1)
        : <StatsCollection>[];

    return SliverList(
      delegate: SliverChildListDelegate([
        // --- Última estadística ---
        if (latest != null && _searchQuery.isEmpty) ...[
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
            child: HistoryLatestCard(
              collection: latest,
              formattedDate: _formatDate(latest.createdAt),
              onTap: () => _showDetail(latest),
              onOptionsPressed: () => _showOptions(latest),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 32, thickness: 2),
          ),
        ],

        // --- Historial completo ---
        if (history.isNotEmpty || _searchQuery.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Resultados de Búsqueda'
                      : 'Historial Completo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                if (_searchQuery.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_allCollections.length - 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Items
          if (_searchQuery.isNotEmpty)
            ..._displayedCollections.asMap().entries.map(
              (e) => _buildCard(e.value, e.key),
            )
          else
            ...history.asMap().entries.map(
              (e) => _buildCard(e.value, e.key + 1),
            ),

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!_hasMoreData && history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay más estadísticas',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ] else if (_searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No hay más estadísticas guardadas',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildCard(StatsCollection collection, int index) {
    final badgeNumber = _allCollections.length - index;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        index == 0 && _searchQuery.isEmpty ? 0 : 8,
        16,
        8,
      ),
      child: GestureDetector(
        onLongPress: () => _showOptions(collection),
        child: StatsCollectionCard(
          collection: collection,
          onTap: () => _showDetail(collection),
          badge: _searchQuery.isEmpty ? '$badgeNumber' : null,
        ),
      ),
    );
  }
}
