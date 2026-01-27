import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/presentation/widgets/app_sliver_bar.dart';
import 'package:insight/features/stats/presentation/widgets/stats_verification_widget.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.collection});

  final StatsCollection collection;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverBar(
            title: 'Stats ${dateFormat.format(collection.createdAt)}',
            colors: const [Color(0xFF059669), Color(0xFF10B981)],
          ),
          _buildStatsContent(),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        ...collection.availableStats.map(
          (stats) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: StatsVerificationWidget(gameMode: stats.mode, stats: stats),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
