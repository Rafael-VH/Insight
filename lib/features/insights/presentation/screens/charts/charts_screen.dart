import 'package:flutter/material.dart';
import 'package:insight/features/parser/domain/entities/player_performance.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';

// Widgets locales de esta pantalla
import 'widgets/charts_mode_page.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key, required this.collection});

  final StatsCollection collection;

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<PlayerStats> _availableStats;

  @override
  void initState() {
    super.initState();
    _availableStats = widget.collection.availableStats;
    _tabController = TabController(length: _availableStats.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_availableStats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Análisis Visual')),
        body: const Center(child: Text('Sin datos para mostrar')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _availableStats.length == 1
          ? ChartsModeChartsPage(stats: _availableStats.first)
          : TabBarView(
              controller: _tabController,
              children: _availableStats.map((s) => ChartsModeChartsPage(stats: s)).toList(),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análisis Visual',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            widget.collection.displayName,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      bottom: _availableStats.length > 1
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _availableStats
                  .map((s) => Tab(icon: Icon(s.mode.icon, size: 16), text: s.mode.shortName))
                  .toList(),
            )
          : null,
    );
  }
}
