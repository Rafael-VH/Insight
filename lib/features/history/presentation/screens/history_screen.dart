import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/history/presentation/bloc/history_state.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';
import 'package:insight/features/insights/presentation/screens/details/session_detail_screen.dart';
import 'package:insight/core/services/dialog_service.dart';

import 'widgets/history_delete_dialog.dart';
import 'widgets/history_export_import_bottom_sheet.dart';
import 'widgets/history_filter_bar.dart';
import 'widgets/history_options_menu.dart';
import 'widgets/history_rename_dialog.dart';
import 'widgets/history_search_bar.dart';
import 'widgets/history_hero_section.dart';
import 'widgets/history_latest_card.dart';
import 'widgets/history_list_card.dart';

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

  // ── Lifecycle ─────────────────────────────────────────────────

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

  // ── Paginación y filtrado ─────────────────────────────────────

  void _onScroll() {
    if (_isLoadingMore || !_hasMoreData) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreCollections();
    }
  }

  void _loadCollections() {
    if (mounted) {
      context.read<HistoryBloc>().add(LoadAllStatsCollectionsEvent());
    }
  }

  void _loadMoreCollections() {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);

    final startIndex = _currentPage * _pageSize;
    final endIndex = min(startIndex + _pageSize, _allCollections.length);

    if (startIndex < _allCollections.length) {
      setState(() {
        _displayedCollections.addAll(_allCollections.sublist(startIndex, endIndex));
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

  List<StatsCollection> _filterAndSortCollections(List<StatsCollection> collections) {
    var filtered = collections;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final name = c.displayName.toLowerCase();
        final date = _formatDateShort(c.createdAt).toLowerCase();
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
    final bloc = context.read<HistoryBloc>();
    if (bloc.state is HistoryCollectionsLoaded) {
      _updateCollections((bloc.state as HistoryCollectionsLoaded).collections);
    }
  }

  // ── Acciones ──────────────────────────────────────────────────

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
    if (newName != null && newName.isNotEmpty && newName != collection.displayName) {
      context.read<HistoryBloc>().add(
        UpdateStatsCollectionNameEvent(createdAt: collection.createdAt, newName: newName),
      );
    }
  }

  Future<void> _deleteCollection(StatsCollection collection) async {
    final confirmed = await HistoryDeleteDialog.show(
      context: context,
      collection: collection,
      formattedDate: _formatDateShort(collection.createdAt),
    );
    if (confirmed == true) {
      context.read<HistoryBloc>().add(DeleteStatsCollectionEvent(collection.createdAt));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _formatDateShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().substring(2);
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $h:$min';
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Hace unos segundos';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return _formatDateShort(date);
  }

  bool get _useAwesomeSnackbar {
    final state = context.read<SettingsBloc>().state;
    return state is SettingsLoaded ? state.settings.useAwesomeSnackbar : true;
  }

  HistoryGlobalMetrics _computeGlobalMetrics(List<StatsCollection> collections) {
    if (collections.isEmpty) {
      return HistoryGlobalMetrics(total: 0, avgWr: 0, avgKda: 0);
    }

    double totalWr = 0;
    double totalKda = 0;
    int countWr = 0;
    int countKda = 0;

    for (final c in collections) {
      final stats = c.totalStats ?? c.rankedStats ?? c.classicStats ?? c.brawlStats;
      if (stats != null) {
        if (stats.winRate > 0) {
          totalWr += stats.winRate;
          countWr++;
        }
        if (stats.kda > 0) {
          totalKda += stats.kda;
          countKda++;
        }
      }
    }

    return HistoryGlobalMetrics(
      total: collections.length,
      avgWr: countWr > 0 ? totalWr / countWr : 0,
      avgKda: countKda > 0 ? totalKda / countKda : 0,
    );
  }

  // ── BLoC listeners ────────────────────────────────────────────

  void _handleHistoryState(BuildContext context, HistoryState state) {
    if (state is HistoryCollectionsLoaded) {
      _updateCollections(state.collections);
    } else if (state is HistoryNameUpdated) {
      DialogService.showSuccess(context, message: state.message, useAwesome: _useAwesomeSnackbar);
    } else if (state is HistoryDeleted) {
      DialogService.showSuccess(context, message: state.message, useAwesome: _useAwesomeSnackbar);
    } else if (state is HistoryError) {
      DialogService.showError(
        context,
        title: 'Error',
        message: state.message,
        errorDetails: state.errorDetails,
        useAwesome: _useAwesomeSnackbar,
      );
    }
  }

  void _handleExportImportState(BuildContext context, HistoryState state) async {
    if (state is HistoryExported) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(state.filePath)],
          subject: 'Insight — ${state.totalCollections} colección(es)',
          text: 'Backup de estadísticas de Mobile Legends',
        ),
      );
    } else if (state is HistoryImported) {
      if (!context.mounted) return;
      final msg = state.skippedCount > 0
          ? '${state.importedCount} importada(s), '
                '${state.skippedCount} duplicada(s) omitida(s)'
          : '${state.importedCount} colección(es) importada(s)'
                '${state.merged ? ' y fusionada(s)' : ', datos anteriores reemplazados'}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryBloc, HistoryState>(
      listener: _handleExportImportState,
      child: BlocListener<HistoryBloc, HistoryState>(
        listener: _handleHistoryState,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // ── Hero section ───────────────────────────────
              BlocBuilder<HistoryBloc, HistoryState>(
                buildWhen: (_, s) => s is HistoryCollectionsLoaded,
                builder: (context, state) {
                  final metrics = _computeGlobalMetrics(
                    state is HistoryCollectionsLoaded ? state.collections : _allCollections,
                  );
                  return SliverToBoxAdapter(
                    child: HistoryHeroSection(
                      metrics: metrics,
                      sortBy: _sortBy,
                      isAscending: _isAscending,
                      onRefresh: _loadCollections,
                      onToggleSort: _onToggleSort,
                      onExportImport: () => HistoryExportImportBottomSheet.show(context),
                    ),
                  );
                },
              ),

              // ── Buscador ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: HistorySearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),

              // ── Filter bar ─────────────────────────────────
              SliverToBoxAdapter(
                child: HistoryFilterBar(
                  totalResults: _allCollections.length,
                  searchQuery: _searchQuery,
                  onClearSearch: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
              ),

              // ── Contenido principal ────────────────────────
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading && _displayedCollections.isEmpty) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        if (state is HistoryError && _displayedCollections.isEmpty) {
          return SliverFillRemaining(
            child: _HistoryErrorState(message: state.message, onRetry: _loadCollections),
          );
        }

        if (_allCollections.isEmpty && state is! HistoryLoading) {
          return SliverFillRemaining(
            child: _HistoryEmptyState(
              hasSearch: _searchQuery.isNotEmpty,
              onImport: () => HistoryExportImportBottomSheet.show(context),
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          );
        }

        return _buildList();
      },
    );
  }

  Widget _buildList() {
    final colorScheme = Theme.of(context).colorScheme;

    final latest = _displayedCollections.isNotEmpty ? _displayedCollections.first : null;
    final history = _displayedCollections.length > 1
        ? _displayedCollections.sublist(1)
        : <StatsCollection>[];

    return SliverList(
      delegate: SliverChildListDelegate([
        if (latest != null && _searchQuery.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: _SectionLabel(label: 'Más reciente'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: HistoryLatestCard(
              collection: latest,
              formattedDate: _formatDateShort(latest.createdAt),
              relativeTime: _relativeTime(latest.createdAt),
              onTap: () => _showDetail(latest),
              onOptionsPressed: () => _showOptions(latest),
            ),
          ),
        ],

        if (history.isNotEmpty || _searchQuery.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _SectionLabel(
                  label: _searchQuery.isNotEmpty ? 'Resultados de búsqueda' : 'Historial completo',
                ),
                const SizedBox(width: 8),
                if (_searchQuery.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_allCollections.length - 1}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_searchQuery.isNotEmpty)
            ..._displayedCollections.asMap().entries.map((e) => _buildListCard(e.value, e.key + 1))
          else
            ...history.asMap().entries.map((e) => _buildListCard(e.value, e.key + 2)),

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          if (!_hasMoreData && history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Center(
                child: Text(
                  '— Fin del historial —',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ] else if (_searchQuery.isEmpty && _displayedCollections.length == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Center(
              child: Text(
                'Solo hay una sesión guardada',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildListCard(StatsCollection collection, int number) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: GestureDetector(
        onLongPress: () => _showOptions(collection),
        child: HistoryListCard(
          collection: collection,
          number: number,
          totalCount: _allCollections.length,
          relativeTime: _relativeTime(collection.createdAt),
          formattedDate: _formatDateShort(collection.createdAt),
          onTap: () => _showDetail(collection),
          onOptionsPressed: () => _showOptions(collection),
        ),
      ),
    );
  }
}

// ── Helpers internos ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.hasSearch,
    required this.onImport,
    required this.onClear,
  });
  final bool hasSearch;
  final VoidCallback onImport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 28,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'Sin resultados para tu búsqueda' : 'Aún no hay sesiones guardadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Prueba con otro término o limpia el filtro'
                  : 'Importa un archivo .json o captura tus primeras estadísticas',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (hasSearch)
              OutlinedButton(onPressed: onClear, child: const Text('Limpiar búsqueda'))
            else
              ElevatedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Importar estadísticas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el historial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
