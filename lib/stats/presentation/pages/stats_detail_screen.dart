// lib/features/ml_stats/presentation/pages/stats_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/presentation/pages/widgets/stats_verification_widget.dart';
import 'package:intl/intl.dart';

class StatsDetailScreen extends StatelessWidget {
  const StatsDetailScreen({super.key, required this.collection});

  final StatsCollection collection;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Stats ${dateFormat.format(collection.createdAt)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              ...collection.availableStats.map(
                (stats) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: StatsVerificationWidget(
                    gameMode: stats.mode,
                    stats: stats,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ],
      ),
    );
  }
}
