import 'dart:math';

import 'package:flutter/material.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/stats/presentation/services/dialog_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';
import 'package:insight/features/stats/presentation/screens/details/detail_screen.dart';
import 'package:insight/features/stats/presentation/widgets/app_sliver_bar.dart';
import 'package:insight/features/stats/presentation/widgets/empty_state_widget.dart';
import 'package:insight/features/stats/presentation/widgets/error_state_widget.dart';
import 'package:insight/features/stats/presentation/widgets/stats_collection_card.dart';
import 'package:insight/features/stats/presentation/screens/charts/stats_charts_screen.dart';
import 'package:insight/features/stats/presentation/widgets/export_import_bottom_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchQuery = '';
    _allCollections.clear();
    _displayedCollections.clear();
    super.dispose();
  }

  void _initializeScreen() {
    _loadCollections();
    _scrollController.addListener(_onScroll);
  }

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
    if (_allCollections.isNotEmpty) {
      _loadMoreCollections();
    }
  }

  List<StatsCollection> _filterAndSortCollections(
    List<StatsCollection> collections,
  ) {
    var filtered = collections;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((collection) {
        final name = collection.displayName.toLowerCase();
        final date = _formatDate(collection.createdAt).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || date.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      int comparison;
      if (_sortBy == 'date') {
        comparison = a.createdAt.compareTo(b.createdAt);
      } else {
        comparison = a.displayName.compareTo(b.displayName);
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _reloadWithFilters();
  }

  void _toggleSort(String sortType) {
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
      final state = bloc.state as StatsCollectionsLoaded;
      _updateCollections(state.collections);
    }
  }

  Future<void> _showRenameDialog(StatsCollection collection) async {
    final currentName = collection.displayName;
    final controller = TextEditingController(text: currentName);
    final colorScheme = Theme.of(context).colorScheme;

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              'Cambiar Nombre',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa un nuevo nombre para estas estadísticas:',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre',
                hintText: 'Ej: Partidas del sábado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
                counterText: '',
              ),
              autofocus: true,
              maxLength: 50,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogContext, text);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      context.read<StatsBloc>().add(
        UpdateStatsCollectionNameEvent(
          createdAt: collection.createdAt,
          newName: newName,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(StatsCollection collection) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 12),
            Text('Confirmar', style: TextStyle(color: colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de eliminar estas estadísticas?',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red[900]!.withValues(alpha: 0.3)
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.red[700]! : Colors.red[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(collection.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.red[300] : Colors.red[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      context.read<StatsBloc>().add(
        DeleteStatsCollectionEvent(collection.createdAt),
      );
    }
  }

  void _showStatsDetail(StatsCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(collection: collection),
      ),
    );
  }

  void _showOptionsMenu(StatsCollection collection, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.more_horiz,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Opciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                'Ver Gráficos',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatsChartsScreen(collection: collection),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.import_export_rounded,
                  color: Colors.teal,
                ),
              ),
              title: Text(
                'Exportar / Importar',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                ExportImportBottomSheet.show(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF059669)),
              ),
              title: Text(
                'Cambiar Nombre',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showRenameDialog(collection);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red[400]),
              ),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showDeleteConfirmation(collection);
              },
            ),
            const SizedBox(height: 8),
          ],
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<StatsBloc, StatsState>(
      listener: _handleExportImportState,
      child: BlocListener<StatsBloc, StatsState>(
        listener: (context, state) {
          final settingsState = context.read<SettingsBloc>().state;
          final useAwesome = settingsState is SettingsLoaded
              ? settingsState.settings.useAwesomeSnackbar
              : true;
          if (state is StatsCollectionsLoaded) {
            _updateCollections(state.collections);
          } else if (state is StatsNameUpdated) {
            DialogService.showSuccess(
              context,
              message: state.message,
              useAwesome: useAwesome,
            );
          } else if (state is StatsDeleted) {
            DialogService.showSuccess(
              context,
              message: state.message,
              useAwesome: useAwesome,
            );
          } else if (state is StatsError) {
            DialogService.showError(
              context,
              title: 'Error',
              message: state.message,
              errorDetails: state.errorDetails,
              useAwesome: useAwesome,
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                _buildAppBar(),
                _buildSearchBar(),
                _buildFilterBar(),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleExportImportState(BuildContext context, StatsState state) async {
    if (state is StatsExported) {
      await Share.shareXFiles(
        [XFile(state.filePath)],
        subject: 'Insight — ${state.totalCollections} colección(es)',
        text: 'Backup de estadísticas de Mobile Legends',
      );
    } else if (state is StatsImported) {
      if (!context.mounted) return;
      final msg = state.skippedCount > 0
          ? '✅ ${state.importedCount} importada(s), '
                '${state.skippedCount} duplicada(s) omitida(s)'
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

  Widget _buildAppBar() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return AppSliverBar(
      title: 'Historial de Estadísticas',
      colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      expandedHeight: isKeyboardVisible ? 60.0 : 100.0,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            _sortBy == 'date' ? Icons.calendar_today : Icons.sort_by_alpha,
          ),
          tooltip: 'Ordenar',
          onSelected: (value) {
            if (value == 'toggle') {
              _toggleSort(_sortBy);
            } else {
              _toggleSort(value);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'date',
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _sortBy == 'date'
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Por Fecha',
                    style: TextStyle(
                      fontWeight: _sortBy == 'date'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'name',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha,
                    color: _sortBy == 'name'
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Por Nombre',
                    style: TextStyle(
                      fontWeight: _sortBy == 'name'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  const SizedBox(width: 12),
                  Text(_isAscending ? 'Ascendente' : 'Descendente'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadCollections,
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.import_export_rounded),
          onPressed: () => ExportImportBottomSheet.show(context),
          tooltip: 'Exportar / Importar',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: colorScheme.primary.withValues(alpha: 0.05),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o fecha...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_allCollections.length} resultado(s)',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_searchQuery.isNotEmpty)
              Chip(
                label: Text(
                  'Búsqueda: "$_searchQuery"',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
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
                  : 'Carga tus primeras estadísticas desde la pantalla principal',
              actionButton: _searchQuery.isEmpty
                  ? ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Cargar Estadísticas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        }

        return _buildCollectionsList();
      },
    );
  }

  Widget _buildCollectionsList() {
    if (_displayedCollections.isEmpty && _allCollections.isNotEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    final latestCollection = _displayedCollections.isNotEmpty
        ? _displayedCollections.first
        : null;
    final historyCollections = _displayedCollections.length > 1
        ? _displayedCollections.sublist(1)
        : <StatsCollection>[];

    return SliverList(
      delegate: SliverChildListDelegate([
        if (latestCollection != null && _searchQuery.isEmpty) ...[
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 32, thickness: 2),
          ),
        ],

        if (historyCollections.isNotEmpty || _searchQuery.isNotEmpty) ...[
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
          if (_searchQuery.isNotEmpty && _displayedCollections.isNotEmpty)
            ..._displayedCollections.asMap().entries.map(
              (entry) => _buildHistoryCard(entry.value, entry.key),
            )
          else
            ...historyCollections.asMap().entries.map(
              (entry) => _buildHistoryCard(entry.value, entry.key + 1),
            ),

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!_hasMoreData && historyCollections.isNotEmpty)
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

  Widget _buildLatestStatsCard(StatsCollection collection) {
    return GestureDetector(
      onTap: () => _showStatsDetail(collection),
      onLongPress: () => _showOptionsMenu(collection, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF059669).withValues(alpha: 0.9),
              const Color(0xFF10B981),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.3),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                  IconButton(
                    onPressed: () => _showOptionsMenu(collection, 0),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: 'Más opciones',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                collection.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
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
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (collection.availableStats.isNotEmpty) ...[
                Text(
                  'Modos capturados:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

  Widget _buildHistoryCard(StatsCollection collection, int index) {
    final badgeNumber = _allCollections.length - index;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        index == 0 && _searchQuery.isEmpty ? 0 : 8,
        16,
        8,
      ),
      child: GestureDetector(
        onLongPress: () => _showOptionsMenu(collection, index),
        child: StatsCollectionCard(
          collection: collection,
          onTap: () => _showStatsDetail(collection),
          badge: _searchQuery.isEmpty ? '$badgeNumber' : null,
        ),
      ),
    );
  }

  Widget _buildModeChip(dynamic mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
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
}
